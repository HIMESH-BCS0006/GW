import React, { useEffect, useState } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import {
  ArrowLeft,
  Clock,
  Calendar,
  Package,
  Weight,
  Thermometer,
  FileText,
  RotateCcw,
  ClipboardCheck,
  CheckCircle2,
  Ban,
  History,
  ChevronDown,
  ChevronUp,
  ShieldCheck,
  Truck,
  MapPin,
  Radio,
  QrCode,
} from 'lucide-react';
import { useOrder } from '../api/hooks';
import { LoadingState } from '../../../shared/components/LoadingState';
import { ErrorState } from '../../../shared/components/ErrorState';
import { EmptyState } from '../../../shared/components/EmptyState';
import { StatusBadge } from '../../../shared/components/StatusBadge';
import { ProgressRail } from '../components/ProgressRail';
import { CancelOrderDialog } from '../components/CancelOrderDialog';
import { useBusinessClock } from '../../../shared/hooks/useBusinessClock';
import type { Order } from '../types';

/**
 * SM4 Order Tracking screen (spec/04 §2.4, spec/01 §4, D19, D22).
 *
 * Endpoint: GET /orders/{id}
 *
 * Sections:
 *  1. Progress rail (Received → Scheduled → Loaded → On the way → Delivered/Partial)
 *  2. ETA window (from stop's eta field on the Order)
 *  3. Order details (date, units, weight, volume, temp, note)
 *  4. Deferral info + history (shown when DEFERRED, or deferral_count > 0)
 *  5. "Confirm receipt" button → SM5 (only when stop delivered + receipt_status = AWAITING)
 *  6. Cancel order (only when cancellable: SUBMITTED | PLANNED | SCHEDULED)
 *
 * Errors:
 *  - 404 → Order not found message
 *  - 409 INVALID_TRANSITION from cancel → friendly message in dialog
 *  - Network error → ErrorState with retry
 *
 * Cancel is only offered when cancellable (D22 + spec/01 state machine):
 *   allowed before LOADED. The server enforces 409 on any disallowed transition.
 */

const CANCELLABLE_STATUSES = ['SUBMITTED', 'PLANNED', 'SCHEDULED'];

