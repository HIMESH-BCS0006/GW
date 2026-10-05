import React, { useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import {
  useCancelOrder,
  useGetOrderById,
} from '../api/generated/store-manager/store-manager';
import { useRequeueOrder } from '../api/generated/dispatcher/dispatcher';
import type { Order, Outlet } from '../api/generated/models';
import { OrderStatus } from '../api/generated/models';
import { StatusBadge } from './StatusBadge';
import { ErrorState } from './ErrorState';
import { LoadingState } from './LoadingState';
import { DeferralHistory } from './DeferralHistory';
import { ApiError } from '../api/http';
import { formatColomboDateTime } from '../lib/time';

/** Statuses from which cancel is allowed per the contract */
const CANCELLABLE_STATUSES: string[] = [
  OrderStatus.SUBMITTED,
  OrderStatus.PLANNED,
  OrderStatus.SCHEDULED,
];

interface OrderDetailPanelProps {
  order: Order;
  outlet?: Outlet;
  onClose: () => void;
  onCancelOrder?: (order: Order) => void;
}

export const OrderDetailPanel: React.FC<OrderDetailPanelProps> = ({
  order,
  outlet,
  onClose,
  onCancelOrder,
}) => {
  const queryClient = useQueryClient();

  // Fetch full order detail (includes deferral_history once backend adds it)
  const {
    data: detail,
    isLoading: loadingDetail,
    isError: errorDetail,
    error: detailError,
  } = useGetOrderById({ id: order.id });

  // Cancel state
  const [showCancelForm, setShowCancelForm] = useState(false);
  const [cancelReason, setCancelReason] = useState('');
  const [cancelNote, setCancelNote] = useState('');
  const [cancelInlineError, setCancelInlineError] = useState<ApiError | Error | null>(null);

  const cancelMutation = useCancelOrder({
    mutation: {
      onSuccess: () => {
        queryClient.invalidateQueries({ queryKey: ['/dispatch/queue'] });
        queryClient.invalidateQueries({ queryKey: [`/orders/${order.id}`] });
        setShowCancelForm(false);
        setCancelReason('');
        setCancelNote('');
        setCancelInlineError(null);
      },
      onError: (err: any) => {
        setCancelInlineError(err);
      },
    },
  });

  // Requeue state
  const [requeueInlineError, setRequeueInlineError] = useState<ApiError | Error | null>(null);
  const requeueMutation = useRequeueOrder({
    mutation: {
      onSuccess: () => {
        queryClient.invalidateQueries({ queryKey: ['/dispatch/queue'] });
        queryClient.invalidateQueries({ queryKey: [`/orders/${order.id}`] });
        setRequeueInlineError(null);
      },
      onError: (err: any) => {
        setRequeueInlineError(err);
      },
    },
  });

  const handleCancel = (e: React.FormEvent) => {
    e.preventDefault();
    if (!cancelReason.trim()) return;
    setCancelInlineError(null);
    cancelMutation.mutate({
      id: order.id,
      data: { reason: cancelReason.trim(), note: cancelNote.trim() || undefined },
    });
  };

  const handleRequeue = () => {
    setRequeueInlineError(null);
    requeueMutation.mutate({ id: order.id });
  };

  const displayOrder = detail ?? order;

  return (
    <div className="h-full flex flex-col bg-white border-l border-slate-200 overflow-hidden">
      {/* Header */}
      <div className="flex items-center justify-between px-5 py-4 border-b border-slate-200 bg-slate-50">
        <div>
          <p className="text-[10px] text-slate-400 uppercase font-semibold tracking-wide">
            Order Detail
          </p>
          <h2 className="text-base font-bold text-slate-900 font-mono">{order.id}</h2>
        </div>
        <button
          onClick={onClose}
          className="text-slate-400 hover:text-slate-700 text-lg font-bold leading-none p-1"
          aria-label="Close panel"
        >
          ×
        </button>
      </div>

      <div className="flex-1 overflow-y-auto px-5 py-4 space-y-5">
        {loadingDetail && <LoadingState message="Loading order details…" />}
        {errorDetail && detailError && (
          <ErrorState error={detailError} />
        )}

        {/* Outlet info */}
        {outlet && (
          <section>
            <h3 className="text-[10px] uppercase font-semibold text-slate-400 tracking-wide mb-2">
              Outlet
            </h3>
            <div className="grid grid-cols-2 gap-x-4 gap-y-1 text-xs">
              <div className="text-slate-500">Outlet ID</div>
              <div className="font-mono font-semibold text-slate-800">{outlet.outlet_id}</div>
              <div className="text-slate-500">Brand</div>
              <div className="font-semibold text-slate-800">{outlet.brand}</div>
              <div className="text-slate-500">District</div>
              <div className="text-slate-800">{outlet.district}</div>
              <div className="text-slate-500">Depot</div>
              <div className="text-slate-800">{outlet.depot}</div>
              <div className="text-slate-500">Window</div>
              <div className="text-slate-800">
                {outlet.window_open_time} – {outlet.window_close_time}
              </div>
            </div>
          </section>
        )}

        {/* Status & key fields */}
        <section>
          <h3 className="text-[10px] uppercase font-semibold text-slate-400 tracking-wide mb-2">
            Status & Timeline
          </h3>
          <div className="grid grid-cols-2 gap-x-4 gap-y-1.5 text-xs">
            <div className="text-slate-500">Status</div>
            <div>
              <StatusBadge status={displayOrder.status} type="order" />
            </div>

            <div className="text-slate-500">Delivery Date</div>
            <div className="font-mono text-slate-800">{displayOrder.delivery_date}</div>

            {displayOrder.rolled_over && (
              <>
                <div className="text-slate-500">Rolled Over</div>
                <div className="font-semibold text-amber-700">
                  Yes — requested: {displayOrder.requested_delivery_date ?? '–'}
                </div>
              </>
            )}

            <div className="text-slate-500">Placed At</div>
            <div className="text-slate-800">{formatColomboDateTime(displayOrder.placed_at)}</div>

            {displayOrder.trip_id && (
              <>
                <div className="text-slate-500">Trip ID</div>
                <div className="font-mono font-semibold text-indigo-700">{displayOrder.trip_id}</div>
              </>
            )}
            {displayOrder.stop_id && (
              <>
                <div className="text-slate-500">Stop ID</div>
                <div className="font-mono text-slate-800">{displayOrder.stop_id}</div>
              </>
            )}
            {displayOrder.eta && (
              <>
                <div className="text-slate-500">ETA</div>
                <div className="font-mono font-bold text-brand-700">{displayOrder.eta}</div>
              </>
            )}
          </div>
        </section>

        {/* Order payload */}
        <section>
          <h3 className="text-[10px] uppercase font-semibold text-slate-400 tracking-wide mb-2">
            Payload
          </h3>
          <div className="grid grid-cols-2 gap-x-4 gap-y-1 text-xs">
            <div className="text-slate-500">Temperature</div>
            <div className="font-semibold text-slate-800">{displayOrder.temp_requirement}</div>
            <div className="text-slate-500">Units</div>
            <div className="text-slate-800">{displayOrder.order_units}</div>
            <div className="text-slate-500">Weight</div>
            <div className="text-slate-800">{displayOrder.order_weight_kg} kg</div>
            <div className="text-slate-500">Volume</div>
            <div className="text-slate-800">{displayOrder.order_volume_m3} m³</div>
            {displayOrder.deferral_count > 0 && (
              <>
                <div className="text-slate-500">Times Deferred</div>
                <div className="font-bold text-red-700">{displayOrder.deferral_count}×</div>
              </>
            )}
            {displayOrder.note && (
              <>
                <div className="text-slate-500">Note</div>
                <div className="text-slate-800 col-span-1">{displayOrder.note}</div>
              </>
            )}
          </div>
        </section>

        {/* Deferral history – will be populated once backend adds deferral_history to Order GET response */}
        <section>
          <h3 className="text-[10px] uppercase font-semibold text-slate-400 tracking-wide mb-2">
            Deferral History
          </h3>
          {/* TODO: backend to add deferral_history: Deferral[] to GET /orders/{id} response */}
          <DeferralHistory deferrals={(displayOrder as any).deferral_history ?? []} />
        </section>

        {/* Actions */}
        <section className="border-t border-slate-200 pt-4">
          <h3 className="text-[10px] uppercase font-semibold text-slate-400 tracking-wide mb-3">
            Actions
          </h3>

          {/* Requeue (DEFERRED only) */}
          {displayOrder.status === OrderStatus.DEFERRED && (
            <div className="mb-3">
              {requeueInlineError && <ErrorState error={requeueInlineError} />}
              <button
                onClick={handleRequeue}
                disabled={requeueMutation.isPending}
                className="w-full bg-brand-600 hover:bg-brand-700 disabled:opacity-50 text-white text-xs font-semibold py-2 px-4 rounded-md transition-colors"
              >
                {requeueMutation.isPending ? 'Requeueing…' : 'Requeue Order'}
              </button>
            </div>
          )}

          {/* Cancel (SUBMITTED / PLANNED / SCHEDULED) */}
          {CANCELLABLE_STATUSES.includes(displayOrder.status) && (
            <div>
              {!showCancelForm ? (
                <button
                  onClick={() => {
                    if (onCancelOrder) {
                      onCancelOrder(displayOrder);
                    } else {
                      setShowCancelForm(true);
                    }
                  }}
                  className="w-full flex items-center justify-center gap-1.5 border border-red-300 text-red-700 hover:bg-red-50 text-xs font-semibold py-2 px-4 rounded-lg transition-colors"
                >
                  <svg className="w-3.5 h-3.5 text-red-600" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <circle cx="12" cy="12" r="10" />
                    <line x1="4.93" y1="4.93" x2="19.07" y2="19.07" />
                  </svg>
                  Cancel Order…
                </button>
              ) : (
                <form onSubmit={handleCancel} className="space-y-2">
                  {cancelInlineError && <ErrorState error={cancelInlineError} />}
                  <div>
                    <label className="block text-xs font-semibold text-slate-700 mb-1">
                      Reason <span className="text-red-600">*</span>
                    </label>
                    <textarea
                      required
                      rows={2}
                      value={cancelReason}
                      onChange={(e) => setCancelReason(e.target.value)}
                      placeholder="Mandatory reason for cancellation…"
                      className="w-full border border-slate-300 rounded-md px-3 py-2 text-xs focus:ring-2 focus:ring-red-400 resize-none"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-semibold text-slate-700 mb-1">
                      Note <span className="text-slate-400">(optional)</span>
                    </label>
                    <input
                      type="text"
                      value={cancelNote}
                      onChange={(e) => setCancelNote(e.target.value)}
                      placeholder="Additional note…"
                      className="w-full border border-slate-300 rounded-md px-3 py-2 text-xs focus:ring-2 focus:ring-slate-400"
                    />
                  </div>
                  <div className="flex space-x-2">
                    <button
                      type="submit"
                      disabled={cancelMutation.isPending || !cancelReason.trim()}
                      className="flex-1 bg-red-600 hover:bg-red-700 disabled:opacity-50 text-white text-xs font-semibold py-2 px-4 rounded-md transition-colors"
                    >
                      {cancelMutation.isPending ? 'Cancelling…' : 'Confirm Cancel'}
                    </button>
                    <button
                      type="button"
                      onClick={() => {
                        setShowCancelForm(false);
                        setCancelReason('');
                        setCancelNote('');
                        setCancelInlineError(null);
                      }}
                      className="flex-1 border border-slate-300 text-slate-600 hover:bg-slate-50 text-xs font-semibold py-2 px-4 rounded-md transition-colors"
                    >
                      Back
                    </button>
                  </div>
                </form>
              )}
            </div>
          )}

          {/* Inform non-actionable states */}
          {!CANCELLABLE_STATUSES.includes(displayOrder.status) &&
            displayOrder.status !== OrderStatus.DEFERRED && (
              <p className="text-xs text-slate-400 italic">
                No actions available for orders in{' '}
                <span className="font-semibold">{displayOrder.status}</span> status.
              </p>
            )}
        </section>
      </div>
    </div>
  );
};
