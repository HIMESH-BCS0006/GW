import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
  AlertTriangle, Check, CheckCircle2, Loader2, Minus, Package, Plus, Printer, RotateCcw, Save,
  Search, Snowflake, Sun, Trash2, Truck, Warehouse, WifiOff,
} from 'lucide-react';
import { useAuth } from '../../../shared/auth/AuthContext';
import { ErrorState } from '../../../shared/components/ErrorState';
import { LoadingState } from '../../../shared/components/LoadingState';
import { useBusinessClock } from '../../../shared/hooks/useBusinessClock';
import { useCreateOrder, useRefOutlets } from '../api/hooks';
import { CutoffCountdown } from '../components/CutoffCountdown';
import { OrderConfirmationCard } from '../components/OrderConfirmationCard';
import type { CreateOrderRequest, CreateOrderResponse } from '../types';

/**
 * SM2 Place order, body only (the app layout supplies header/footer).
 *
 * CONTRACT NOTE (openapi.yaml, POST /orders): there are no item/SKU/line fields.
 * Items here are a client-side builder. On submit they are grouped by temperature
 * (D9: one order = one temperature), so at most two orders are sent:
 *   order_units      = sum of item quantities
 *   order_weight_kg  = sent only when any item has its own weight/volume (D18 override)
 *   note             = generated list "ID name xQty; ..." + the manager's extra note
 * The server does not store items as rows. List this as a README departure (Spec 04 #4).
 */

type Temp = 'ambient' | 'chilled';
interface Item {
  key: string;
  itemId: string;
  name: string;
  temp: Temp;
  qty: number;
  weightPerUnit: string; // kg per unit; blank = use the standard conversion (D10)
  volumePerUnit: string; // m3 per unit; blank = use the standard conversion
}
interface Entry { itemId: string; name: string; temp: Temp; qty: string; weight: string; volume: string }
type Filter = 'all' | Temp;

const emptyEntry = (temp: Temp = 'ambient'): Entry => ({ itemId: '', name: '', temp, qty: '1', weight: '', volume: '' });
const TEMP_LABEL: Record<Temp, string> = { ambient: 'Dry (ambient)', chilled: 'Chilled' };

function consts(unitConstants: Record<string, any> | undefined, brand: string, temp: Temp) {
  const e = unitConstants?.[brand]?.[temp];
  return e && e.kg_per_unit > 0 && e.m3_per_unit > 0 ? (e as { kg_per_unit: number; m3_per_unit: number }) : null;
}

