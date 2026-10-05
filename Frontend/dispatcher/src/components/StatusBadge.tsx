import React from 'react';

interface StatusBadgeProps {
  status: string;
  type?: 'order' | 'trip' | 'stop' | 'general';
}

export const StatusBadge: React.FC<StatusBadgeProps> = ({ status, type = 'general' }) => {
  const upper = (status || '').toUpperCase();

  let style = 'bg-gray-100 text-gray-800 border-gray-200';

  if (['CONFIRMED', 'DELIVERED', 'LOADED', 'COMPLETED'].includes(upper)) {
    style = 'bg-mint-100 text-mint-900 border-mint-200';
  } else if (['IN_PROGRESS', 'IN_TRANSIT', 'SCHEDULED', 'PLANNED', 'ARRIVED'].includes(upper)) {
    style = 'bg-blue-100 text-blue-800 border-blue-200';
  } else if (['SUBMITTED', 'PENDING'].includes(upper)) {
    style = 'bg-amber-100 text-amber-800 border-amber-200';
  } else if (['DEFERRED', 'CANCELLED', 'BLOCKED', 'SKIPPED', 'REFUSED', 'EXCEPTION'].includes(upper)) {
    style = 'bg-red-100 text-red-800 border-red-200';
  }

  return (
    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold border ${style}`}>
      {status}
    </span>
  );
};
