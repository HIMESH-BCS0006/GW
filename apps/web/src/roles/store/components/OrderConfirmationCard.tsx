import React from 'react';
import { CheckCircle, CalendarClock, AlertTriangle } from 'lucide-react';
import { StatusBadge } from '../../../shared/components/StatusBadge';
import type { CreateOrderResponse } from '../types';

interface OrderConfirmationCardProps {
  result: CreateOrderResponse;
  onPlaceAnother: () => void;
}

/**
 * Shown after a successful POST /orders.
 *
 * Spec rules enforced:
 *  - D18: if rolled_over=true, show rollover message with requested_delivery_date vs actual delivery_date.
 *  - D18: order_weight_kg and order_volume_m3 are always non-null in the response (read-only display).
 *  - Confirmation code displayed prominently.
 *  - Status always starts as SUBMITTED.
 */
export const OrderConfirmationCard: React.FC<OrderConfirmationCardProps> = ({
  result,
  onPlaceAnother,
}) => {
  const { order, confirmation_code, rolled_over, requested_delivery_date } = result;

  return (
    <div
      data-testid="order-confirmation"
      className="rounded-xl border border-emerald-200 bg-emerald-50 p-6 shadow-sm space-y-4"
    >
      {/* Header */}
      <div className="flex items-start gap-3">
        <CheckCircle className="mt-0.5 h-6 w-6 shrink-0 text-emerald-600" />
        <div>
          <h2 className="text-lg font-bold text-emerald-900">Order Placed</h2>
          <p className="text-sm text-emerald-700">
            Your order has been submitted and acknowledged.
          </p>
        </div>
      </div>

      {/* Rollover banner (D18) */}
      {rolled_over && (
        <div
          data-testid="rollover-notice"
          className="flex items-start gap-2 rounded-lg border border-amber-300 bg-amber-50 px-4 py-3"
        >
          <CalendarClock className="mt-0.5 h-4 w-4 shrink-0 text-amber-600" />
          <div className="text-sm text-amber-800">
            <p className="font-semibold">Cutoff passed – scheduled for the next operating day</p>
            {requested_delivery_date && (
              <p className="mt-0.5 text-xs">
                You requested{' '}
                <span className="font-mono font-bold">{requested_delivery_date}</span>
                {' '}but the order was rolled to{' '}
                <span className="font-mono font-bold">{order.delivery_date}</span>.
              </p>
            )}
          </div>
        </div>
      )}

      {/* Confirmation code */}
      <div className="rounded-lg border border-emerald-200 bg-white p-4">
        <p className="text-xs font-semibold uppercase tracking-wider text-slate-500">
          Confirmation Code
        </p>
        <p
          data-testid="confirmation-code"
          className="mt-1 font-mono text-xl font-bold text-emerald-800 tracking-wide"
        >
          {confirmation_code}
        </p>
      </div>

      {/* Order summary grid */}
      <dl className="grid grid-cols-2 gap-x-4 gap-y-3 rounded-lg border border-slate-200 bg-white p-4 text-sm sm:grid-cols-3">
        <div>
          <dt className="text-xs font-semibold text-slate-500">Order ID</dt>
          <dd className="mt-0.5 font-mono text-xs text-slate-800">{order.id}</dd>
        </div>
        <div>
          <dt className="text-xs font-semibold text-slate-500">Status</dt>
          <dd className="mt-0.5">
            <StatusBadge status={order.status} />
          </dd>
        </div>
        <div>
          <dt className="text-xs font-semibold text-slate-500">Delivery Date</dt>
          <dd className="mt-0.5 font-mono text-xs text-slate-800">{order.delivery_date}</dd>
        </div>
        <div>
          <dt className="text-xs font-semibold text-slate-500">Temperature</dt>
          <dd className="mt-0.5 capitalize text-slate-800">{order.temp_requirement}</dd>
        </div>
        <div>
          <dt className="text-xs font-semibold text-slate-500">Units Ordered</dt>
          <dd className="mt-0.5 text-slate-800">{order.order_units}</dd>
        </div>
        <div>
          <dt className="text-xs font-semibold text-slate-500">Placed At</dt>
          <dd className="mt-0.5 font-mono text-xs text-slate-800">{order.placed_at}</dd>
        </div>
        {/* D18: weight and volume always non-null in the response; displayed read-only */}
        <div>
          <dt className="text-xs font-semibold text-slate-500">Weight (derived)</dt>
          <dd className="mt-0.5 text-slate-800">{order.order_weight_kg} kg</dd>
        </div>
        <div>
          <dt className="text-xs font-semibold text-slate-500">Volume (derived)</dt>
          <dd className="mt-0.5 text-slate-800">{order.order_volume_m3} m³</dd>
        </div>
        {order.note && (
          <div className="col-span-2 sm:col-span-3">
            <dt className="text-xs font-semibold text-slate-500">Note</dt>
            <dd className="mt-0.5 text-slate-700">{order.note}</dd>
          </div>
        )}
      </dl>

      {/* Actions */}
      <div className="flex flex-col gap-2 sm:flex-row">
        <button
          onClick={onPlaceAnother}
          className="flex-1 rounded-lg border border-emerald-300 bg-white px-4 py-2.5 text-sm font-semibold text-emerald-800 hover:bg-emerald-50 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:ring-offset-2 transition-colors"
        >
          Place Another Order
        </button>
      </div>
    </div>
  );
};
