import React from 'react';
import { Deferral } from '../api/generated/models';
import { formatColomboDateTime } from '../lib/time';

interface DeferralHistoryProps {
  deferrals: Deferral[];
}

const REASON_CLASS_COLORS: Record<string, string> = {
  UNAVOIDABLE: 'bg-gray-100 text-gray-800 border-gray-200',
  CHOICE: 'bg-blue-100 text-blue-800 border-blue-200',
  OPERATIONAL: 'bg-amber-100 text-amber-800 border-amber-200',
  DISPATCHER: 'bg-purple-100 text-purple-800 border-purple-200',
};

export const DeferralHistory: React.FC<DeferralHistoryProps> = ({ deferrals }) => {
  if (!deferrals || deferrals.length === 0) {
    return (
      <p className="text-xs text-slate-400 italic py-2">No deferral history for this order.</p>
    );
  }

  return (
    <div className="space-y-2">
      {deferrals.map((d) => {
        const classColor =
          REASON_CLASS_COLORS[d.reason_class] ?? 'bg-gray-100 text-gray-800 border-gray-200';
        return (
          <div key={d.id} className="bg-slate-50 border border-slate-200 rounded-md p-3 text-xs">
            <div className="flex items-center justify-between mb-1.5">
              <span className="font-mono font-bold text-slate-700">
                Skipped: {d.from_delivery_date}
              </span>
              <span
                className={`px-2 py-0.5 rounded-full text-[10px] font-semibold border ${classColor}`}
              >
                {d.reason_class}
              </span>
            </div>
            <p className="text-slate-700 mb-1">
              <span className="font-semibold">Reason ({d.reason_code}):</span> {d.reason_text}
            </p>
            {d.consequence_text && (
              <p className="text-amber-700 bg-amber-50 rounded px-2 py-1 mt-1">
                Impact: {d.consequence_text}
              </p>
            )}
            {d.resolved_to_date && (
              <p className="text-slate-500 mt-1">
                → Carried to: <strong>{d.resolved_to_date}</strong>
              </p>
            )}
            <p className="text-slate-400 mt-1">
              Decided by {d.decided_by}
              {d.decided_by_user ? ` (${d.decided_by_user})` : ''} at{' '}
              {formatColomboDateTime(d.decided_at)}
            </p>
          </div>
        );
      })}
    </div>
  );
};
