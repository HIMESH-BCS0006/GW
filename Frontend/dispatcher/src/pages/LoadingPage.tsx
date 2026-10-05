import React, { useState } from 'react';
import { PageHeader } from '../components/PageHeader';
import { LoadingState } from '../components/LoadingState';
import { EmptyState } from '../components/EmptyState';
import { useGetLoading } from '../api/pending/loading';
import {
  useListLoadChecks,
  useResolveLoadCheck,
} from '../api/generated/dispatcher/dispatcher';
import { useAuth } from '../context/AuthContext';

export const LoadingPage: React.FC = () => {
  const { selectedDepot } = useAuth();
  const { data: summary, isLoading: loadingSummary } = useGetLoading(
    selectedDepot ? { depot_id: selectedDepot } : undefined
  );
  const {
    data: loadChecks,
    isLoading: loadingChecks,
    isError,
    refetch,
  } = useListLoadChecks(selectedDepot ? { depot_id: selectedDepot } : undefined);

  const resolveMutation = useResolveLoadCheck();
  const [activeMessage, setActiveMessage] = useState<string | null>(null);
  const [noteInput, setNoteInput] = useState<{ [id: string]: string }>({});

  const handleResolve = async (
    loadCheckId: string,
    resolution: string
  ) => {
    try {
      const userNote = noteInput[loadCheckId]?.trim();
      await resolveMutation.mutateAsync({
        loadCheckId,
        resolution,
        notes: userNote || `Resolved by dispatcher from loading console`,
      });
      setActiveMessage(
        resolution === 'cancel_order' || resolution === 'reject_load'
          ? `Load check #${loadCheckId} resolved: Order cancelled and store manager notified.`
          : `Load check #${loadCheckId} resolved with ${resolution}.`
      );
      setNoteInput((prev) => ({ ...prev, [loadCheckId]: '' }));
      refetch();
    } catch (err: any) {
      setActiveMessage(`Failed to resolve load check: ${err.message || 'Unknown error'}`);
    }
  };

  if (loadingSummary || loadingChecks) return <LoadingState />;
  if (isError)
    return (
      <EmptyState
        title="Error loading data"
        description="Could not load loading bay checks."
      />
    );

  return (
    <div className="space-y-6">
      <PageHeader
        title="Loading Bay Coordination"
        description={`Warehouse loading bay status, stock shortfalls, and physical verification checks (${selectedDepot})`}
      />

      {activeMessage && (
        <div className="p-3 bg-brand-50 border border-brand-200 text-brand-900 rounded-lg text-sm flex justify-between items-center">
          <span>{activeMessage}</span>
          <button
            onClick={() => setActiveMessage(null)}
            className="text-brand-600 font-bold ml-2 hover:text-brand-800"
          >
            ×
          </button>
        </div>
      )}

      {/* Summary Metrics */}
      <div className="grid gap-4 sm:grid-cols-3">
        <div className="p-5 bg-white border border-slate-200 rounded-xl shadow-sm">
          <h4 className="text-xs uppercase tracking-wider text-slate-500 font-semibold">
            Active Stock Shortfalls
          </h4>
          <p className="text-3xl font-extrabold text-amber-600 mt-1">
            {summary?.shortfall ?? 0}
          </p>
          <p className="text-xs text-slate-500 mt-0.5">Physical count variances requiring sign-off</p>
        </div>
        <div className="p-5 bg-white border border-slate-200 rounded-xl shadow-sm">
          <h4 className="text-xs uppercase tracking-wider text-slate-500 font-semibold">
            Pending Orders in Bay
          </h4>
          <p className="text-3xl font-extrabold text-slate-900 mt-1">
            {summary?.pendingOrders ?? 0}
          </p>
          <p className="text-xs text-slate-500 mt-0.5">Awaiting physical loading into trucks</p>
        </div>
        <div className="p-5 bg-white border border-slate-200 rounded-xl shadow-sm">
          <h4 className="text-xs uppercase tracking-wider text-slate-500 font-semibold">
            Vehicles Being Loaded
          </h4>
          <p className="text-3xl font-extrabold text-brand-600 mt-1">
            {summary?.vehiclesLoading ?? 0}
          </p>
          <p className="text-xs text-slate-500 mt-0.5">Trucks currently docked at warehouse bays</p>
        </div>
      </div>

      {/* Load Checks List */}
      <section className="bg-white border border-slate-200 rounded-xl p-5 shadow-sm space-y-4">
        <div className="flex items-center justify-between">
          <h3 className="text-base font-bold text-slate-900">
            Warehouse Load Checks & Discrepancies ({(loadChecks ?? []).length})
          </h3>
        </div>

        {(loadChecks ?? []).length === 0 ? (
          <p className="text-xs text-slate-400 py-4 text-center bg-slate-50 rounded-lg">
            No discrepancy load checks reported for {selectedDepot}. All loading manifests match inventory.
          </p>
        ) : (
          <div className="divide-y divide-slate-100">
            {(loadChecks ?? []).map((lc) => (
              <div
                key={lc.id}
                className="py-4 flex flex-col md:flex-row md:items-start justify-between gap-4"
              >
                <div className="space-y-1 max-w-md">
                  <div className="flex items-center space-x-2">
                    <span className="font-bold text-slate-800 text-sm">{`Check #${lc.id}`}</span>
                    <span className="text-xs bg-slate-100 text-slate-700 px-2 py-0.5 rounded font-medium">
                      Trip {lc.trip_id}
                    </span>
                    <span className="text-xs bg-blue-50 text-blue-700 px-2 py-0.5 rounded font-medium">
                      Order {lc.order_id}
                    </span>
                    <span
                      className={`text-[10px] uppercase font-bold px-2 py-0.5 rounded ${
                        lc.status === 'resolved'
                          ? 'bg-emerald-100 text-emerald-800'
                          : 'bg-red-100 text-red-800'
                      }`}
                    >
                      {lc.status}
                    </span>
                  </div>
                  <p className="text-xs text-slate-600">
                    Issue: <span className="font-semibold text-slate-800">{lc.issue}</span> (Expected {lc.expected_qty} vs Loaded {lc.loaded_qty}) • Loader:{' '}
                    <span className="font-semibold text-slate-800">{lc.reported_by || 'Loader'}</span>
                  </p>
                  {lc.note && (
                    <p className="text-xs text-slate-500 italic">Loader Note: {lc.note}</p>
                  )}
                  {lc.status !== 'resolved' && (
                    <input
                      type="text"
                      placeholder="Add note for Store Manager / cancellation reason..."
                      value={noteInput[lc.id] || ''}
                      onChange={(e) =>
                        setNoteInput((prev) => ({ ...prev, [lc.id]: e.target.value }))
                      }
                      className="w-full mt-2 border border-slate-300 rounded px-2.5 py-1 text-xs focus:ring-1 focus:ring-brand-500"
                    />
                  )}
                </div>

                {lc.status !== 'resolved' && (
                  <div className="flex flex-wrap gap-2 items-center">
                    <button
                      className="bg-red-600 hover:bg-red-700 text-white text-xs font-semibold px-3 py-1.5 rounded-lg shadow transition-colors"
                      onClick={() => handleResolve(lc.id, 'cancel_order')}
                    >
                      Cancel & Notify Store Manager
                    </button>
                    <button
                      className="bg-amber-600 hover:bg-amber-700 text-white text-xs font-semibold px-3 py-1.5 rounded-lg shadow transition-colors"
                      onClick={() => handleResolve(lc.id, 'defer_order')}
                    >
                      Defer Order
                    </button>
                    <button
                      className="bg-brand-600 hover:bg-brand-700 text-white text-xs font-semibold px-3 py-1.5 rounded-lg shadow transition-colors"
                      onClick={() => handleResolve(lc.id, 'accept_shortfall')}
                    >
                      Accept Shortfall
                    </button>
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </section>
    </div>
  );
};
