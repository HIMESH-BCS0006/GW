import React, { useState } from 'react';
import { PageHeader } from '../components/PageHeader';
import { EmptyState } from '../components/EmptyState';
import { LoadingState } from '../components/LoadingState';
import {
  useGetPlanningTrips,
  useGeneratePlan,
  useConfirmTrip,
  useCancelTrip,
  useRemoveOrderFromTrip,
} from '../api/generated/dispatcher/dispatcher';
import { useGetUnplannedOrders } from '../api/pending/unplannedOrders';
import { useOutletMap } from '../hooks/useOutletMap';
import { useAuth } from '../context/AuthContext';
import { EditTripOrdersDrawer } from '../components/EditTripOrdersDrawer';
import type { TripCard } from '../api/pending/planning';
import type { StopDetail } from '../api/generated/models/stopDetail';

export const PlanningPage: React.FC = () => {
  const { selectedDepot, deliveryDate } = useAuth();
  const { outletsById } = useOutletMap();

  // Core planning data
  const {
    data: trips,
    isLoading,
    isError,
    refetch,
  } = useGetPlanningTrips({
    depot_id: selectedDepot,
  });

  const {
    data: unplannedOrders,
    isLoading: unplannedLoading,
    refetch: refetchUnplanned,
  } = useGetUnplannedOrders({
    depot_id: selectedDepot,
  });

  const generatePlanMutation = useGeneratePlan();
  const confirmMutation = useConfirmTrip();
  const cancelMutation = useCancelTrip();
  const removeOrderMutation = useRemoveOrderFromTrip();

  // UI state
  const [selectedOrders, setSelectedOrders] = useState<string[]>([]);
  const [editingTrip, setEditingTrip] = useState<TripCard | null>(null);
  const [tripFilter, setTripFilter] = useState<'all' | 'draft' | 'confirmed'>('all');
  const [activeMessage, setActiveMessage] = useState<{
    type: 'info' | 'success' | 'error';
    text: string;
  } | null>(null);

  // Synchronize editingTrip with refreshed trips data
  const currentEditingTrip = trips?.find((t) => t.id === editingTrip?.id) || editingTrip;

  const handleGeneratePlan = async () => {
    try {
      setActiveMessage({
        type: 'info',
        text: 'Generating full plan via optimization engine...',
      });
      await generatePlanMutation.mutateAsync({
        depot_id: selectedDepot,
        delivery_date: deliveryDate,
        regenerate: true,
      });
      setActiveMessage({
        type: 'success',
        text: `Plan generated successfully for ${selectedDepot} (${deliveryDate})!`,
      });
      refetch();
      refetchUnplanned();
    } catch (err: any) {
      setActiveMessage({
        type: 'error',
        text: `Failed to generate plan: ${err.message || 'Unknown error'}`,
      });
    }
  };

  // Auto-allocate unassigned orders using optimization engine
  const handleAutoAllocate = async () => {
    try {
      const ordersToProcess =
        selectedOrders.length > 0
          ? (unplannedOrders || []).filter((o) => selectedOrders.includes(o.id))
          : unplannedOrders || [];
      const count = ordersToProcess.length;

      if (count === 0) return;

      setActiveMessage({
        type: 'info',
        text: `Running optimization engine to auto-allocate ${count} unassigned order(s)...`,
      });

      const uniqueDates = Array.from(
        new Set(ordersToProcess.map((o) => o.delivery_date).filter(Boolean))
      ) as string[];
      if (uniqueDates.length === 0) uniqueDates.push(deliveryDate);

      for (const d of uniqueDates) {
        await generatePlanMutation.mutateAsync({
          depot_id: selectedDepot,
          delivery_date: d,
          regenerate: true,
        });
      }

      setActiveMessage({
        type: 'success',
        text: `Auto-allocation complete! ${count} order(s) evaluated and allocated to compliant vehicle trips.`,
      });
      setSelectedOrders([]);
      refetch();
      refetchUnplanned();
    } catch (err: any) {
      console.error('Auto-allocate error:', err);
      const errMsg =
        err?.response?.data?.message ||
        err?.response?.data?.detail ||
        err?.message ||
        'Unknown error';
      setActiveMessage({
        type: 'error',
        text: `Failed to auto-allocate: ${errMsg}`,
      });
    }
  };

  // Auto-allocate a single order using optimization engine
  const handleAutoAllocateOrder = async (orderId: string, e: React.MouseEvent) => {
    e.stopPropagation();
    try {
      const ord = unplannedOrders?.find((o) => o.id === orderId);
      const targetDate = ord?.delivery_date || deliveryDate;

      setActiveMessage({
        type: 'info',
        text: `Auto-allocating Order ${orderId} via optimization engine...`,
      });
      await generatePlanMutation.mutateAsync({
        depot_id: selectedDepot,
        delivery_date: targetDate,
        regenerate: true,
      });
      setActiveMessage({
        type: 'success',
        text: `Order ${orderId} has been evaluated by the engine and allocated to the optimal trip!`,
      });
      setSelectedOrders((prev) => prev.filter((id) => id !== orderId));
      refetch();
      refetchUnplanned();
    } catch (err: any) {
      console.error('Auto-allocate order error:', err);
      const errMsg =
        err?.response?.data?.message ||
        err?.response?.data?.detail ||
        err?.message ||
        'Unknown error';
      setActiveMessage({
        type: 'error',
        text: `Failed to allocate Order ${orderId}: ${errMsg}`,
      });
    }
  };

  const handleConfirm = async (tripId: string) => {
    try {
      await confirmMutation.mutateAsync(tripId);
      setActiveMessage({
        type: 'success',
        text: `Trip ${tripId} confirmed and queued for loading bay dispatch.`,
      });
      refetch();
      refetchUnplanned();
    } catch (err: any) {
      setActiveMessage({
        type: 'error',
        text: `Failed to confirm trip: ${err.message || 'Unknown error'}`,
      });
    }
  };

  const handleCancel = async (tripId: string) => {
    try {
      await cancelMutation.mutateAsync(tripId);
      setActiveMessage({
        type: 'info',
        text: `Trip ${tripId} cancelled. Orders returned to unassigned queue.`,
      });
      if (editingTrip?.id === tripId) {
        setEditingTrip(null);
      }
      refetch();
      refetchUnplanned();
    } catch (err: any) {
      setActiveMessage({
        type: 'error',
        text: `Failed to cancel trip: ${err.message || 'Unknown error'}`,
      });
    }
  };

  const handleQuickRemoveStop = async (tripId: string, orderId: string, e: React.MouseEvent) => {
    e.stopPropagation();
    try {
      await removeOrderMutation.mutateAsync({
        tripId,
        orderId,
      });
      setActiveMessage({
        type: 'info',
        text: `Order ${orderId} removed from Trip ${tripId} and returned to unassigned queue.`,
      });
      refetch();
      refetchUnplanned();
    } catch (err: any) {
      setActiveMessage({
        type: 'error',
        text: `Failed to remove order: ${err.message || 'Unknown error'}`,
      });
    }
  };

  const toggleOrderSelection = (orderId: string) => {
    setSelectedOrders((prev) =>
      prev.includes(orderId) ? prev.filter((id) => id !== orderId) : [...prev, orderId]
    );
  };

  // Suggest chilled vehicle if there are chilled unplanned orders
  const chilledUnplanned =
    unplannedOrders?.filter((o) => o.temp_requirement === 'chilled') || [];
  const chilledSuggestion =
    chilledUnplanned.length > 0
      ? `Notice: ${chilledUnplanned.length} unassigned chilled order(s) require reefer vehicles.`
      : '';

  if (isLoading) return <LoadingState />;
  if (isError)
    return (
      <EmptyState
        title="Error loading planning data"
        description="Could not connect to planning service."
      />
    );

  const draftTrips = (trips ?? []).filter((t) => t.status === 'DRAFT' || !t.status);
  const confirmedTrips = (trips ?? []).filter((t) => t.status && t.status !== 'DRAFT');
  const displayedTrips =
    tripFilter === 'draft' ? draftTrips : tripFilter === 'confirmed' ? confirmedTrips : trips ?? [];

  return (
    <div className="h-full flex gap-5 overflow-hidden">
      {/* Main Content Area */}
      <div className="flex-1 overflow-y-auto space-y-6 pr-1">
        {/* Page Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div className="flex items-center space-x-3">
            <div className="p-2.5 rounded-xl bg-teal-50 border border-teal-200 text-teal-700 shadow-sm">
              <svg className="w-6 h-6" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M18 6L6 18" />
                <path d="M6 6l12 12" />
                <circle cx="6" cy="6" r="3" />
                <circle cx="18" cy="18" r="3" />
                <circle cx="6" cy="18" r="3" />
                <circle cx="18" cy="6" r="3" />
              </svg>
            </div>
            <div>
              <div className="flex items-center gap-2.5">
                <h1 className="text-lg font-bold text-slate-900 tracking-tight">
                  Auto-Planned Trips & Dispatch Manifests
                </h1>
                <span className="text-xs font-bold px-2.5 py-0.5 rounded-full bg-blue-100 text-blue-800 border border-blue-200">
                  {draftTrips.length} Draft / {confirmedTrips.length} Confirmed
                </span>
              </div>
              <p className="text-xs text-slate-500 mt-0.5">
                Optimized for Cold-chain separation & shortest route sequence ({selectedDepot} • {deliveryDate})
              </p>
            </div>
          </div>

          <div className="flex items-center space-x-2.5">
            <button
              onClick={handleGeneratePlan}
              disabled={generatePlanMutation.isPending}
              className="inline-flex items-center justify-center px-4 py-2 bg-brand-600 hover:bg-brand-700 text-white text-xs font-bold rounded-lg shadow-sm transition-colors disabled:opacity-50"
            >
              {generatePlanMutation.isPending ? 'Optimizing Fleet...' : 'Generate New Plan'}
            </button>
          </div>
        </div>

        {/* Notifications / feedback */}
        {activeMessage && (
          <div
            className={`p-3.5 rounded-xl text-xs font-semibold flex justify-between items-center shadow-sm border ${
              activeMessage.type === 'success'
                ? 'bg-emerald-50 border-emerald-200 text-emerald-900'
                : activeMessage.type === 'error'
                ? 'bg-red-50 border-red-200 text-red-900'
                : 'bg-brand-50 border-brand-200 text-brand-900'
            }`}
          >
            <div className="flex items-center space-x-2">
              {activeMessage.type === 'success' && (
                <svg className="w-4 h-4 text-emerald-600 shrink-0" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                </svg>
              )}
              {activeMessage.type === 'error' && (
                <svg className="w-4 h-4 text-red-600 shrink-0" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                </svg>
              )}
              {activeMessage.type === 'info' && (
                <svg className="w-4 h-4 text-brand-600 shrink-0" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <circle cx="12" cy="12" r="10" />
                  <line x1="12" y1="16" x2="12" y2="12" />
                  <line x1="12" y1="8" x2="12.01" y2="8" />
                </svg>
              )}
              <span>{activeMessage.text}</span>
            </div>
            <button
              onClick={() => setActiveMessage(null)}
              className="text-slate-400 hover:text-slate-700 font-bold ml-4"
            >
              ×
            </button>
          </div>
        )}

        {/* Unassigned orders section with Auto-Allocate option (TOP of the page) */}
        <section className="bg-white border border-slate-200 rounded-2xl p-5 shadow-sm">
          <div className="flex flex-wrap items-center justify-between gap-3 mb-4">
            <div className="flex items-center space-x-3">
              <h2 className="text-sm font-bold uppercase tracking-wider text-slate-800">
                Unassigned Orders ({(unplannedOrders ?? []).length})
              </h2>
              {selectedOrders.length > 0 && (
                <span className="text-xs font-semibold text-brand-700 bg-brand-50 px-2.5 py-0.5 rounded-full border border-brand-200">
                  {selectedOrders.length} selected
                </span>
              )}
            </div>

            <div className="flex items-center space-x-3">
              {chilledSuggestion && (
                <span className="text-xs text-blue-700 font-medium bg-blue-50 border border-blue-200 px-2.5 py-1 rounded-lg">
                  {chilledSuggestion}
                </span>
              )}

              {(unplannedOrders ?? []).length > 0 && (
                <button
                  type="button"
                  onClick={handleAutoAllocate}
                  disabled={generatePlanMutation.isPending}
                  className="inline-flex items-center space-x-1.5 px-3.5 py-2 bg-gradient-to-r from-brand-600 to-indigo-600 hover:from-brand-700 hover:to-indigo-700 text-white text-xs font-bold rounded-lg shadow-sm transition-all disabled:opacity-50"
                  title="Run optimization engine to automatically allocate unassigned orders"
                >
                  {generatePlanMutation.isPending ? (
                    <>
                      <svg className="w-3.5 h-3.5 animate-spin mr-1" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
                      </svg>
                      <span>Optimizing Allocation...</span>
                    </>
                  ) : (
                    <>
                      <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2" />
                      </svg>
                      <span>
                        {selectedOrders.length > 0
                          ? `Auto-Allocate Selected (${selectedOrders.length})`
                          : 'Auto-Allocate All Unassigned'}
                      </span>
                    </>
                  )}
                </button>
              )}
            </div>
          </div>

          {unplannedLoading ? (
            <p className="text-xs text-slate-500">Loading unassigned orders...</p>
          ) : (unplannedOrders ?? []).length === 0 ? (
            <div className="p-6 bg-slate-50 border border-dashed border-slate-200 rounded-xl text-center">
              <svg className="w-8 h-8 text-emerald-500 mx-auto mb-2" viewBox="0 0 20 20" fill="currentColor">
                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
              </svg>
              <p className="text-xs font-semibold text-slate-700">All submitted orders are assigned to trips.</p>
              <p className="text-[11px] text-slate-400 mt-0.5">No pending or unassigned orders for {deliveryDate}.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3 max-h-72 overflow-y-auto pt-1">
              {unplannedOrders?.map((o) => {
                const isSelected = selectedOrders.includes(o.id);
                const outlet = outletsById[o.outlet_id];
                return (
                  <div
                    key={o.id}
                    onClick={() => toggleOrderSelection(o.id)}
                    className={`flex flex-col justify-between p-3.5 border rounded-xl text-xs cursor-pointer transition-all shadow-sm ${
                      isSelected
                        ? 'border-brand-500 bg-brand-50/70 ring-2 ring-brand-500/20 text-brand-900'
                        : 'border-slate-200 hover:border-slate-300 hover:bg-slate-50/80 bg-white text-slate-700'
                    }`}
                  >
                    <div>
                      <div className="flex items-start justify-between gap-2">
                        <div className="flex items-center space-x-2">
                          <input
                            type="checkbox"
                            className="rounded border-slate-300 text-brand-600 focus:ring-brand-500"
                            checked={isSelected}
                            onChange={() => {}} // toggled by parent div
                          />
                          <span className="font-mono font-bold text-slate-900">{o.id}</span>
                        </div>
                        <div className="flex items-center gap-1">
                          {o.deferral_count > 0 && (
                            <span className="px-1.5 py-0.5 rounded text-[9px] font-extrabold bg-amber-100 text-amber-900 border border-amber-300" title="Re-queued order with aging priority">
                              Re-queued • Def #{o.deferral_count}
                            </span>
                          )}
                          <span
                            className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                              o.temp_requirement === 'chilled'
                                ? 'bg-blue-100 text-blue-800 border border-blue-200'
                                : 'bg-amber-100 text-amber-800 border border-amber-200'
                            }`}
                          >
                            {o.temp_requirement}
                          </span>
                        </div>
                      </div>

                      <div className="mt-2 space-y-0.5">
                        <div className="font-semibold text-slate-800 truncate">
                          {outlet ? `${outlet.outlet_id} – ${outlet.brand}` : `Outlet ${o.outlet_id}`}
                        </div>
                        <div className="text-[11px] text-slate-500 flex items-center gap-2">
                          <span>{outlet?.district ?? '–'}</span>
                          <span>•</span>
                          <span>
                            {o.order_units} units ({o.order_weight_kg}kg)
                          </span>
                        </div>
                      </div>
                    </div>

                    <div className="mt-3 pt-2.5 border-t border-slate-100 flex items-center justify-between">
                      <span className="text-[10px] text-slate-400 font-mono">{o.delivery_date}</span>
                      <button
                        type="button"
                        onClick={(e) => handleAutoAllocateOrder(o.id, e)}
                        disabled={generatePlanMutation.isPending}
                        className="inline-flex items-center space-x-1 px-2.5 py-1 text-[11px] font-bold text-brand-700 bg-brand-50 hover:bg-brand-100 border border-brand-200 rounded-md transition-colors"
                        title="Auto-allocate this order to optimal trip"
                      >
                        <svg className="w-3 h-3 text-brand-600" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                          <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2" />
                        </svg>
                        <span>Auto Allocate</span>
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </section>

        {/* Trips Section with View Filter Tabs (BELOW unassigned orders) */}
        <section className="space-y-4">
          <div className="flex flex-wrap items-center justify-between gap-3 bg-white p-3 rounded-2xl border border-slate-200 shadow-sm">
            <div className="flex items-center space-x-2">
              <button
                type="button"
                onClick={() => setTripFilter('draft')}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-all flex items-center gap-2 ${
                  tripFilter === 'draft'
                    ? 'bg-blue-600 text-white shadow-sm'
                    : 'bg-slate-100 hover:bg-slate-200 text-slate-700'
                }`}
              >
                <span>Draft Routes (Awaiting Review)</span>
                <span
                  className={`text-[10px] px-2 py-0.5 rounded-full font-extrabold ${
                    tripFilter === 'draft' ? 'bg-blue-800 text-white' : 'bg-slate-200 text-slate-800'
                  }`}
                >
                  {draftTrips.length}
                </span>
              </button>

              <button
                type="button"
                onClick={() => setTripFilter('confirmed')}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-all flex items-center gap-2 ${
                  tripFilter === 'confirmed'
                    ? 'bg-emerald-700 text-white shadow-sm'
                    : 'bg-slate-100 hover:bg-slate-200 text-slate-700'
                }`}
              >
                <span>Confirmed Dispatch Manifests</span>
                <span
                  className={`text-[10px] px-2 py-0.5 rounded-full font-extrabold ${
                    tripFilter === 'confirmed' ? 'bg-emerald-900 text-white' : 'bg-slate-200 text-slate-800'
                  }`}
                >
                  {confirmedTrips.length}
                </span>
              </button>

              <button
                type="button"
                onClick={() => setTripFilter('all')}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-all flex items-center gap-2 ${
                  tripFilter === 'all'
                    ? 'bg-slate-800 text-white shadow-sm'
                    : 'bg-slate-100 hover:bg-slate-200 text-slate-700'
                }`}
              >
                <span>All Routes</span>
                <span
                  className={`text-[10px] px-2 py-0.5 rounded-full font-extrabold ${
                    tripFilter === 'all' ? 'bg-slate-900 text-white' : 'bg-slate-200 text-slate-800'
                  }`}
                >
                  {(trips ?? []).length}
                </span>
              </button>
            </div>

            <div className="text-xs text-slate-500 font-medium">
              Showing {displayedTrips.length} of {(trips ?? []).length} route(s)
            </div>
          </div>

          {displayedTrips.length === 0 ? (
            <div className="bg-white border border-slate-200 rounded-2xl p-10 text-center shadow-sm">
              <div className="w-12 h-12 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-3 text-slate-400">
                <svg className="w-6 h-6" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <rect x="1" y="3" width="15" height="13" />
                  <polygon points="16 8 20 8 23 11 23 16 16 16 16 8" />
                  <circle cx="5.5" cy="18.5" r="2.5" />
                  <circle cx="18.5" cy="18.5" r="2.5" />
                </svg>
              </div>
              <h3 className="text-base font-bold text-slate-800">
                {tripFilter === 'confirmed'
                  ? 'No Confirmed Trips Yet'
                  : tripFilter === 'draft'
                  ? 'No Draft Trips Awaiting Review'
                  : 'No Trips Planned'}
              </h3>
              <p className="text-xs text-slate-500 mt-1 max-w-md mx-auto">
                {tripFilter === 'confirmed'
                  ? 'Review draft trips above and click "Confirm Trip" to lock manifests for warehouse loading.'
                  : 'Click "Generate New Plan" or "Auto-Allocate All Unassigned" to create optimized routes for pending orders.'}
              </p>
            </div>
          ) : (
            <div className="space-y-4">
              {displayedTrips.map((trip) => {
                const isReefer =
                  trip.vehicle?.temperature === 'chilled' || trip.brand === 'Fresh';
                const isConfirmed = trip.status === 'CONFIRMED' || trip.status === 'LOADING';
                const isEditing = currentEditingTrip?.id === trip.id;

                const weightUsed = trip.weight_used || 0;
                const weightCap = trip.weight_cap || 2200;
                const weightPct = Math.round((weightUsed / Math.max(weightCap, 1)) * 100);
                const volumeUsed = trip.volume_used || 0;
                const volumeCap = trip.volume_cap || 14.0;
                const availableSpare = Math.max(0, weightCap - weightUsed);

                const brandTagLabel =
                  trip.brand === 'Fresh'
                    ? 'WAYPOINT FRESH (CHILLED)'
                    : `WAYPOINT ${trip.brand.toUpperCase()}`;

                const corridorLabel = `${trip.district} Corridor`;
                const driverName =
                  trip.brand === 'Fresh' ? 'S. Jayasuriya' : 'N. Bandara';

                return (
                  <div
                    key={trip.id}
                    className={`bg-white border rounded-2xl shadow-sm transition-all overflow-hidden ${
                      isEditing
                        ? 'border-blue-500 ring-2 ring-blue-500/20'
                        : 'border-slate-200/90 hover:border-slate-300'
                    }`}
                  >
                    {/* Trip Card Header */}
                    <div className="p-5 border-b border-slate-100 flex flex-col md:flex-row md:items-center justify-between gap-4 bg-slate-50/50">
                      <div className="flex items-start space-x-3.5">
                        {/* Vehicle Box Icon */}
                        <div
                          className={`p-2.5 rounded-xl text-white shadow-sm shrink-0 flex items-center justify-center ${
                            isReefer ? 'bg-emerald-800' : 'bg-slate-700'
                          }`}
                        >
                          {isReefer ? (
                            <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                              <path d="M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6" />
                            </svg>
                          ) : (
                            <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                              <rect x="1" y="3" width="15" height="13" />
                              <polygon points="16 8 20 8 23 11 23 16 16 16 16 8" />
                              <circle cx="5.5" cy="18.5" r="2.5" />
                              <circle cx="18.5" cy="18.5" r="2.5" />
                            </svg>
                          )}
                        </div>

                        {/* Title & tags */}
                        <div className="space-y-1">
                          <div className="flex flex-wrap items-center gap-2">
                            <h3 className="font-bold text-slate-900 text-base font-mono">
                              Trip #{trip.id}
                            </h3>
                            <span
                              className={`text-[10px] font-bold uppercase tracking-wider px-2.5 py-0.5 rounded-full ${
                                isReefer
                                  ? 'bg-emerald-100 text-emerald-800 border border-emerald-200'
                                  : 'bg-slate-200 text-slate-800'
                              }`}
                            >
                              {brandTagLabel}
                            </span>
                            <span className="text-[10px] font-medium text-slate-500 bg-white border border-slate-200 px-2 py-0.5 rounded-full">
                              {corridorLabel}
                            </span>
                          </div>

                          <div className="text-xs text-slate-600 flex flex-wrap items-center gap-x-3 gap-y-1">
                            <span>
                              Vehicle: <strong className="font-semibold text-slate-800">{trip.vehicle_id}</strong> ({isReefer ? 'Reefer 2.5T' : 'Heavy Box 3.5T'})
                            </span>
                            <span className="text-slate-300">•</span>
                            <span>
                              Driver: <strong className="font-semibold text-slate-800">{driverName}</strong>
                            </span>
                            <span className="text-slate-300">•</span>
                            <span>
                              {isReefer ? (
                                <span className="text-teal-800 font-semibold">Temp: 2°C – 4°C Maintained</span>
                              ) : (
                                <span className="text-slate-600">Cargo: Ambient Dry / High Value</span>
                              )}
                            </span>
                          </div>
                        </div>
                      </div>

                      {/* Top Action Buttons */}
                      <div className="flex items-center space-x-2 shrink-0">
                        <button
                          type="button"
                          onClick={() => setEditingTrip(isEditing ? null : trip)}
                          className={`inline-flex items-center space-x-1.5 px-3.5 py-2 text-xs font-bold rounded-lg border shadow-sm transition-all ${
                            isEditing
                              ? 'bg-blue-50 border-blue-300 text-blue-800 ring-2 ring-blue-500/20'
                              : 'bg-white border-slate-300 text-slate-700 hover:bg-slate-50 hover:border-slate-400'
                          }`}
                        >
                          <svg className="w-3.5 h-3.5 text-blue-600" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                            <line x1="8" y1="6" x2="21" y2="6" />
                            <line x1="8" y1="12" x2="21" y2="12" />
                            <line x1="8" y1="18" x2="21" y2="18" />
                            <line x1="3" y1="6" x2="3.01" y2="6" />
                            <line x1="3" y1="12" x2="3.01" y2="12" />
                            <line x1="3" y1="18" x2="3.01" y2="18" />
                          </svg>
                          <span>{isEditing ? 'Editing Plan' : 'Edit Plan'}</span>
                        </button>

                        {!isConfirmed ? (
                          <button
                            type="button"
                            onClick={() => handleConfirm(trip.id)}
                            disabled={confirmMutation.isPending}
                            className="inline-flex items-center space-x-1.5 px-4 py-2 bg-emerald-700 hover:bg-emerald-800 text-white text-xs font-bold rounded-lg shadow-sm transition-all disabled:opacity-50"
                          >
                            <svg className="w-3.5 h-3.5" viewBox="0 0 20 20" fill="currentColor">
                              <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                            </svg>
                            <span>{confirmMutation.isPending ? 'Confirming...' : 'Confirm Trip'}</span>
                          </button>
                        ) : (
                          <span className="inline-flex items-center px-3 py-1.5 rounded-lg text-xs font-bold bg-emerald-100 text-emerald-800 border border-emerald-200">
                            ✓ Confirmed
                          </span>
                        )}
                      </div>
                    </div>

                    {/* Utilization Progress Bar */}
                    <div className="px-5 pt-3 pb-2 bg-white">
                      <div className="flex flex-wrap items-center justify-between text-xs text-slate-600 mb-1.5">
                        <span>
                          Payload & Volume Utilization:{' '}
                          <strong className="text-slate-900 font-bold">
                            {weightUsed.toLocaleString()} kg / {weightCap.toLocaleString()} kg ({weightPct}% Used)
                          </strong>
                        </span>
                        <span className="text-[11px] text-slate-500">
                          Max Volume: {volumeCap} m³ • Available: <strong>{availableSpare.toLocaleString()} kg spare</strong>
                        </span>
                      </div>
                      <div className="h-2 bg-slate-100 rounded-full overflow-hidden">
                        <div
                          className={`h-full transition-all duration-300 ${
                            weightPct > 100 ? 'bg-red-500' : weightPct > 85 ? 'bg-amber-500' : 'bg-emerald-600'
                          }`}
                          style={{ width: `${Math.min(weightPct, 100)}%` }}
                        />
                      </div>
                    </div>

                    {/* Orders / Stops List Inside Trip */}
                    <div className="p-5 pt-3 space-y-2">
                      {(trip.stops || []).length === 0 ? (
                        <div className="p-4 rounded-xl bg-slate-50 border border-dashed border-slate-200 text-center text-xs text-slate-400">
                          No stops currently assigned to this trip. Click "Edit Plan" to add compatible orders.
                        </div>
                      ) : (
                        trip.stops.map((stop: StopDetail, idx: number) => {
                          const stopOutlet = outletsById[stop.outlet_id];
                          const windowText = stopOutlet
                            ? `${stopOutlet.window_open_time} – ${stopOutlet.window_close_time}`
                            : `${stop.window_open_time || '06:00'} – ${stop.window_close_time || '07:30'}`;
                          const etaText = stop.eta ? `ETA ${stop.eta}` : 'ETA Scheduled';

                          const isChilledStop =
                            trip.brand === 'Fresh' ||
                            stopOutlet?.brand === 'Fresh';

                          return (
                            <div
                              key={stop.id || stop.order_id}
                              className="flex items-center justify-between p-3 rounded-xl border border-slate-100 hover:border-slate-200 bg-slate-50/40 hover:bg-slate-50 transition-colors text-xs"
                            >
                              <div className="flex items-center space-x-3 min-w-0">
                                <span className="w-6 h-6 rounded-full bg-emerald-800 text-white text-[11px] font-bold flex items-center justify-center shrink-0">
                                  {stop.seq || idx + 1}
                                </span>
                                <div className="space-y-0.5 min-w-0">
                                  <div className="flex items-center gap-2 flex-wrap">
                                    <span className="font-bold text-teal-900 font-mono text-xs">
                                      {stop.order_id}
                                    </span>
                                    <span
                                      className={`px-2 py-0.2 rounded text-[10px] font-semibold ${
                                        isChilledStop
                                          ? 'bg-blue-100 text-blue-800'
                                          : 'bg-slate-200 text-slate-700'
                                      }`}
                                    >
                                      {isChilledStop ? 'Chilled 2°C' : 'Ambient'}
                                    </span>
                                  </div>
                                  <div className="font-semibold text-slate-900 truncate">
                                    {stop.outlet_name || (stopOutlet ? `${stopOutlet.outlet_id} – ${stopOutlet.brand}` : `Outlet ${stop.outlet_id}`)}
                                  </div>
                                </div>
                              </div>

                              <div className="flex items-center space-x-6 text-right shrink-0">
                                <div>
                                  <div className="font-bold text-slate-900">
                                    {stop.order_weight_kg} kg
                                  </div>
                                  <div className="text-[10px] text-slate-400">
                                    {stop.order_volume_m3} m³
                                  </div>
                                </div>

                                <div>
                                  <div className="font-mono font-semibold text-slate-800">
                                    {windowText}
                                  </div>
                                  <div className="text-[10px] font-bold text-brand-700">
                                    {etaText}
                                  </div>
                                </div>

                                <button
                                  type="button"
                                  onClick={(e) => handleQuickRemoveStop(trip.id, stop.order_id, e)}
                                  className="text-slate-400 hover:text-red-600 p-1.5 rounded-lg hover:bg-red-50 transition-colors"
                                  title="Remove order from trip"
                                >
                                  <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                    <line x1="18" y1="6" x2="6" y2="18" />
                                    <line x1="6" y1="6" x2="18" y2="18" />
                                  </svg>
                                </button>
                              </div>
                            </div>
                          );
                        })
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </section>
      </div>

      {/* Right Drawer: Manual Amendment (Add / Remove Orders) */}
      {currentEditingTrip && (
        <EditTripOrdersDrawer
          trip={currentEditingTrip}
          unassignedOrders={unplannedOrders || []}
          outletsById={outletsById}
          onClose={() => setEditingTrip(null)}
          onSuccess={(msg) => {
            setActiveMessage({
              type: 'success',
              text: msg,
            });
            refetch();
            refetchUnplanned();
          }}
        />
      )}
    </div>
  );
};
