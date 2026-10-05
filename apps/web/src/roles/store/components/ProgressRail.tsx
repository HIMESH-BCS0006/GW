import React from 'react';
import {
  CheckCircle2,
  Circle,
  Clock,
  PackageCheck,
  Truck,
  XCircle,
  CalendarX,
  RotateCcw,
  AlertCircle,
} from 'lucide-react';
import { clsx } from 'clsx';
import type { Order } from '../types';

/**
 * Progress Rail for SM4 Tracking.
 *
 * State machine from spec/01-decisions-domain-state.md §4:
 *   SUBMITTED → PLANNED → SCHEDULED → LOADED → IN_TRANSIT → DELIVERED | PARTIALLY_DELIVERED
 *   SUBMITTED | PLANNED | SCHEDULED → DEFERRED
 *   SUBMITTED | PLANNED | SCHEDULED → CANCELLED
 *   DEFERRED → SUBMITTED (carried to next run; deferral_count retained)
 *
 * D19: PLANNED = in a draft trip; SCHEDULED = trip confirmed.
 * The SM rail collapses both into one "Scheduled" visual step per spec/04 §2.4.
 *
 * Terminal states DEFERRED and CANCELLED render as a separate banner rather
 * than in the linear rail.
 */

type OrderStatus =
  | 'SUBMITTED'
  | 'PLANNED'
  | 'SCHEDULED'
  | 'LOADED'
  | 'IN_TRANSIT'
  | 'DELIVERED'
  | 'PARTIALLY_DELIVERED'
  | 'DEFERRED'
  | 'CANCELLED';

interface RailStep {
  key: string;
  label: string;
  Icon: React.ElementType;
  /** Order statuses that count as this step being COMPLETE */
  completedOn: OrderStatus[];
  /** Order statuses that count as this step being ACTIVE (current) */
  activeOn: OrderStatus[];
}

const RAIL_STEPS: RailStep[] = [
  {
    key: 'received',
    label: 'Received',
    Icon: Circle,
    activeOn: ['SUBMITTED'],
    completedOn: ['PLANNED', 'SCHEDULED', 'LOADED', 'IN_TRANSIT', 'DELIVERED', 'PARTIALLY_DELIVERED'],
  },
  {
    key: 'scheduled',
    label: 'Scheduled',
    Icon: Clock,
    activeOn: ['PLANNED', 'SCHEDULED'],        // D19: collapse PLANNED + SCHEDULED
    completedOn: ['LOADED', 'IN_TRANSIT', 'DELIVERED', 'PARTIALLY_DELIVERED'],
  },
  {
    key: 'loaded',
    label: 'Loaded',
    Icon: PackageCheck,
    activeOn: ['LOADED'],
    completedOn: ['IN_TRANSIT', 'DELIVERED', 'PARTIALLY_DELIVERED'],
  },
  {
    key: 'on_the_way',
    label: 'On the way',
    Icon: Truck,
    activeOn: ['IN_TRANSIT'],
    completedOn: ['DELIVERED', 'PARTIALLY_DELIVERED'],
  },
  {
    key: 'delivered',
    label: 'Delivered',
    Icon: CheckCircle2,
    activeOn: ['DELIVERED', 'PARTIALLY_DELIVERED'],
    completedOn: [],
  },
];

type StepState = 'completed' | 'active' | 'future';

function getStepState(step: RailStep, status: OrderStatus): StepState {
  if (step.completedOn.includes(status)) return 'completed';
  if (step.activeOn.includes(status)) return 'active';
  return 'future';
}

interface ProgressRailProps {
  order: Order;
}

