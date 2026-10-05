import React, { useState } from 'react';
import { PageHeader } from '../components/PageHeader';
import { LoadingState } from '../components/LoadingState';
import { EmptyState } from '../components/EmptyState';
import {
  useGetLiveMonitoring,
  useResolveExceptionDecision,
} from '../api/generated/dispatcher/dispatcher';
import { useAuth } from '../context/AuthContext';

export const MonitoringPage: React.FC = () => {
  const { selectedDepot } = useAuth();
  const { data, isLoading, isError, refetch } = useGetLiveMonitoring(
    selectedDepot ? { depot_id: selectedDepot } : undefined
  );

  const resolveExceptionMutation = useResolveExceptionDecision();
  const [selectedException, setSelectedException] = useState<{
    id: string;
    stopNumber: number;
    reason: string;
  } | null>(null);
  const [decisionNotes, setDecisionNotes] = useState('');
  const [actionMessage, setActionMessage] = useState<string | null>(null);

  const handleDecision = async (decision: 'retry' | 'skip' | 'cancel') => {
    if (!selectedException) return;
    try {
      await resolveExceptionMutation.mutateAsync({
        exceptionId: selectedException.id,
        decision,
        notes: decisionNotes,
      });
      setActionMessage(`Exception marked as ${decision.toUpperCase()}.`);
      setSelectedException(null);
      setDecisionNotes('');
      refetch();
    } catch (err: any) {
      setActionMessage(`Failed to record decision: ${err.message || 'Unknown error'}`);
    }
  };

  if (isLoading) return <LoadingState />;
  if (isError)
    return (
      <EmptyState
        title="Error loading live monitoring"
        description="Could not connect to live monitoring feed."
      />
    );

  const trips = data?.trips ?? [];

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <PageHeader
          title="Live Delivery Monitoring"
          description={`Real-time vehicle telemetry, stop progression, and active exceptions (${selectedDepot})`}
        />
        <div className="flex items-center space-x-2 text-xs text-slate-500 bg-white border border-slate-200 px-3 py-1.5 rounded-lg shadow-sm">
          <span className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
          <span>Live feed active • Auto-refreshes every 10s</span>
        </div>
      </div>

      {actionMessage && (
        <div className="p-3 bg-brand-50 border border-brand-200 text-brand-900 rounded-lg text-sm flex justify-between items-center">
          <span>{actionMessage}</span>
          <button
            onClick={() => setActionMessage(null)}
            className="text-brand-600 font-bold ml-2 hover:text-brand-800"
          >
            ×
          </button>
        </div>
      )}

      {/* Overview Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="p-4 bg-white border border-slate-200 rounded-xl shadow-sm">
          <h4 className="text-xs uppercase tracking-wider text-slate-500 font-semibold">
            Active Vehicles
          </h4>
          <p className="text-2xl font-extrabold text-slate-900 mt-1">{trips.length}</p>
          <p className="text-xs text-slate-500 mt-0.5">En-route across delivery sectors</p>
        </div>
        <div className="p-4 bg-white border border-slate-200 rounded-xl shadow-sm">
          <h4 className="text-xs uppercase tracking-wider text-slate-500 font-semibold">
            On-Schedule Rate
          </h4>
          <p className="text-2xl font-extrabold text-emerald-600 mt-1">
            {trips.length > 0
              ? `${Math.round(
                  (trips.filter((t) => t.health === 'on_schedule').length / trips.length) * 100
                )}%`
              : '100%'}
          </p>
          <p className="text-xs text-slate-500 mt-0.5">
            {trips.filter((t) => t.health === 'delayed').length} vehicles experiencing delay
          </p>
        </div>
        <div className="p-4 bg-white border border-slate-200 rounded-xl shadow-sm">
          <h4 className="text-xs uppercase tracking-wider text-slate-500 font-semibold">
            Last Synced Timestamp
          </h4>
          <p className="text-sm font-semibold text-slate-800 mt-2 font-mono">
            {data?.last_synced_at ? new Date(data.last_synced_at).toLocaleTimeString() : 'Just now'}
          </p>
          <p className="text-xs text-slate-400 mt-0.5">Synchronized with central telemetry</p>
        </div>
      </div>

      {/* Trips list */}
      {trips.length === 0 ? (
        <div className="bg-white border border-slate-200 rounded-xl p-8 text-center shadow-sm">
          <h3 className="text-base font-semibold text-slate-800">No Active Trips En-Route</h3>
          <p className="text-xs text-slate-500 mt-1 max-w-md mx-auto">
            Once loaders confirm vehicle loading and drivers start their routes, live vehicle
            progress and GPS ETA updates will appear here automatically.
          </p>
        </div>
      ) : (
        <div className="grid gap-6 lg:grid-cols-2">
          {trips.map((trip) => {
            const progressPct = Math.round(
              (trip.stops_completed / Math.max(trip.stops_total, 1)) * 100
            );

            return (
              <div
                key={trip.vehicle_id}
                className="bg-white border border-slate-200 rounded-xl p-5 shadow-sm space-y-4"
              >
                <div className="flex items-center justify-between border-b border-slate-100 pb-3">
                  <div>
                    <div className="flex items-center space-x-2">
                      <span className="font-bold text-slate-900 text-base">{trip.vehicle_id}</span>
                      <span className="text-xs bg-slate-100 text-slate-700 px-2 py-0.5 rounded font-medium">
                        {trip.brand} • {trip.district}
                      </span>
                    </div>
                    <p className="text-xs text-slate-500 mt-0.5">
                      Driver: <span className="font-semibold text-slate-700">{trip.driver_name}</span>
                    </p>
                  </div>

                  <span
                    className={`text-xs px-2.5 py-1 rounded-full font-bold uppercase tracking-wider ${
                      trip.health === 'on_schedule'
                        ? 'bg-emerald-100 text-emerald-800'
                        : trip.health === 'delayed'
                        ? 'bg-amber-100 text-amber-800'
                        : 'bg-red-100 text-red-800'
                    }`}
                  >
                    {trip.health?.replace('_', ' ')}
                    {trip.delay_min ? ` (+${trip.delay_min}m)` : ''}
                  </span>
                </div>

                {/* Progress bar */}
                <div>
                  <div className="flex justify-between text-xs text-slate-600 mb-1">
                    <span>
                      Delivery Progress: {trip.stops_completed} / {trip.stops_total} stops completed
                    </span>
                    <span className="font-bold">{progressPct}%</span>
                  </div>
                  <div className="h-2 bg-slate-100 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-brand-500 rounded-full transition-all duration-500"
                      style={{ width: `${progressPct}%` }}
                    />
                  </div>
                </div>

                {/* Next Stop Info */}
                {trip.next_stop && (
                  <div className="p-3 bg-slate-50 border border-slate-200 rounded-lg flex items-center justify-between text-xs">
                    <div>
                      <span className="text-slate-500 block">Next Destination:</span>
                      <span className="font-bold text-slate-800">
                        {trip.next_stop.outlet_name || trip.next_stop.outlet_id}
                      </span>
                    </div>
                    <div className="text-right">
                      <span className="text-slate-500 block">Estimated Arrival:</span>
                      <span className="font-bold text-brand-700">{trip.next_stop.eta || 'N/A'}</span>
                    </div>
                  </div>
                )}

                {/* Stops Sequence */}
                <div className="space-y-1.5 pt-2">
                  <h5 className="text-[11px] font-bold uppercase tracking-wider text-slate-500">
                    Stop Manifest & Outcome
                  </h5>
                  <div className="space-y-1 max-h-40 overflow-y-auto pr-1">
                    {(trip.stops || []).map((stop) => (
                      <div
                        key={stop.stop_number}
                        className="flex items-center justify-between p-2 text-xs border border-slate-100 rounded-lg hover:bg-slate-50"
                      >
                        <div className="flex items-center space-x-2">
                          <span className="h-5 w-5 rounded-full bg-slate-200 text-slate-700 font-bold flex items-center justify-center text-[10px]">
                            {stop.stop_number}
                          </span>
                          <span className="font-medium text-slate-800">
                            {stop.outlet_name || stop.outlet_id}
                          </span>
                        </div>
                        <div className="flex items-center space-x-2">
                          <span className="text-[11px] text-slate-500">{stop.eta}</span>
                          <span
                            className={`text-[10px] px-2 py-0.5 rounded font-semibold ${
                              stop.status === 'completed'
                                ? 'bg-emerald-100 text-emerald-800'
                                : stop.status === 'failed'
                                ? 'bg-red-100 text-red-800'
                                : 'bg-slate-100 text-slate-600'
                            }`}
                          >
                            {stop.status || 'pending'}
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Exception Decision Modal */}
      {selectedException && (
        <div className="fixed inset-0 bg-slate-900/50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-xl max-w-md w-full p-6 space-y-4 shadow-xl">
            <h3 className="text-base font-bold text-slate-900">
              Resolve Delivery Exception #{selectedException.id}
            </h3>
            <p className="text-xs text-slate-600">
              Reason: <span className="font-semibold">{selectedException.reason}</span>
            </p>

            <textarea
              className="w-full border border-slate-300 rounded-lg p-2.5 text-xs focus:ring-2 focus:ring-brand-500"
              rows={3}
              placeholder="Enter dispatcher decision rationale..."
              value={decisionNotes}
              onChange={(e) => setDecisionNotes(e.target.value)}
            />

            <div className="grid grid-cols-3 gap-2 pt-2">
              <button
                className="bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold py-2 rounded-lg"
                onClick={() => handleDecision('retry')}
              >
                Retry
              </button>
              <button
                className="bg-amber-600 hover:bg-amber-700 text-white text-xs font-bold py-2 rounded-lg"
                onClick={() => handleDecision('skip')}
              >
                Skip Stop
              </button>
              <button
                className="bg-red-600 hover:bg-red-700 text-white text-xs font-bold py-2 rounded-lg"
                onClick={() => handleDecision('cancel')}
              >
                Cancel Order
              </button>
            </div>
            <button
              className="w-full text-xs text-slate-500 hover:text-slate-700 py-1"
              onClick={() => setSelectedException(null)}
            >
              Close
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
