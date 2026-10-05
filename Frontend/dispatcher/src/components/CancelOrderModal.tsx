import React, { useState, useEffect } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { useCancelOrder } from '../api/generated/store-manager/store-manager';
import type { Order, Outlet } from '../api/generated/models';
import { ApiError } from '../api/http';

interface CancelOrderModalProps {
  isOpen: boolean;
  onClose: () => void;
  order: Order | null;
  outlet?: Outlet;
  onSuccess?: (orderId: string) => void;
}

const CANCELLATION_REASONS = [
  'Customer Request',
  'Store Maintenance',
  'Duplicate Order',
  'Stock Unavailability',
  'Incorrect Order Specs',
  'Weather / Access Issue',
  'Other',
];

export const CancelOrderModal: React.FC<CancelOrderModalProps> = ({
  isOpen,
  onClose,
  order,
  outlet,
  onSuccess,
}) => {
  const queryClient = useQueryClient();

  const [reason, setReason] = useState<string>('Customer Request');
  const [customReason, setCustomReason] = useState<string>('');
  const [note, setNote] = useState<string>('');
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (isOpen) {
      setReason('Customer Request');
      setCustomReason('');
      setNote('');
      setError(null);
    }
  }, [isOpen, order]);

  const cancelMutation = useCancelOrder({
    mutation: {
      onSuccess: () => {
        // Invalidate queue and dashboard queries
        queryClient.invalidateQueries({ queryKey: ['dispatchQueue'] });
        queryClient.invalidateQueries({ queryKey: ['/dispatch/queue'] });
        queryClient.invalidateQueries({ queryKey: ['dashboard'] });
        queryClient.invalidateQueries({ queryKey: ['/dashboard'] });
        queryClient.invalidateQueries({ queryKey: ['plans'] });
        queryClient.invalidateQueries({ queryKey: ['planTrips'] });
        queryClient.invalidateQueries({ queryKey: ['planningTrips'] });
        queryClient.invalidateQueries({ queryKey: ['unplannedOrders'] });
        if (order?.id) {
          queryClient.invalidateQueries({ queryKey: [`/orders/${order.id}`] });
          queryClient.invalidateQueries({ queryKey: ['orders', order.id] });
        }

        if (order && onSuccess) {
          onSuccess(order.id);
        }
        onClose();
      },
      onError: (err: any) => {
        const msg =
          err?.response?.data?.message ||
          err?.message ||
          'Failed to cancel order. Please check order status.';
        setError(msg);
      },
    },
  });

  if (!isOpen || !order) return null;

  const effectiveReason = reason === 'Other' ? customReason.trim() : reason;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!effectiveReason) {
      setError('Please provide a cancellation reason.');
      return;
    }

    setError(null);
    cancelMutation.mutate({
      id: order.id,
      data: {
        reason: effectiveReason,
        note: note.trim() || undefined,
      },
    });
  };

  const getStatusBadgeText = (status?: string) => {
    if (!status) return 'Pending Dispatch';
    switch (status) {
      case 'SUBMITTED':
        return 'Pending Dispatch';
      case 'PLANNED':
        return 'Planned';
      case 'SCHEDULED':
        return 'Scheduled';
      default:
        return status;
    }
  };

  const outletDisplayName = outlet
    ? `${outlet.outlet_id} – ${outlet.brand} (${outlet.district})`
    : `Outlet ${order.outlet_id}`;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="relative w-full max-w-lg bg-white rounded-2xl shadow-2xl border border-slate-200 overflow-hidden">
        {/* Header */}
        <div className="flex items-start justify-between px-6 pt-6 pb-4 border-b border-slate-100">
          <div className="flex items-start space-x-3.5">
            <div className="flex items-center justify-center w-10 h-10 rounded-xl bg-amber-50 border border-amber-200/80 text-amber-600 shadow-sm shrink-0">
              <svg
                className="w-5 h-5"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" />
                <line x1="12" y1="9" x2="12" y2="13" />
                <line x1="12" y1="17" x2="12.01" y2="17" />
              </svg>
            </div>
            <div>
              <h2 className="text-base font-bold text-slate-900 tracking-tight">Cancel Order</h2>
              <p className="text-xs text-slate-500 mt-0.5">
                Confirm order withdrawal and record reason
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            disabled={cancelMutation.isPending}
            className="text-slate-400 hover:text-slate-600 p-1 rounded-lg hover:bg-slate-100 transition-colors"
            aria-label="Close"
          >
            <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <line x1="18" y1="6" x2="6" y2="18" />
              <line x1="6" y1="6" x2="18" y2="18" />
            </svg>
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-5">
          {/* Target Order Card */}
          <div className="bg-slate-50/90 border border-slate-200/90 rounded-xl p-4 space-y-1.5">
            <div className="flex items-center justify-between">
              <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400">
                TARGET ORDER
              </span>
              <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-amber-100/80 text-amber-800 border border-amber-200">
                {getStatusBadgeText(order.status)}
              </span>
            </div>
            <div className="text-base font-bold text-slate-900 font-mono tracking-tight">
              {order.id}
            </div>
            <div className="text-xs font-medium text-slate-600">{outletDisplayName}</div>
            <div className="text-[11px] text-slate-500 pt-1 flex items-center gap-3">
              <span>{order.order_units} units</span>
              <span>•</span>
              <span>{order.order_weight_kg} kg</span>
              <span>•</span>
              <span>{order.temp_requirement}</span>
              <span>•</span>
              <span>Delivery: {order.delivery_date}</span>
            </div>
          </div>

          {/* Cancellation Reason */}
          <div className="space-y-1.5">
            <div className="flex items-center justify-between">
              <label htmlFor="cancel-reason" className="text-xs font-bold text-slate-700">
                Cancellation Reason <span className="text-amber-600">*</span>
              </label>
              <span className="text-[10px] font-semibold text-slate-400 uppercase tracking-wider">
                Required
              </span>
            </div>
            <select
              id="cancel-reason"
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              className="w-full bg-white border border-slate-300 rounded-lg px-3 py-2 text-xs font-medium text-slate-800 shadow-sm focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-amber-500"
            >
              {CANCELLATION_REASONS.map((r) => (
                <option key={r} value={r}>
                  {r}
                </option>
              ))}
            </select>

            {reason === 'Other' && (
              <input
                type="text"
                value={customReason}
                onChange={(e) => setCustomReason(e.target.value)}
                placeholder="Specify reason for cancellation..."
                className="w-full mt-2 bg-white border border-slate-300 rounded-lg px-3 py-2 text-xs text-slate-800 shadow-sm focus:outline-none focus:ring-2 focus:ring-amber-500"
                required
              />
            )}
          </div>

          {/* Cancellation Note */}
          <div className="space-y-1.5">
            <div className="flex items-center justify-between">
              <label htmlFor="cancel-note" className="text-xs font-bold text-slate-700">
                Cancellation Note
              </label>
              <span className="text-[10px] font-semibold text-slate-400 uppercase tracking-wider">
                Internal log entry
              </span>
            </div>
            <textarea
              id="cancel-note"
              rows={3}
              value={note}
              onChange={(e) => setNote(e.target.value)}
              placeholder="Store manager requested withdrawal due to temporary cold storage maintenance at KCC branch."
              className="w-full bg-white border border-slate-300 rounded-lg p-3 text-xs text-slate-800 shadow-sm focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-amber-500 resize-none"
            />
          </div>

          {/* Information banner */}
          <div className="flex items-start space-x-2.5 p-3 rounded-lg bg-amber-50/60 border border-amber-200/60 text-amber-900 text-xs">
            <svg
              className="w-4 h-4 text-amber-600 shrink-0 mt-0.5"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
            >
              <circle cx="12" cy="12" r="10" />
              <line x1="12" y1="16" x2="12" y2="12" />
              <line x1="12" y1="8" x2="12.01" y2="8" />
            </svg>
            <p className="text-xs text-slate-600 leading-relaxed">
              This action will notify the consignee and release any reserved vehicle bay space.
            </p>
          </div>

          {/* Error Message */}
          {error && (
            <div className="p-3 bg-red-50 border border-red-200 text-red-700 text-xs rounded-lg flex items-center gap-2">
              <svg className="w-4 h-4 text-red-500 shrink-0" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <circle cx="12" cy="12" r="10" />
                <line x1="15" y1="9" x2="9" y2="15" />
                <line x1="9" y1="9" x2="15" y2="15" />
              </svg>
              <span>{error}</span>
            </div>
          )}

          {/* Footer Actions */}
          <div className="flex items-center justify-end space-x-3 pt-2">
            <button
              type="button"
              onClick={onClose}
              disabled={cancelMutation.isPending}
              className="px-4 py-2 text-xs font-semibold text-slate-700 bg-white border border-slate-300 rounded-lg hover:bg-slate-50 transition-colors"
            >
              Dismiss
            </button>
            <button
              type="submit"
              disabled={cancelMutation.isPending || (reason === 'Other' && !customReason.trim())}
              className="inline-flex items-center space-x-1.5 px-4 py-2 text-xs font-bold text-white bg-gradient-to-r from-amber-600 to-amber-700 hover:from-amber-700 hover:to-amber-800 disabled:opacity-50 rounded-lg shadow-sm transition-all focus:ring-2 focus:ring-amber-500 focus:ring-offset-1"
            >
              {cancelMutation.isPending ? (
                <>
                  <svg className="w-3.5 h-3.5 animate-spin mr-1" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
                  </svg>
                  Cancelling...
                </>
              ) : (
                <>
                  <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <circle cx="12" cy="12" r="10" />
                    <line x1="4.93" y1="4.93" x2="19.07" y2="19.07" />
                  </svg>
                  <span>Confirm Cancellation</span>
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