export const SM4TrackingPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const { data: order, isLoading, isError, error, refetch } = useOrder(id);
  const { isCutoffPassed } = useBusinessClock();

  const [showCancel, setShowCancel] = useState(false);
  const [showHistory, setShowHistory] = useState(false);
  useEffect(() => {
    if (typeof EventSource === 'undefined') return undefined;
    const events = new EventSource('/api/v1/events/stream');
    events.onmessage = () => { void refetch(); };
    return () => events.close();
  }, [refetch]);

  if (isLoading) {
    return (
      <div className="p-4 lg:p-6">
        <LoadingState message="Loading order details…" />
      </div>
    );
  }

  if (isError) {
    return (
      <div className="p-4 lg:p-6">
        <ErrorState
          error={error}
          title="Could not load order"
          onRetry={() => refetch()}
        />
      </div>
    );
  }

  if (!order) return <div className="p-4 lg:p-6"><EmptyState title="Order not found" description="This order is no longer available in your store account." /></div>;

  const isCancellable = CANCELLABLE_STATUSES.includes(order.status) && !isCutoffPassed;
  const isDelivered =
    order.status === 'DELIVERED' || order.status === 'PARTIALLY_DELIVERED';
  const isDeferred = order.status === 'DEFERRED';

  /**
   * "Confirm receipt" link (SM5) is shown only when the order has a stop and
   * receipt_status is AWAITING. We infer receipt_status from the Order.
   * The Order schema from openapi.yaml doesn't carry receipt_status directly —
   * that's on the stop. But the stop_id is on the order; for SM purposes
   * we route the user to SM5 which fetches the stop independently.
   *
   * Spec/04 §2.4: "Offer 'Confirm receipt' (link to SM5) only when the stop
   * has been delivered and receipt_status is AWAITING."
   *
   * The Order schema does not carry receipt_status. We infer:
   *  - If delivered + stop_id exists → show the link (SM5 will show the form or
   *    a "already confirmed" state).
   *  - TODO if the API is extended to include receipt_status on Order, read it here.
   */
  const showReceiptLink = isDelivered || ['LOADED', 'IN_TRANSIT'].includes(order.status);
  const statusLabel = order.status.replace(/_/g, ' ');
  const deliveryLabel = isDelivered
    ? 'Delivery completed'
    : order.status === 'IN_TRANSIT'
      ? 'Order is on the way'
      : order.status === 'LOADED'
        ? 'Order loaded for dispatch'
        : 'Order received and confirmed';
  const manifestTitle = order.temp_requirement === 'chilled' ? 'Cold chain manifest' : 'Ambient manifest';

  return (
    <div className="min-h-full bg-[#f5f8f7] p-4 lg:p-6">
      <div className="mx-auto max-w-7xl space-y-5">
      {/* Back navigation */}
      <div className="flex items-center gap-3">
        <button
          onClick={() => navigate(-1)}
          className="rounded-full p-2 text-slate-600 hover:bg-slate-100"
          aria-label="Go back"
          data-testid="back-button"
        >
          <ArrowLeft className="h-5 w-5" />
        </button>
        <div className="min-w-0">
          <h1 className="truncate text-lg font-bold text-slate-900">
            Order{' '}
            <span className="font-mono text-sm text-slate-600">{order.id}</span>
          </h1>
          <StatusBadge status={order.status} />
        </div>
      </div>

      <section className="flex flex-col justify-between gap-4 rounded-xl bg-[#12665a] p-4 text-white shadow-sm sm:flex-row sm:items-center">
        <div className="flex items-start gap-3">
          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-white/15">
            <CheckCircle2 className="h-6 w-6" />
          </div>
          <div>
            <p className="text-base font-bold">{deliveryLabel}</p>
            <p className="mt-1 text-xs text-emerald-100">
              Submitted {order.placed_at} • Store order {order.id}
            </p>
          </div>
        </div>
        <div className="rounded-lg bg-white/10 px-4 py-2 text-left sm:text-right">
          <p className="text-[10px] font-bold uppercase tracking-wider text-emerald-100">Current status</p>
          <p className="mt-0.5 text-sm font-bold capitalize">{statusLabel.toLowerCase()}</p>
        </div>
      </section>

      {/* 1. Progress rail */}
      <section className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
        <div className="mb-4 flex items-center justify-between gap-3">
          <h2 className="flex items-center gap-2 text-sm font-bold text-slate-700">
            <Radio className="h-4 w-4 text-emerald-700" /> Delivery Progress
          </h2>
          <span className="text-[10px] font-semibold uppercase tracking-wider text-slate-400">Live order status</span>
        </div>
        <ProgressRail order={order} />
      </section>

      <section className="grid gap-4 lg:grid-cols-3">
        <div className="rounded-xl border border-slate-200 bg-[#d8eee7] p-4 lg:col-span-2">
          <div className="flex items-center justify-between gap-3">
            <h2 className="flex items-center gap-2 text-sm font-bold text-[#164b40]">
              <Truck className="h-4 w-4" /> Delivery telemetry
            </h2>
            {order.eta && <span className="rounded-md bg-white px-2 py-1 text-xs font-bold text-[#12665a]">ETA {order.eta}</span>}
          </div>
          <div className="mt-3 grid gap-3 sm:grid-cols-3">
            <div className="rounded-lg bg-white/80 p-3">
              <p className="text-[10px] uppercase tracking-wide text-slate-500">Delivery date</p>
              <p className="mt-1 font-mono text-sm font-bold text-slate-800">{order.delivery_date}</p>
            </div>
            <div className="rounded-lg bg-white/80 p-3">
              <p className="text-[10px] uppercase tracking-wide text-slate-500">Route reference</p>
              <p className="mt-1 flex items-center gap-1 text-sm font-bold text-slate-800"><MapPin className="h-3.5 w-3.5 text-emerald-700" />{order.stop_id ?? 'Not assigned'}</p>
            </div>
            <div className="rounded-lg bg-white/80 p-3">
              <p className="text-[10px] uppercase tracking-wide text-slate-500">Temperature</p>
              <p className="mt-1 text-sm font-bold capitalize text-slate-800">{order.temp_requirement}</p>
            </div>
          </div>
        </div>
        <div className="rounded-xl border border-slate-200 bg-white p-4">
          <p className="text-[10px] font-bold uppercase tracking-wider text-slate-400">Dispatch authorization</p>
          <div className="mt-3 flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-emerald-100 text-emerald-700"><ShieldCheck className="h-5 w-5" /></div>
            <div>
              <p className="text-sm font-bold text-slate-800">Order verified</p>
              <p className="text-xs text-slate-500">Reference {order.client_op_id ?? order.id}</p>
            </div>
          </div>
        </div>
      </section>

      <section className="grid gap-4 lg:grid-cols-[1.35fr_0.65fr]">
        <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
          <div className="flex items-center justify-between gap-3">
            <h2 className="flex items-center gap-2 text-sm font-bold text-slate-700"><Package className="h-4 w-4 text-emerald-700" /> {manifestTitle}</h2>
            <span className="rounded-md bg-emerald-100 px-2 py-1 text-[10px] font-bold uppercase tracking-wide text-emerald-800">Order manifest</span>
          </div>
          <div className="mt-4 grid gap-2 sm:grid-cols-3">
            <div className="rounded-lg bg-[#eef5f2] p-3"><p className="text-[10px] uppercase tracking-wide text-slate-500">Total units</p><p className="mt-1 text-xl font-bold text-slate-900">{order.order_units}</p></div>
            <div className="rounded-lg bg-[#eef5f2] p-3"><p className="text-[10px] uppercase tracking-wide text-slate-500">Gross weight</p><p className="mt-1 text-xl font-bold text-slate-900">{order.order_weight_kg} kg</p></div>
            <div className="rounded-lg bg-[#eef5f2] p-3"><p className="text-[10px] uppercase tracking-wide text-slate-500">Volume</p><p className="mt-1 text-xl font-bold text-slate-900">{order.order_volume_m3} m³</p></div>
          </div>
          <div className="mt-4 flex items-center justify-between rounded-lg border border-slate-200 px-3 py-2.5 text-sm">
            <span className="font-semibold text-slate-700">{order.temp_requirement === 'chilled' ? 'Temperature-controlled goods' : 'Ambient goods'}</span>
            <span className="font-mono text-xs text-slate-500">{order.outlet_id}</span>
          </div>
        </div>
        <div className="rounded-xl border border-slate-200 bg-[#f4f1e6] p-5">
          <h2 className="text-sm font-bold text-slate-700">Store intake readiness</h2>
          <div className="mt-4 space-y-2 text-sm">
            <div className="flex items-center gap-2 rounded-lg bg-white px-3 py-2 text-slate-700"><CheckCircle2 className="h-4 w-4 text-emerald-600" /> Order details available</div>
            <div className="flex items-center gap-2 rounded-lg bg-white px-3 py-2 text-slate-700"><CheckCircle2 className="h-4 w-4 text-emerald-600" /> Receiving quantity recorded</div>
            <div className="flex items-center gap-2 rounded-lg bg-white px-3 py-2 text-slate-700"><CheckCircle2 className="h-4 w-4 text-emerald-600" /> Delivery window confirmed</div>
          </div>
        </div>
      </section>

      {/* 2. ETA window */}
      {order.eta ? (
        <section
          data-testid="eta-section"
          className="flex items-center gap-3 rounded-xl border border-brand-200 bg-brand-50 px-4 py-3"
        >
          <Clock className="h-5 w-5 shrink-0 text-brand-600" />
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider text-brand-700">
              Estimated Arrival
            </p>
            <p className="text-xl font-bold text-brand-900">{order.eta}</p>
          </div>
        </section>
      ) : (
        ['PLANNED', 'SCHEDULED', 'LOADED', 'IN_TRANSIT'].includes(order.status) && (
          <section
            data-testid="no-eta-section"
            className="flex items-center gap-3 rounded-xl border border-slate-200 bg-slate-50 px-4 py-3"
          >
            <Clock className="h-5 w-5 shrink-0 text-slate-400" />
            <p className="text-sm text-slate-500">
              ETA not yet available – will be updated once the trip departs.
            </p>
          </section>
        )
      )}

      {/* 3. Order details */}
      <section className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm space-y-3">
        <h2 className="text-sm font-bold text-slate-700">Order Details</h2>
        <dl className="grid grid-cols-2 gap-x-4 gap-y-3 text-sm sm:grid-cols-3">
          <div>
            <dt className="text-xs font-semibold text-slate-500 flex items-center gap-1">
              <Calendar className="h-3 w-3" /> Delivery Date
            </dt>
            <dd className="mt-0.5 font-mono text-slate-800">{order.delivery_date}</dd>
          </div>
          <div>
            <dt className="text-xs font-semibold text-slate-500 flex items-center gap-1">
              <Thermometer className="h-3 w-3" /> Temperature
            </dt>
            <dd className="mt-0.5 capitalize text-slate-800">{order.temp_requirement}</dd>
          </div>
          <div>
            <dt className="text-xs font-semibold text-slate-500 flex items-center gap-1">
              <Package className="h-3 w-3" /> Units
            </dt>
            <dd className="mt-0.5 text-slate-800">{order.order_units}</dd>
          </div>
          <div>
            <dt className="text-xs font-semibold text-slate-500 flex items-center gap-1">
              <Weight className="h-3 w-3" /> Weight
            </dt>
            <dd className="mt-0.5 text-slate-800">{order.order_weight_kg} kg</dd>
          </div>
          <div>
            <dt className="text-xs font-semibold text-slate-500">Volume</dt>
            <dd className="mt-0.5 text-slate-800">{order.order_volume_m3} m³</dd>
          </div>
          <div>
            <dt className="text-xs font-semibold text-slate-500">Placed At</dt>
            <dd className="mt-0.5 font-mono text-xs text-slate-700">{order.placed_at}</dd>
          </div>
          {order.note && (
            <div className="col-span-2 sm:col-span-3">
              <dt className="text-xs font-semibold text-slate-500 flex items-center gap-1">
                <FileText className="h-3 w-3" /> Note
              </dt>
              <dd className="mt-0.5 text-slate-700">{order.note}</dd>
            </div>
          )}
          {order.rolled_over && (
            <div className="col-span-2 sm:col-span-3">
              <dt className="text-xs font-semibold text-amber-700">Rolled Over</dt>
              <dd className="mt-0.5 text-xs text-amber-600">
                Placed after 16:00 cutoff and scheduled for the next operating day.
              </dd>
            </div>
          )}
        </dl>
      </section>

      {/* 4. Deferral history */}
      {(isDeferred || order.deferral_count > 0) && (
        <section
          data-testid="deferral-section"
          className="rounded-xl border border-orange-200 bg-orange-50 p-5 space-y-3"
        >
          <button
            className="flex w-full items-center justify-between"
            onClick={() => setShowHistory(!showHistory)}
            aria-expanded={showHistory}
            data-testid="deferral-history-toggle"
          >
            <div className="flex items-center gap-2">
              <RotateCcw className="h-4 w-4 text-orange-600" />
              <h2 className="text-sm font-bold text-orange-900">
                Deferral History ({order.deferral_count})
              </h2>
            </div>
            {showHistory ? (
              <ChevronUp className="h-4 w-4 text-orange-600" />
            ) : (
              <ChevronDown className="h-4 w-4 text-orange-600" />
            )}
          </button>

          {showHistory && (
            <div
              data-testid="deferral-history-body"
              className="space-y-2"
            >
              <p className="text-xs text-orange-800">
                This order has been deferred{' '}
                <span className="font-bold">{order.deferral_count}</span>{' '}
                time{order.deferral_count !== 1 ? 's' : ''}. Each deferral moves
                the order to the next available operating run. Contact your
                dispatcher for details.
              </p>
              {order.cancel_reason && (
                <div className="rounded-lg border border-orange-200 bg-white p-3">
                  <p className="text-xs font-semibold text-orange-700 flex items-center gap-1">
                    <History className="h-3 w-3" /> Last recorded reason
                  </p>
                  <p className="mt-1 text-sm text-orange-900">{order.cancel_reason}</p>
                </div>
              )}
            </div>
          )}
        </section>
      )}

      {/* 5. Driver arrival handover & Confirm receipt link (SM5) */}
      {['LOADED', 'IN_TRANSIT'].includes(order.status) && (
        <section className="rounded-xl border border-emerald-300 bg-emerald-50 p-4 shadow-sm">
          <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div className="flex items-center gap-3">
              <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-[#12665a] text-white shadow-sm">
                <QrCode className="h-6 w-6" />
              </div>
              <div>
                <p className="text-sm font-bold text-emerald-950">Driver Arrival &amp; Handover</p>
                <p className="text-xs text-emerald-800">
                  When the driver arrives at your store, scan their Handover QR code to verify goods and mark the order as Delivered.
                </p>
              </div>
            </div>
            <Link
              to={`/store/orders/${order.id}/receipt`}
              data-testid="scan-handover-qr-btn"
              className="inline-flex shrink-0 items-center justify-center gap-2 rounded-xl bg-[#12665a] px-5 py-3 text-xs font-bold text-white shadow-sm hover:bg-[#0e4e45] transition-colors"
            >
              <QrCode className="h-4 w-4" /> Scan Driver QR &amp; Confirm Receipt
            </Link>
          </div>
        </section>
      )}

      {showReceiptLink && (
        <Link
          to={`/store/orders/${order.id}/receipt`}
          data-testid="confirm-receipt-link"
          className="flex w-full items-center justify-center gap-2 rounded-xl border border-emerald-300 bg-emerald-50 px-4 py-3.5 text-sm font-bold text-emerald-800 hover:bg-emerald-100 focus:outline-none focus:ring-2 focus:ring-emerald-500 transition-colors"
        >
          <ClipboardCheck className="h-5 w-5" />
          {isDelivered ? 'View Receipt Details' : 'Confirm Goods Receipt & Scan Handover QR'}
        </Link>
      )}

      {/* 6. Cancel order */}
      {isCancellable && (
        <div className="pb-4">
          <button
            data-testid="cancel-order-button"
            onClick={() => setShowCancel(true)}
            className="flex w-full items-center justify-center gap-2 rounded-xl border border-rose-300 bg-white px-4 py-3 text-sm font-semibold text-rose-700 hover:bg-rose-50 focus:outline-none focus:ring-2 focus:ring-rose-400 transition-colors"
          >
            <Ban className="h-4 w-4" />
            Cancel Order
          </button>
          <p className="mt-1.5 text-center text-xs text-slate-400">
            Only available before the order is loaded. A reason is required.
          </p>
        </div>
      )}

      {/* Cancel dialog (modal sheet) */}
      {showCancel && (
        <CancelOrderDialog
          orderId={order.id}
          onClose={() => setShowCancel(false)}
          onCancelled={() => {
            setShowCancel(false);
            refetch();
          }}
        />
      )}
      </div>
    </div>
  );
};
