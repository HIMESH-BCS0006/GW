import React, { useState } from 'react';
import { AlertTriangle, X, Loader2 } from 'lucide-react';
import { clsx } from 'clsx';
import { useCancelOrder } from '../api/hooks';
import { ApiError } from '../../../shared/api/client';

interface CancelOrderDialogProps {
  orderId: string;
  onClose: () => void;
  onCancelled: () => void;
}

/**
 * Cancel-order sheet (D22).
 *
 * POST /orders/{id}/cancel  body: { reason: string, note?: string }
 * Returns 409 INVALID_TRANSITION when the order state disallows cancel
 * (e.g. LOADED, IN_TRANSIT, DELIVERED). That error is shown as a friendly message.
 *
 * Reason is mandatory (D22).
 */
export const CancelOrderDialog: React.FC<CancelOrderDialogProps> = ({
  orderId,
  onClose,
  onCancelled,
}) => {
  const [reason, setReason] = useState('');
  const [note, setNote] = useState('');
  const [errorMsg, setErrorMsg] = useState('');

  const cancel = useCancelOrder();

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!reason.trim()) {
      setErrorMsg('A reason is required to cancel the order (D22).');
      return;
    }
    setErrorMsg('');

    try {
      await cancel.mutateAsync({ id: orderId, reason: reason.trim(), note: note.trim() || undefined });
      onCancelled();
    } catch (err) {
      if (err instanceof ApiError) {
        if (err.code === 'INVALID_TRANSITION') {
          setErrorMsg(
            `This order cannot be cancelled in its current state: ${err.message}`
          );
        } else {
          setErrorMsg(err.message || 'An unexpected error occurred.');
        }
      } else {
        setErrorMsg('Network error – please try again.');
      }
    }
  }

  const isSubmitting = cancel.isPending;

  return (
    /* Backdrop */
    <div
      className="fixed inset-0 z-50 flex items-end justify-center bg-black/40 sm:items-center"
      role="dialog"
      aria-modal="true"
      aria-label="Cancel order"
      data-testid="cancel-dialog"
    >
      <div className="w-full max-w-lg rounded-t-2xl bg-white p-6 shadow-xl sm:rounded-2xl">
        {/* Header */}
        <div className="flex items-start justify-between">
          <div className="flex items-center gap-2">
            <AlertTriangle className="h-5 w-5 text-rose-500" />
            <h2 className="text-lg font-bold text-slate-900">Cancel Order</h2>
          </div>
          <button
            onClick={onClose}
            className="rounded-full p-1 text-slate-500 hover:bg-slate-100"
            aria-label="Close"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <p className="mt-1 text-sm text-slate-500">
          This action cannot be undone. Order{' '}
          <span className="font-mono font-bold">{orderId}</span> will be cancelled.
          Cancellation is only allowed before the order is loaded.
        </p>

        {/* Error (including 409 INVALID_TRANSITION) */}
        {errorMsg && (
          <div
            data-testid="cancel-error"
            className="mt-3 rounded-lg border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-800"
          >
            {errorMsg}
          </div>
        )}

        <form onSubmit={handleSubmit} className="mt-4 space-y-4">
          {/* Mandatory reason (D22) */}
          <div>
            <label
              htmlFor="cancel_reason"
              className="block text-sm font-semibold text-slate-800"
            >
              Reason <span className="text-red-500">*</span>
            </label>
            <textarea
              id="cancel_reason"
              data-testid="cancel-reason-input"
              value={reason}
              onChange={(e) => { setReason(e.target.value); setErrorMsg(''); }}
              rows={3}
              placeholder="Why is this order being cancelled?"
              className={clsx(
                'mt-1.5 block w-full rounded-lg border px-3 py-2 text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-rose-500',
                !reason.trim() && errorMsg
                  ? 'border-red-400 bg-red-50'
                  : 'border-slate-300'
              )}
            />
          </div>

          {/* Optional note */}
          <div>
            <label
              htmlFor="cancel_note"
              className="block text-sm font-semibold text-slate-800"
            >
              Additional note{' '}
              <span className="font-normal text-slate-400">(optional)</span>
            </label>
            <textarea
              id="cancel_note"
              data-testid="cancel-note-input"
              value={note}
              onChange={(e) => setNote(e.target.value)}
              rows={2}
              placeholder="Any further context…"
              className="mt-1.5 block w-full rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-rose-500"
            />
          </div>

          <div className="flex gap-3 pt-2">
            <button
              type="button"
              onClick={onClose}
              disabled={isSubmitting}
              className="flex-1 rounded-lg border border-slate-300 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 hover:bg-slate-50 focus:outline-none focus:ring-2 focus:ring-slate-400"
            >
              Keep Order
            </button>
            <button
              type="submit"
              data-testid="confirm-cancel-button"
              disabled={isSubmitting}
              className="flex flex-1 items-center justify-center gap-2 rounded-lg bg-rose-600 px-4 py-2.5 text-sm font-bold text-white hover:bg-rose-700 focus:outline-none focus:ring-2 focus:ring-rose-500 disabled:opacity-50"
            >
              {isSubmitting ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Cancelling…
                </>
              ) : (
                'Cancel Order'
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
