import React from 'react';
import { Clock, AlertCircle } from 'lucide-react';
import { useBusinessClock } from '../../../shared/hooks/useBusinessClock';
import { clsx } from 'clsx';

/**
 * Displays a countdown to the 16:00 order cutoff using business_now() from
 * GET /ref/config (D11, D18). NEVER reads window.Date or the browser clock.
 */
export const CutoffCountdown: React.FC = () => {
  const { cutoffTime, formattedClockDate, isCutoffPassed, minutesUntilCutoff, isLoading } =
    useBusinessClock();

  if (isLoading) {
    return (
      <div className="h-12 animate-pulse rounded-lg bg-slate-100" />
    );
  }

  const hours = Math.floor(Math.abs(minutesUntilCutoff) / 60);
  const mins = Math.abs(minutesUntilCutoff) % 60;
  const timeLabel = hours > 0 ? `${hours}h ${mins}m` : `${mins}m`;

  return (
    <div
      data-testid="cutoff-countdown"
      className={clsx(
        'flex items-center justify-between rounded-lg border px-4 py-3 text-sm',
        isCutoffPassed
          ? 'border-amber-300 bg-amber-50 text-amber-800'
          : 'border-brand-200 bg-brand-50 text-brand-800'
      )}
    >
      <div className="flex items-center gap-2">
        {isCutoffPassed ? (
          <AlertCircle className="h-4 w-4 shrink-0 text-amber-600" />
        ) : (
          <Clock className="h-4 w-4 shrink-0 text-brand-600" />
        )}
        <div>
          <p className="font-semibold">
            {isCutoffPassed
              ? `Cutoff passed (${cutoffTime}) – order rolls to next operating day`
              : `Order cutoff in ${timeLabel}`}
          </p>
          <p className="text-xs opacity-75">
            Orders for {formattedClockDate} close at {cutoffTime} on D-1
          </p>
        </div>
      </div>

      {!isCutoffPassed && (
        <span
          className={clsx(
            'shrink-0 rounded-full px-3 py-1 text-xs font-bold tabular-nums',
            minutesUntilCutoff <= 30
              ? 'bg-amber-200 text-amber-900'
              : 'bg-brand-200 text-brand-900'
          )}
        >
          {timeLabel}
        </span>
      )}
    </div>
  );
};
