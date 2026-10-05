import React, { useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import {
  AlertTriangle, Bell, CalendarX, CheckCircle2, Clock, ClipboardList, ExternalLink,
  FileText, Package, PlusCircle, ShoppingCart, Snowflake, Truck, Crosshair, QrCode,
} from 'lucide-react';
import { useAuth } from '../../../shared/auth/AuthContext';
import { LoadingState } from '../../../shared/components/LoadingState';
import { ErrorState } from '../../../shared/components/ErrorState';
import { EmptyState } from '../../../shared/components/EmptyState';
import { StatusBadge } from '../../../shared/components/StatusBadge';
import { CutoffCountdown } from '../components/CutoffCountdown';
import { useOrders, useNotifications, useExpectedDeliveries } from '../api/hooks';
import type { Order } from '../types';

type Filter = 'all' | 'progress' | 'done';
const DONE = ['DELIVERED', 'PARTIALLY_DELIVERED'];
const TERMINAL = [...DONE, 'CANCELLED'];
const isInProgress = (o: Order) => !TERMINAL.includes(o.status) && o.status !== 'DEFERRED';

/** SM1 Home (spec/04 §2.4), styled after the Figma "Store Manager Home (Desktop)". */
export const SM1HomePage: React.FC = () => {
  const { user } = useAuth();
  const outletId = user?.outlet_id;
  const [filter, setFilter] = useState<Filter>('all');

  const { data: orders, isLoading: ordersLoading, isError: ordersError, refetch: refetchOrders, error: ordersErr } = useOrders();
  const { data: notifications, isLoading: notifLoading, isError: notificationsError, error: notificationsErr, refetch: refetchNotifications } = useNotifications();
  const { data: expectedDeliveries, isLoading: deliveriesLoading, isError: deliveriesError, refetch: refetchDeliveries } =
    useExpectedDeliveries(outletId);

  const unreadCount = notifications?.filter((n: any) => !n.read_at).length ?? 0;
  const nextDelivery: any = expectedDeliveries?.find((s: any) => s.status === 'PENDING');

  const sortedOrders: Order[] = useMemo(
    () =>
      orders
        ? [...orders].sort((a, b) => {
            const ta = TERMINAL.includes(a.status) ? 1 : 0;
            const tb = TERMINAL.includes(b.status) ? 1 : 0;
            return ta !== tb ? ta - tb : a.delivery_date.localeCompare(b.delivery_date);
          })
        : [],
    [orders],
  );

  const counts = {
    all: sortedOrders.length,
    progress: sortedOrders.filter(isInProgress).length,
    done: sortedOrders.filter((o) => DONE.includes(o.status)).length,
  };
  const visible = sortedOrders.filter((o) =>
    filter === 'all' ? true : filter === 'progress' ? isInProgress(o) : DONE.includes(o.status),
  );
  const deferredOrder = sortedOrders.find((o) => o.status === 'DEFERRED');

  if (ordersLoading || notifLoading || deliveriesLoading) {
    return <div className="p-4 lg:p-6"><LoadingState message="Loading dashboard…" /></div>;
  }

  return (
    <div className="mx-auto w-full max-w-5xl space-y-5 p-4 lg:px-14 lg:py-8">
      {notificationsError && (
        <ErrorState error={notificationsErr} title="Could not load notices" onRetry={() => refetchNotifications()} />
      )}
      {/* Deferral / notices banner */}
      {(deferredOrder || unreadCount > 0) && (
        <Link
          to="/store/notifications"
          data-testid="unread-notices-link"
          className="flex items-center gap-3 rounded-xl bg-[#FFDDD0] px-3 py-2.5 shadow-sm focus:outline-none focus-visible:ring-2 focus-visible:ring-[#8A3A1C]"
        >
          <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-[#7A3A1C] text-white">
            <Bell className="h-5 w-5" />
          </span>
          <span className="min-w-0 flex-1">
            <span className="block text-[10px] font-bold uppercase tracking-wide text-[#8A3A1C]">
              {deferredOrder ? 'Deferral notice' : 'Notices'}
            </span>
            <span className="block text-sm text-slate-800">
              {deferredOrder
                ? `Order ${deferredOrder.id} was deferred. Open the notice for the reason and the new date.`
                : `${unreadCount} unread notice${unreadCount !== 1 ? 's' : ''}`}
            </span>
          </span>
          {unreadCount > 0 && (
            <span data-testid="unread-badge" className="flex h-6 min-w-6 items-center justify-center rounded-full bg-[#7A3A1C] px-1 text-xs font-bold text-white">
              {unreadCount > 9 ? '9+' : unreadCount}
            </span>
          )}
        </Link>
      )}

      {/* Next delivery + cutoff */}
      <section className="grid gap-5 lg:grid-cols-2">
        {/* Next scheduled delivery */}
        <div className="min-h-[220px] rounded-2xl bg-[#85B9A5] p-4">
          <h2 className="flex items-center gap-2 text-lg font-bold text-[#16322B]">
            <Truck className="h-4 w-4" /> Next scheduled delivery
          </h2>

          {deliveriesError ? (
            <div data-testid="next-delivery-error" className="mt-4 rounded-md bg-white p-3 text-sm text-rose-700">
              Could not load expected deliveries.{' '}
              <button onClick={() => refetchDeliveries()} className="font-semibold underline">Retry</button>
            </div>
          ) : nextDelivery ? (
            <div data-testid="next-delivery-card" className="mt-4 space-y-3">
              <div className="grid grid-cols-1 gap-2 sm:grid-cols-3">
                <div className="rounded-md bg-white p-2.5 shadow-sm">
                  <p className="text-[10px] text-slate-500">Arrival (ETA)</p>
                  <p className="flex items-center gap-1 text-sm font-bold text-[#0F5C45]">
                    <Clock className="h-3.5 w-3.5" />
                    {nextDelivery.eta ? `ETA ${nextDelivery.eta}` : 'ETA not yet set'}
                  </p>
                </div>
                {nextDelivery.service_start_est && (
                  <div className="rounded-md bg-white p-2.5 shadow-sm">
                    <p className="text-[10px] text-slate-500">Service starts</p>
                    <p className="font-mono text-sm font-bold">{nextDelivery.service_start_est}</p>
                    <p className="text-[10px] text-slate-500">{nextDelivery.service_min} min</p>
                  </div>
                )}
                {/* Show only if the API returns them; do not invent. */}
                {nextDelivery.vehicle_id && (
                  <div className="rounded-md bg-white p-2.5 shadow-sm">
                    <p className="text-[10px] text-slate-500">Vehicle</p>
                    <p className="text-sm font-bold">{nextDelivery.vehicle_id}</p>
                    {nextDelivery.driver_name && <p className="text-[10px] text-slate-500">{nextDelivery.driver_name}</p>}
                  </div>
                )}
              </div>
              {!nextDelivery.eta && (
                <p data-testid="no-eta-notice" className="text-xs text-[#16322B]">
                  ETA will appear once the trip has departed the depot.
                </p>
              )}
              <Link
                to={`/store/orders/${nextDelivery.order_id}`}
                data-testid="next-delivery-order-link"
                className="inline-flex items-center gap-1.5 rounded-lg bg-white px-3 py-1.5 text-xs font-semibold shadow-sm hover:bg-slate-50"
              >
                View order <ExternalLink className="h-3.5 w-3.5" />
              </Link>
            </div>
          ) : (
            <p data-testid="no-upcoming-delivery" className="mt-4 rounded-md bg-white/60 p-3 text-sm text-[#16322B]">
              No upcoming deliveries scheduled. Orders placed before the cutoff appear here once a trip is confirmed.
            </p>
          )}
        </div>

        {/* Cutoff + CTA */}
        <div className="rounded-2xl border border-slate-100 p-4">
          <h2 className="text-lg font-bold text-slate-900">Next restock</h2>
          <p className="mt-1 text-[11px] leading-snug text-slate-500">
            Order deadline for fresh produce, bakery and chilled lines.
          </p>
          <div className="mt-3 rounded-lg bg-[#F5F0E3] p-3">
            <CutoffCountdown />
          </div>
          <Link
            to="/store/orders/new"
            data-testid="place-order-cta"
            className="mt-4 flex w-full items-center justify-center gap-2 rounded-lg bg-[#2B6E62] py-3 text-sm font-semibold text-white transition-colors hover:bg-[#245C52] focus:outline-none focus-visible:ring-2 focus-visible:ring-[#2B6E62] focus-visible:ring-offset-2"
          >
            <ShoppingCart className="h-4 w-4" /> Place new order
          </Link>
        </div>
      </section>

      {/* Consignments */}
      <section aria-labelledby="consignments" className="pt-2">
        <div className="flex flex-wrap items-end justify-between gap-3">
          <div>
            <p className="flex items-center gap-1 text-[9px] font-bold uppercase tracking-wide text-slate-500">
              <Package className="h-3 w-3" /> Store receiving manifest
            </p>
            <h2 id="consignments" className="text-lg font-bold text-slate-900">Active &amp; recent consignments</h2>
          </div>
          <div role="tablist" className="flex gap-1 rounded-lg bg-[#F4F1E6] p-1 text-[11px] font-semibold">
            {([['all', 'All orders'], ['progress', 'In progress'], ['done', 'Completed']] as [Filter, string][]).map(([k, label]) => (
              <button
                key={k}
                role="tab"
                aria-selected={filter === k}
                onClick={() => setFilter(k)}
                className={`rounded-md px-3 py-1.5 ${filter === k ? 'bg-white shadow-sm' : 'text-slate-600 hover:bg-white/60'}`}
              >
                {label} ({counts[k]})
              </button>
            ))}
          </div>
        </div>

        <div className="mt-3">
          {ordersError ? (
            <ErrorState error={ordersErr} title="Could not load orders" onRetry={() => refetchOrders()} />
          ) : sortedOrders.length === 0 ? (
            <EmptyState
              data-testid="no-orders-empty"
              icon={<ClipboardList className="h-10 w-10" />}
              title="No orders yet"
              description="Place your first order before the cutoff."
              action={
                <Link to="/store/orders/new" className="inline-flex items-center gap-2 rounded-lg bg-[#2B6E62] px-4 py-2 text-sm font-bold text-white hover:bg-[#245C52]">
                  <PlusCircle className="h-4 w-4" /> Place order
                </Link>
              }
            />
          ) : visible.length === 0 ? (
            <p className="rounded-xl border border-dashed border-slate-300 p-6 text-center text-sm text-slate-500">
              No orders in this view.
            </p>
          ) : (
            <ul data-testid="orders-list" className="space-y-2.5">
              {visible.map((order) => <OrderListItem key={order.id} order={order} />)}
            </ul>
          )}
        </div>
      </section>
    </div>
  );
};

// ─── Order row ───────────────────────────────────────────────────────────────

export const OrderListItem: React.FC<{ order: Order }> = ({ order }) => {
  const deferred = order.status === 'DEFERRED';
  const done = DONE.includes(order.status);
  const chilled = order.temp_requirement === 'chilled';

  const rowBg = deferred ? 'bg-[#FFD9CC]' : order.status === 'CANCELLED' ? 'bg-slate-100' : 'bg-[#B8D8CC]';
  const iconBg = deferred ? 'bg-[#F2BFAA]' : done ? 'bg-[#CFF1E4]' : 'bg-[#E8EFEA]';
  const Icon = deferred ? CalendarX : done ? CheckCircle2 : chilled ? Snowflake : Truck;

  const action = deferred
    ? { label: 'View deferral', to: '/store/notifications', icon: <AlertTriangle className="h-3.5 w-3.5" /> }
    : done
      ? { label: 'Confirm / view receipt', to: `/store/orders/${order.id}/receipt`, icon: <FileText className="h-3.5 w-3.5" /> }
      : order.status === 'IN_TRANSIT'
        ? { label: 'Receive / Scan QR', to: `/store/orders/${order.id}/receipt`, icon: <QrCode className="h-3.5 w-3.5" /> }
        : { label: 'View details', to: `/store/orders/${order.id}`, icon: <ExternalLink className="h-3.5 w-3.5" /> };

  return (
    <li>
      <div
        data-testid={`order-row-${order.id}`}
        className={`flex flex-wrap items-center justify-between gap-3 rounded-xl px-3 py-2.5 ${rowBg}`}
      >
        <Link to={`/store/orders/${order.id}`} className="flex min-w-0 flex-1 items-center gap-3">
          <span className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-lg ${iconBg}`}>
            <Icon className={`h-5 w-5 ${deferred ? 'text-[#8A3A1C]' : 'text-[#2B5A50]'}`} />
          </span>
          <span className="min-w-0">
            <span className="block truncate text-sm">
              <span className={`font-bold ${deferred ? 'text-[#8A3A1C]' : ''}`}>#{order.id}</span>{' '}
              <span className="font-semibold capitalize">{order.temp_requirement}</span>
              {order.deferral_count > 0 && (
                <span className="ml-1.5 text-[10px] font-semibold text-[#8A3A1C]">Deferred ×{order.deferral_count}</span>
              )}
            </span>
            <span className="block text-[11px] text-slate-700">
              {order.order_units} units • {order.order_weight_kg.toFixed(1)} kg • {order.order_volume_m3} m³ •{' '}
              <span className="font-mono">{order.delivery_date}</span>
              {order.eta && <> • <Clock className="mb-0.5 inline h-3 w-3" /> ETA {order.eta}</>}
            </span>
          </span>
        </Link>

        <div className="flex items-center gap-3">
          <StatusBadge status={order.status} />
          <Link
            to={action.to}
            className="flex items-center gap-1.5 rounded-lg bg-white px-3.5 py-2 text-xs font-semibold shadow-sm hover:bg-slate-50 focus:outline-none focus-visible:ring-2 focus-visible:ring-[#2B6E62]"
          >
            {action.label} {action.icon}
          </Link>
        </div>
      </div>
    </li>
  );
};