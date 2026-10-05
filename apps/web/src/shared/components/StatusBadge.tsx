import React from 'react';
import { clsx } from 'clsx';

export type OrderState =
  | 'SUBMITTED'
  | 'PLANNED'
  | 'SCHEDULED'
  | 'LOADED'
  | 'IN_TRANSIT'
  | 'DELIVERED'
  | 'PARTIALLY_DELIVERED'
  | 'DEFERRED'
  | 'CANCELLED';

interface StatusBadgeProps {
  status: OrderState | string;
  className?: string;
}

const statusStyles: Record<string, { bg: string; text: string; label: string }> = {
  SUBMITTED: { bg: 'bg-blue-100 border-blue-200', text: 'text-blue-800', label: 'Received' },
  PLANNED: { bg: 'bg-sky-100 border-sky-200', text: 'text-sky-800', label: 'Scheduled' },
  SCHEDULED: { bg: 'bg-sky-100 border-sky-200', text: 'text-sky-800', label: 'Scheduled' },
  LOADED: { bg: 'bg-teal-100 border-teal-200', text: 'text-teal-800', label: 'Loaded' },
  IN_TRANSIT: { bg: 'bg-purple-100 border-purple-200', text: 'text-purple-800', label: 'On the way' },
  DELIVERED: { bg: 'bg-emerald-100 border-emerald-200', text: 'text-emerald-800', label: 'Delivered' },
  PARTIALLY_DELIVERED: { bg: 'bg-amber-100 border-amber-200', text: 'text-amber-800', label: 'Partially Delivered' },
  DEFERRED: { bg: 'bg-orange-100 border-orange-200', text: 'text-orange-800', label: 'Deferred' },
  CANCELLED: { bg: 'bg-rose-100 border-rose-200', text: 'text-rose-800', label: 'Cancelled' },
};

export const StatusBadge: React.FC<StatusBadgeProps> = ({ status, className }) => {
  const config = statusStyles[status] || {
    bg: 'bg-slate-100 border-slate-200',
    text: 'text-slate-800',
    label: status,
  };

  return (
    <span
      data-testid="status-badge"
      className={clsx(
        'inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold uppercase tracking-wider',
        config.bg,
        config.text,
        className
      )}
    >
      {config.label}
    </span>
  );
};