export const SM2PlaceOrderPage: React.FC = () => {
  const { user } = useAuth();
  const outletId = user?.outlet_id ?? '';
  const { unitConstants, isLoading: clockLoading, isError: clockError } = useBusinessClock();
  const { data: outlets, isLoading: outletsLoading, isError: outletsError, refetch: refetchOutlets } = useRefOutlets();
  const createOrder = useCreateOrder();

  const [entry, setEntry] = useState<Entry>(emptyEntry());
  const [entryErrors, setEntryErrors] = useState<Record<string, string>>({});
  const [items, setItems] = useState<Item[]>([]);
  const [extraNote, setExtraNote] = useState('');
  const [filter, setFilter] = useState<Filter>('all');
  const [search, setSearch] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [isOffline, setIsOffline] = useState(!navigator.onLine);
  const [placed, setPlaced] = useState<Partial<Record<Temp, CreateOrderResponse>>>({});
  const [failed, setFailed] = useState<Partial<Record<Temp, unknown>>>({});
  const [formError, setFormError] = useState<string | null>(null);
  const [msg, setMsg] = useState<string | null>(null);
  const opIds = useRef<Partial<Record<Temp, { sig: string; id: string }>>>({});

  const outlet: any = outlets?.find((o) => o.outlet_id === outletId);
  const brand: string = outlet?.brand ?? '';
  const isFresh = brand === 'Fresh';
  const draftKey = `sm-order-draft:${outletId}`;

  useEffect(() => {
    const on = () => setIsOffline(false);
    const off = () => setIsOffline(true);
    window.addEventListener('online', on);
    window.addEventListener('offline', off);
    return () => { window.removeEventListener('online', on); window.removeEventListener('offline', off); };
  }, []);

  // D9: only Fresh outlets may order chilled
  useEffect(() => { if (!isFresh && entry.temp === 'chilled') setEntry((e) => ({ ...e, temp: 'ambient' })); }, [isFresh, entry.temp]);

  // optional local draft (not part of the API)
  useEffect(() => {
    if (!outletId) return;
    try {
      const raw = localStorage.getItem(draftKey);
      if (raw) {
        const d = JSON.parse(raw) as { items: Item[]; extraNote: string };
        if (Array.isArray(d.items) && d.items.length) { setItems(d.items); setExtraNote(d.extraNote ?? ''); setMsg('Draft restored.'); }
      }
    } catch { /* storage unavailable */ }
  }, [draftKey, outletId]);

  /** Effective per-unit values for an item (own value, else standard conversion). */
  const perUnit = (it: Item) => {
    const c = consts(unitConstants, brand, it.temp);
    const w = it.weightPerUnit !== '' ? Number(it.weightPerUnit) : c?.kg_per_unit ?? NaN;
    const v = it.volumePerUnit !== '' ? Number(it.volumePerUnit) : c?.m3_per_unit ?? NaN;
    return { w, v };
  };
  const lineKg = (it: Item) => { const { w } = perUnit(it); return Number.isFinite(w) ? w * it.qty : 0; };
  const lineM3 = (it: Item) => { const { v } = perUnit(it); return Number.isFinite(v) ? v * it.qty : 0; };

  const totals = useMemo(() => {
    const t = (list: Item[]) => ({
      units: list.reduce((a, i) => a + i.qty, 0),
      kg: list.reduce((a, i) => a + lineKg(i), 0),
      m3: list.reduce((a, i) => a + lineM3(i), 0),
    });
    const open = items.filter((i) => !placed[i.temp]);
    return { all: t(open), ambient: t(open.filter((i) => i.temp === 'ambient')), chilled: t(open.filter((i) => i.temp === 'chilled')), open };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [items, placed, unitConstants, brand]);

  const orderCount = (['ambient', 'chilled'] as Temp[]).filter((t) => totals.open.some((i) => i.temp === t)).length;

  // ── add item
  function addItem() {
    const e: Record<string, string> = {};
    const qty = Number(entry.qty);
    if (!entry.name.trim()) e.name = 'Enter an item name.';
    if (!entry.itemId.trim()) e.itemId = 'Enter an item id.';
    if (!Number.isInteger(qty) || qty < 1) e.qty = 'Enter a whole number, at least 1.';
    if (entry.temp === 'chilled' && !isFresh) e.temp = 'Chilled is for Fresh outlets only.';
    if (placed[entry.temp]) e.temp = `Your ${TEMP_LABEL[entry.temp]} order is already placed.`;
    const c = consts(unitConstants, brand, entry.temp);
    if (!c) {
      if (!(Number(entry.weight) > 0)) e.weight = 'Enter weight per unit (standard conversion unavailable).';
      if (!(Number(entry.volume) > 0)) e.volume = 'Enter volume per unit (standard conversion unavailable).';
    }
    if (entry.weight !== '' && !(Number(entry.weight) > 0)) e.weight = 'Weight must be above 0.';
    if (entry.volume !== '' && !(Number(entry.volume) > 0)) e.volume = 'Volume must be above 0.';
    setEntryErrors(e);
    if (Object.keys(e).length) return;

    setItems((list) => {
      const same = list.find((i) => i.itemId.toLowerCase() === entry.itemId.trim().toLowerCase() && i.temp === entry.temp);
      if (same) return list.map((i) => (i.key === same.key ? { ...i, qty: i.qty + qty } : i));
      return [...list, {
        key: crypto.randomUUID(), itemId: entry.itemId.trim(), name: entry.name.trim(), temp: entry.temp, qty,
        weightPerUnit: entry.weight, volumePerUnit: entry.volume,
      }];
    });
    setEntry(emptyEntry(entry.temp));
    setMsg(null);
  }

  const setQty = (key: string, qty: number) =>
    setItems((l) => l.map((i) => (i.key === key ? { ...i, qty: Math.max(1, Math.floor(qty) || 1) } : i)));
  const removeItem = (key: string) => setItems((l) => l.filter((i) => i.key !== key));

  // ── submit: one POST /orders per temperature group
  async function handleSubmit(event?: React.FormEvent) {
    event?.preventDefault();
    setFormError(null);
    if (isOffline || submitting) return;

    if (items.length === 0) {
      const qty = Number(entry.qty);
      if (!Number.isInteger(qty) || qty < 1) {
        setFormError('Enter a whole number of units, at least 1.');
        return;
      }

      const temp = entry.temp;
      const quantityOverride = Number(entry.weight) > 0 ? Number(entry.weight) : undefined;
      const volumeOverride = Number(entry.volume) > 0 ? Number(entry.volume) : undefined;
      const hasStandard = Boolean(consts(unitConstants, brand, temp));
      if (!hasStandard && (!quantityOverride || !volumeOverride)) {
        setFormError('Enter the weight and volume values required for this outlet.');
        return;
      }

      const payload: CreateOrderRequest = {
        outlet_id: outletId,
        temp_requirement: temp,
        order_units: qty,
        note: extraNote.trim() || undefined,
        client_op_id: crypto.randomUUID(),
      };

      if (!hasStandard) {
        payload.order_weight_kg = Number(quantityOverride ?? 0);
        payload.order_volume_m3 = Number(volumeOverride ?? 0);
      }

      try {
        const result = await createOrder.mutateAsync(payload);
        setPlaced((p) => ({ ...p, [temp]: result }));
        setEntry(emptyEntry(temp));
        setFormError(null);
      } catch (error) {
        setFormError(error instanceof Error ? error.message : 'Failed to submit order.');
      }
      return;
    }

    if (totals.open.length === 0) { setFormError('Add at least one item.'); return; }
    if (totals.open.some((i) => { const p = perUnit(i); return !Number.isFinite(p.w) || !Number.isFinite(p.v); })) {
      setFormError('Some items have no weight or volume and no standard conversion exists. Edit them and try again.');
      return;
    }
    setSubmitting(true);
    const nextFailed: Partial<Record<Temp, unknown>> = {};
    for (const temp of ['ambient', 'chilled'] as Temp[]) {
      const group = totals.open.filter((i) => i.temp === temp);
      if (group.length === 0 || placed[temp]) continue;
      const needsOverride = !consts(unitConstants, brand, temp) || group.some((i) => i.weightPerUnit !== '' || i.volumePerUnit !== '');
      const itemsText = group.map((i) => `${i.itemId} ${i.name} x${i.qty}`).join('; ');
      const payload: CreateOrderRequest = {
        outlet_id: outletId,
        temp_requirement: temp,
        order_units: group.reduce((a, i) => a + i.qty, 0),
        note: `Items: ${itemsText}${extraNote.trim() ? ` | Note: ${extraNote.trim()}` : ''}`,
        client_op_id: '',
      };
      if (needsOverride) {
        payload.order_weight_kg = Number(group.reduce((a, i) => a + lineKg(i), 0).toFixed(2));
        payload.order_volume_m3 = Number(group.reduce((a, i) => a + lineM3(i), 0).toFixed(3));
      }
      // Reuse the same client_op_id on retry while the content is unchanged; new content gets a new id.
      const sig = JSON.stringify({ ...payload, client_op_id: '' });
      if (opIds.current[temp]?.sig !== sig) opIds.current[temp] = { sig, id: crypto.randomUUID() };
      payload.client_op_id = opIds.current[temp]!.id;
      try {
        const result = await createOrder.mutateAsync(payload);
        setPlaced((p) => ({ ...p, [temp]: result }));
      } catch (error) {
        nextFailed[temp] = error;
      }
    }
    setFailed(nextFailed);
    setSubmitting(false);
    if (Object.keys(nextFailed).length === 0) { try { localStorage.removeItem(draftKey); } catch { /* ignore */ } }
  }

  function saveDraft() {
    try { localStorage.setItem(draftKey, JSON.stringify({ items: totals.open, extraNote })); setMsg('Draft saved on this device.'); }
    catch { setMsg('Could not save the draft.'); }
  }
  function clearForm() {
    try { localStorage.removeItem(draftKey); } catch { /* ignore */ }
    setItems((l) => l.filter((i) => placed[i.temp]));
    setEntry(emptyEntry()); setEntryErrors({}); setExtraNote(''); setFailed({}); setFormError(null); setMsg(null);
  }

  // ── page states
  if (outletsLoading || clockLoading) return <div className="p-4 lg:p-6"><LoadingState message="Loading outlet configuration…" /></div>;
  if (outletsError || clockError) {
    return (
      <div className="p-4 lg:p-6">
        <ErrorState error={{ error: { code: 'REFERENCE_DATA_FAILED', message: 'Could not load outlet configuration. Please retry.' } }} onRetry={() => refetchOutlets()} />
      </div>
    );
  }

  const placedList = (Object.values(placed) as CreateOrderResponse[]).filter(Boolean);
  if (placedList.length > 0 && totals.open.length === 0) {
    return (
      <div className="mx-auto max-w-4xl space-y-4 p-4 lg:p-6" data-testid="order-confirmations">
        {placedList.map((r) => (
          <OrderConfirmationCard key={r.confirmation_code} result={r}
            onPlaceAnother={() => { setPlaced({}); setItems([]); setExtraNote(''); setFailed({}); opIds.current = {}; }} />
        ))}
      </div>
    );
  }

  const shown = items.filter((i) =>
    (filter === 'all' || i.temp === filter) &&
    (!search.trim() || `${i.name} ${i.itemId}`.toLowerCase().includes(search.trim().toLowerCase())));
  const window_ = outlet?.mall_window || (outlet ? `${outlet.window_open_time}-${outlet.window_close_time}` : '');
  const runLabel = totals.chilled.units && totals.ambient.units ? 'Mixed run' : totals.chilled.units ? 'Chilled run' : 'Dry run';
  const maxKg = Math.max(totals.ambient.kg, totals.chilled.kg, 1);

  const inputCls = 'w-full rounded-md border-0 bg-[#E4E1D6] px-3 py-2 text-sm focus:outline-none focus-visible:ring-2 focus-visible:ring-[#2B6E62]';
  const formErrorState = formError ? { error: { code: 'ORDER_SUBMIT_FAILED', message: formError } } : null;

  return (
    <form data-testid="order-form" noValidate onSubmit={(event) => { void handleSubmit(event); }} className="mx-auto max-w-6xl p-4 lg:p-6">
      {formErrorState && <div className="mb-4"><ErrorState error={formErrorState} title="Order could not be placed" /></div>}
      {/* Title row */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          <span className="flex h-11 w-11 items-center justify-center rounded-xl bg-[#2B6E62] text-white"><Package className="h-5 w-5" /></span>
          <div>
            <p className="text-[10px] font-bold uppercase tracking-wide text-[#2B6E62]">Outlet restock</p>
            <h1 className="text-xl font-bold text-slate-900">Create store order</h1>
          </div>
        </div>
        <button type="button" onClick={clearForm} disabled={submitting}
          className="flex items-center gap-1.5 rounded-lg bg-[#F4F1E6] px-3 py-2 text-xs font-semibold text-slate-700 hover:bg-[#ebe7d6] disabled:opacity-50">
          <RotateCcw className="h-3.5 w-3.5" /> Clear form
        </button>
      </div>

      {/* Brand (read-only) + temperature toggle for the add-item form */}
      <div className="mt-4 flex flex-wrap items-center justify-between gap-3 border-b border-slate-100 pb-4">
        <div className="flex items-center gap-2 text-xs">
          <span className="rounded-md bg-[#2B6E62] px-3 py-1.5 font-semibold text-white">Waypoint {brand || 'outlet'}</span>
          <span className="text-slate-500">Brand is fixed by your outlet.</span>
        </div>
        <div role="radiogroup" aria-label="Temperature for new items" className="flex gap-1 rounded-lg bg-[#F4F1E6] p-1 text-xs font-semibold">
          <button type="button" role="radio" aria-checked={entry.temp === 'ambient'} data-testid="radio-ambient"
            onClick={() => setEntry((e) => ({ ...e, temp: 'ambient' }))}
            className={`flex items-center gap-1.5 rounded-md px-3 py-1.5 ${entry.temp === 'ambient' ? 'bg-[#2B6E62] text-white' : 'text-slate-700'}`}>
            <Sun className="h-3.5 w-3.5" /> Dry groceries (ambient)
          </button>
          {isFresh ? (
            <button type="button" role="radio" aria-checked={entry.temp === 'chilled'} data-testid="radio-chilled"
              onClick={() => setEntry((e) => ({ ...e, temp: 'chilled' }))}
              className={`flex items-center gap-1.5 rounded-md px-3 py-1.5 ${entry.temp === 'chilled' ? 'bg-[#2B6E62] text-white' : 'text-slate-700'}`}>
              <Snowflake className="h-3.5 w-3.5" /> Chilled
            </button>
          ) : (
            <span data-testid="chilled-unavailable" className="px-3 py-1.5 text-slate-500">Chilled is for Fresh outlets only ({brand || 'unassigned'})</span>
          )}
        </div>
      </div>

      {isOffline && (
        <div data-testid="offline-submit-block" className="mt-4 flex items-center gap-2 rounded-lg border border-amber-300 bg-amber-50 px-3 py-2 text-sm font-semibold text-amber-800">
          <WifiOff className="h-4 w-4" /> Connect to place an order
        </div>
      )}

      <div className="mt-5 grid gap-6 lg:grid-cols-[1.25fr_0.75fr]">
        {/* ═════════ LEFT ═════════ */}
        <section aria-label="Items" className="min-w-0 space-y-4">
          {/* Add-item form */}
          <div onKeyDown={(e) => { if (e.key === 'Enter' && (e.target as HTMLElement).tagName === 'INPUT') { e.preventDefault(); addItem(); } }}>
            <div className="rounded-md bg-[#2B6E62] py-1.5 text-center text-xs font-semibold text-white">Add item</div>
            <div className="mt-2 space-y-2">
              {([
                ['Item name', 'name', 'text', 'e.g. Highland Fresh Milk 1L'],
                ['Item id', 'itemId', 'text', 'e.g. SKU-4419'],
              ] as const).map(([label, k, type, ph]) => (
                <label key={k} className="flex items-center gap-3 rounded-lg bg-[#F4F1E6] px-4 py-2.5 text-sm font-semibold">
                  <span className="w-28 shrink-0 text-right text-xs">{label}</span>
                  <span className="flex-1">
                    <input data-testid={`input-${k}`} type={type} value={entry[k]} placeholder={ph}
                      onChange={(e) => setEntry((s) => ({ ...s, [k]: e.target.value }))} className={inputCls} />
                    {entryErrors[k] && <span className="text-[11px] font-normal text-red-700">{entryErrors[k]}</span>}
                  </span>
                </label>
              ))}

              <div className="flex items-center gap-3 rounded-lg bg-[#F4F1E6] px-4 py-2.5 text-sm font-semibold">
                <span className="w-28 shrink-0 text-right text-xs">Temperature</span>
                <span className="flex-1">
                  <span className="block rounded-md bg-[#E4E1D6] px-3 py-2 text-sm capitalize">{TEMP_LABEL[entry.temp]}</span>
                  <span className="text-[10px] font-normal text-slate-500">Change it with the toggle above.</span>
                  {entryErrors.temp && <span className="block text-[11px] font-normal text-red-700">{entryErrors.temp}</span>}
                </span>
              </div>

              {(() => {
                const standard = consts(unitConstants, brand, entry.temp);
                return (
                  <>
                    {!standard && (
                      <div data-testid="fallback-inputs" className="mt-2 rounded-lg border border-amber-200 bg-amber-50 p-3 text-[11px] text-amber-800">
                        Standard conversion values are unavailable for this outlet and temperature. Enter per-unit kg and m³ values.
                      </div>
                    )}
                    {([
                      ['Quantity (units)', 'qty', 1, 1, 'input-units'],
                      ['Weight per unit (kg)', 'weight', 0.01, 0.01, 'input-weight'],
                      ['Volume per unit (m³)', 'volume', 0.001, 0.001, 'input-volume'],
                    ] as const).map(([label, k, step, min, tid]) => (
                      <label key={k} className="mt-2 flex items-center gap-3 rounded-lg bg-[#F4F1E6] px-4 py-2.5 text-sm font-semibold">
                        <span className="w-28 shrink-0 text-right text-xs">{label}</span>
                        <span className="flex-1">
                          <input data-testid={tid} type="number" min={min} step={step} value={entry[k]}
                            placeholder={k === 'qty' ? '' : 'Optional: blank uses the standard conversion'}
                            onChange={(e) => setEntry((s) => ({ ...s, [k]: e.target.value }))} className={inputCls} />
                          {entryErrors[k] && <span className="text-[11px] font-normal text-red-700">{entryErrors[k]}</span>}
                        </span>
                      </label>
                    ))}
                  </>
                );
              })()}
            </div>
            <button type="button" onClick={addItem} data-testid="add-item"
              className="mt-2 flex items-center gap-1.5 rounded-md bg-[#2B6E62] px-4 py-2 text-xs font-semibold text-white hover:bg-[#245C52]">
              <Plus className="h-3.5 w-3.5" /> Add item
            </button>
          </div>

          {/* Additional note */}
          <label className="block rounded-lg bg-[#F4F1E6] p-3 text-xs font-semibold">Additional note (optional)
            <textarea value={extraNote} onChange={(e) => setExtraNote(e.target.value)} rows={2} placeholder="Delivery instructions for the dispatcher"
              className="mt-1 block w-full rounded-md border-0 bg-[#E4E1D6] p-2 text-sm font-normal" />
          </label>

          {/* Filter + search over added items */}
          <div className="flex flex-wrap gap-2">
            {([['all', 'All items'], ['ambient', 'Dry'], ['chilled', 'Chilled']] as [Filter, string][]).map(([k, l]) => (
              <button key={k} type="button" onClick={() => setFilter(k)} aria-pressed={filter === k}
                className={`rounded-md px-3 py-1.5 text-xs font-semibold ${filter === k ? 'bg-[#2B6E62] text-white' : 'bg-[#F4F1E6] text-slate-700'}`}>
                {l} ({k === 'all' ? items.length : items.filter((i) => i.temp === k).length})
              </button>
            ))}
          </div>
          <label className="flex items-center gap-2 rounded-lg bg-[#F4F1E6] px-3 py-2.5">
            <Search className="h-4 w-4 text-slate-500" />
            <span className="sr-only">Search added items</span>
            <input value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Search added items by name or id"
              className="w-full border-0 bg-transparent text-sm focus:outline-none" />
          </label>

          {/* Added items */}
          {items.length === 0 ? (
            <p data-testid="no-items" className="rounded-xl border border-dashed border-slate-300 p-6 text-center text-sm text-slate-500">
              No items yet. Fill in the form above and choose Add item.
            </p>
          ) : shown.length === 0 ? (
            <p className="rounded-xl border border-dashed border-slate-300 p-4 text-center text-sm text-slate-500">No items match this view.</p>
          ) : (
            <ul data-testid="items-list" className="space-y-2.5">
              {shown.map((it) => {
                const locked = Boolean(placed[it.temp]) || submitting;
                const p = perUnit(it);
                return (
                  <li key={it.key} data-testid={`item-${it.itemId}`} className="flex flex-wrap items-center justify-between gap-3 rounded-xl bg-[#B8D8CC] px-3 py-2.5">
                    <div className="min-w-0">
                      <p className="flex flex-wrap items-center gap-1.5 text-[10px] font-bold text-[#16322B]">
                        {it.itemId}
                        <span className="rounded bg-white px-1.5 py-0.5 font-semibold">{it.temp === 'chilled' ? 'Chilled' : 'Dry'}</span>
                        {placed[it.temp] && <span className="flex items-center gap-0.5 text-[#0F5C45]"><Check className="h-3 w-3" /> Placed</span>}
                      </p>
                      <p className="truncate text-base font-bold text-slate-900">{it.name}</p>
                      <p className="text-[11px] text-slate-700">
                        {Number.isFinite(p.w) ? `${p.w} kg/unit` : 'weight missing'} • {Number.isFinite(p.v) ? `${p.v} m³/unit` : 'volume missing'}
                        {it.weightPerUnit === '' && it.volumePerUnit === '' && ' (standard)'}
                      </p>
                    </div>
                    <div className="flex items-center gap-3">
                      <div className="text-right text-xs text-[#16322B]">
                        <p className="font-bold">{lineKg(it).toFixed(1)} kg</p>
                        <p>{lineM3(it).toFixed(3)} m³</p>
                      </div>
                      <div className="flex items-center gap-1 rounded-lg bg-white p-1 shadow-sm">
                        <button type="button" aria-label={`Decrease ${it.name}`} disabled={locked || it.qty <= 1} onClick={() => setQty(it.key, it.qty - 1)}
                          className="flex h-8 w-8 items-center justify-center rounded-md text-[#2B6E62] hover:bg-slate-100 disabled:opacity-40"><Minus className="h-4 w-4" /></button>
                        <label className="text-center">
                          <span className="sr-only">Quantity of {it.name}</span>
                          <input type="number" min={1} step={1} value={it.qty} disabled={locked} onChange={(e) => setQty(it.key, Number(e.target.value))}
                            className="w-12 border-0 bg-transparent text-center text-lg font-bold focus:outline-none" />
                          <span className="-mt-1 block text-[9px] text-slate-500">units</span>
                        </label>
                        <button type="button" aria-label={`Increase ${it.name}`} disabled={locked} onClick={() => setQty(it.key, it.qty + 1)}
                          className="flex h-8 w-8 items-center justify-center rounded-md bg-[#2B6E62] text-white hover:bg-[#245C52] disabled:opacity-40"><Plus className="h-4 w-4" /></button>
                      </div>
                      {!locked && (
                        <button type="button" aria-label={`Remove ${it.name}`} onClick={() => removeItem(it.key)} className="rounded-lg bg-white p-2 text-slate-600 hover:text-red-700">
                          <Trash2 className="h-4 w-4" />
                        </button>
                      )}
                    </div>
                  </li>
                );
              })}
            </ul>
          )}
        </section>

        {/* ═════════ RIGHT: summary ═════════ */}
        <aside aria-label="Order summary" className="space-y-3 self-start rounded-2xl border border-slate-100 p-4">
          <div>
            <p className="text-[9px] font-bold uppercase tracking-wide text-[#2B6E62]">Consolidated dispatch</p>
            <h2 className="text-lg font-bold text-slate-900">Order summary</h2>
            <p className="text-xs text-slate-500">{runLabel} • {totals.open.length} item{totals.open.length !== 1 ? 's' : ''} • {orderCount} order{orderCount !== 1 ? 's' : ''}</p>
          </div>

          <div className="rounded-lg bg-[#FFDDD0] p-3"><CutoffCountdown /></div>

          {/* Delivery window (from the outlet record; date and vehicle come from planning) */}
          <div className="rounded-lg border border-slate-100 p-3 text-xs">
            <div className="flex items-center justify-between">
              <span className="text-slate-500">Delivery window</span>
              <span className="font-semibold text-[#0F5C45]">{outlet?.depot ?? '—'} → {outlet?.district ?? '—'}</span>
            </div>
            <p className="mt-1 flex items-center gap-2 text-lg font-bold"><Truck className="h-4 w-4 text-[#2B6E62]" />{window_ ? window_.replace('-', ' – ') : '—'}</p>
            <p className="mt-1 text-slate-600">Date: set by the server on submit (next operating day before the cutoff).</p>
            <p className="text-slate-600">Vehicle: assigned when the dispatcher plans the run.</p>
          </div>

          <dl className="grid grid-cols-3 gap-2 rounded-lg bg-[#F4F1E6] p-3 text-center">
            <div><dt className="text-[9px] text-slate-500">Total units</dt><dd className="text-xl font-bold text-[#0F5C45]">{totals.all.units}</dd></div>
            <div><dt className="text-[9px] text-slate-500">Est. weight</dt><dd className="text-xl font-bold">{totals.all.kg.toFixed(0)}<span className="text-xs"> kg</span></dd></div>
            <div><dt className="text-[9px] text-slate-500">Est. volume</dt><dd className="text-xl font-bold">{totals.all.m3.toFixed(1)}<span className="text-xs"> m³</span></dd></div>
          </dl>

          <div className="flex items-center gap-1.5 rounded-lg bg-[#F4F1E6] px-3 py-2 text-xs font-semibold text-[#0F5C45]">
            <CheckCircle2 className="h-3.5 w-3.5" /> Temperature segregation
          </div>
          <div className="space-y-2 text-xs">
            {(['chilled', 'ambient'] as Temp[]).map((t) => (
              <div key={t}>
                <div className="flex justify-between"><span>{t === 'chilled' ? 'Chilled order' : 'Dry order'} • {totals[t].units} units</span><b>{totals[t].kg.toFixed(0)} kg</b></div>
                <div className="mt-1 h-1.5 rounded bg-slate-100"><div className="h-1.5 rounded bg-[#2B6E62]" style={{ width: `${(totals[t].kg / maxKg) * 100}%` }} /></div>
              </div>
            ))}
          </div>

          <ul className="max-h-44 divide-y divide-slate-100 overflow-y-auto text-xs" aria-label="Items in this order">
            {totals.open.length === 0 && <li className="py-2 text-slate-500">No items added.</li>}
            {totals.open.map((i) => (
              <li key={i.key} className="flex justify-between gap-2 py-1.5">
                <span className="truncate">{i.qty}× {i.name}</span>
                <span className="shrink-0 font-semibold">{lineKg(i).toFixed(0)} kg</span>
              </li>
            ))}
          </ul>

          <div className="space-y-1 border-t border-slate-200 pt-2 text-sm">
            <div className="flex justify-between text-xs text-slate-600"><span>Subtotal (chilled)</span><b>{totals.chilled.kg.toFixed(0)} kg</b></div>
            <div className="flex justify-between text-xs text-slate-600"><span>Subtotal (dry)</span><b>{totals.ambient.kg.toFixed(0)} kg</b></div>
            <div className="flex items-end justify-between"><span className="font-bold">Total weight</span><span className="text-2xl font-extrabold text-[#0F5C45]">{totals.all.kg.toFixed(0)} kg</span></div>
          </div>
          <p className="text-[10px] text-slate-500">Weight and volume are estimates. The server’s values on the confirmation are final. Items are sent to the dispatcher in the order note.</p>

          {formError && <p role="alert" className="flex items-center gap-1.5 rounded-lg bg-red-50 p-2 text-xs font-semibold text-red-700"><AlertTriangle className="h-3.5 w-3.5" />{formError}</p>}
          {(Object.entries(failed) as [Temp, unknown][]).map(([t, err]) => (
            <ErrorState key={t} error={err} title={`${TEMP_LABEL[t]} order could not be placed`} />
          ))}

          <button type="button" onClick={handleSubmit} data-testid="submit-button" disabled={submitting || isOffline || totals.open.length === 0}
            className="flex w-full items-center justify-center gap-2 rounded-lg bg-[#2B6E62] px-4 py-3 text-sm font-bold text-white hover:bg-[#245C52] disabled:bg-slate-300">
            {submitting ? <><Loader2 className="h-4 w-4 animate-spin" /> Placing…</>
              : isOffline ? <><WifiOff className="h-4 w-4" /> Connect to place an order</>
              : `Submit order (${totals.open.length} item${totals.open.length !== 1 ? 's' : ''})`}
          </button>
          <div className="grid grid-cols-2 gap-2">
            <button type="button" onClick={saveDraft} className="flex items-center justify-center gap-1.5 rounded-lg bg-[#F4F1E6] py-2 text-xs font-semibold hover:bg-[#ebe7d6]"><Save className="h-3.5 w-3.5" /> Save as draft</button>
            <button type="button" onClick={() => window.print()} className="flex items-center justify-center gap-1.5 rounded-lg bg-[#F4F1E6] py-2 text-xs font-semibold hover:bg-[#ebe7d6]"><Printer className="h-3.5 w-3.5" /> Print spec</button>
          </div>
          {msg && <p role="status" className="text-center text-[11px] text-slate-500">{msg}</p>}

          <div className="flex items-center gap-2 rounded-lg bg-[#F4F1E6] p-3 text-xs text-slate-700">
            <Warehouse className="h-4 w-4 shrink-0 text-[#2B6E62]" />
            <span>
              <b>{outlet?.depot ?? 'Depot'} depot</b>
              <span className="block">Delivering to {outletId}{outlet?.district ? `, ${outlet.district}` : ''}{outlet?.dock_type ? ` • ${String(outlet.dock_type).replace('_', ' ')}` : ''}</span>
            </span>
          </div>
        </aside>
      </div>
    </form>
  );
};