export const ProgressRail: React.FC<ProgressRailProps> = ({ order }) => {
  const status = order.status as OrderStatus;
  const isTerminal = status === 'DEFERRED' || status === 'CANCELLED';
  const isPartial = status === 'PARTIALLY_DELIVERED';

  return (
    <div data-testid="progress-rail" className="space-y-4">
      {/* Terminal state banners */}
      {status === 'DEFERRED' && (
        <div
          data-testid="deferred-banner"
          className="flex items-start gap-3 rounded-xl border border-orange-300 bg-orange-50 px-4 py-3"
        >
          <RotateCcw className="mt-0.5 h-5 w-5 shrink-0 text-orange-600" />
          <div>
            <p className="font-bold text-orange-900">Order Deferred</p>
            <p className="mt-0.5 text-sm text-orange-800">
              This order was not delivered and has been carried to the next operating run.
              {order.deferral_count > 1 && (
                <span className="ml-1 font-semibold">
                  (Deferred {order.deferral_count} time{order.deferral_count !== 1 ? 's' : ''})
                </span>
              )}
            </p>
            {order.cancel_reason && (
              <p className="mt-1 text-xs text-orange-700">
                <span className="font-semibold">Reason: </span>{order.cancel_reason}
              </p>
            )}
          </div>
        </div>
      )}

      {status === 'CANCELLED' && (
        <div
          data-testid="cancelled-banner"
          className="flex items-start gap-3 rounded-xl border border-rose-300 bg-rose-50 px-4 py-3"
        >
          <XCircle className="mt-0.5 h-5 w-5 shrink-0 text-rose-600" />
          <div>
            <p className="font-bold text-rose-900">Order Cancelled</p>
            {order.cancel_reason && (
              <p className="mt-0.5 text-sm text-rose-800">
                <span className="font-semibold">Reason: </span>{order.cancel_reason}
              </p>
            )}
          </div>
        </div>
      )}

      {isPartial && (
        <div
          data-testid="partial-banner"
          className="flex items-start gap-2 rounded-lg border border-amber-300 bg-amber-50 px-4 py-2.5"
        >
          <AlertCircle className="mt-0.5 h-4 w-4 shrink-0 text-amber-600" />
          <p className="text-sm text-amber-800">
            <span className="font-semibold">Partially delivered.</span> A discrepancy was recorded. Check with your dispatcher.
          </p>
        </div>
      )}

      {/* Linear progress rail (hidden for terminal states that never progressed) */}
      {!isTerminal && (
        <ol
          className="relative flex items-start gap-0"
          aria-label="Order progress"
        >
          {RAIL_STEPS.map((step, idx) => {
            const stepState = getStepState(step, status);
            const isLast = idx === RAIL_STEPS.length - 1;
            const StepIcon = step.Icon;

            return (
              <li
                key={step.key}
                data-testid={`rail-step-${step.key}`}
                data-state={stepState}
                className="flex flex-1 flex-col items-center"
              >
                {/* Icon + connector line */}
                <div className="relative flex w-full items-center">
                  {/* Left connector */}
                  {idx > 0 && (
                    <div
                      className={clsx(
                        'h-0.5 flex-1',
                        stepState === 'future' ? 'bg-slate-200' : 'bg-brand-500'
                      )}
                    />
                  )}

                  {/* Step icon bubble */}
                  <div
                    className={clsx(
                      'flex h-9 w-9 shrink-0 items-center justify-center rounded-full border-2 transition-colors',
                      stepState === 'completed'
                        ? 'border-brand-500 bg-brand-500 text-white'
                        : stepState === 'active'
                          ? 'border-brand-500 bg-white text-brand-600 ring-4 ring-brand-100'
                          : 'border-slate-300 bg-white text-slate-400'
                    )}
                  >
                    {stepState === 'completed' ? (
                      <CheckCircle2 className="h-5 w-5" />
                    ) : (
                      <StepIcon className="h-4 w-4" />
                    )}
                  </div>

                  {/* Right connector */}
                  {!isLast && (
                    <div
                      className={clsx(
                        'h-0.5 flex-1',
                        getStepState(RAIL_STEPS[idx + 1], status) === 'future'
                          ? 'bg-slate-200'
                          : 'bg-brand-500'
                      )}
                    />
                  )}
                </div>

                {/* Label */}
                <p
                  className={clsx(
                    'mt-1.5 text-center text-xs font-medium leading-tight',
                    stepState === 'completed' ? 'text-brand-700' :
                    stepState === 'active'    ? 'text-brand-900 font-bold' :
                                               'text-slate-400'
                  )}
                >
                  {step.label}
                  {step.key === 'delivered' && isPartial ? ' (partial)' : ''}
                </p>
              </li>
            );
          })}
        </ol>
      )}
    </div>
  );
};
