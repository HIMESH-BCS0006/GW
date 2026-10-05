import React, { useState, useMemo, useEffect } from 'react';
import type { TripCard } from '../api/pending/planning';
import type { Order, Outlet } from '../api/generated/models';
import type { StopDetail } from '../api/generated/models/stopDetail';
import {
  useAddOrderToTrip,
  useRemoveOrderFromTrip,
} from '../api/generated/dispatcher/dispatcher';

interface EditTripOrdersDrawerProps {
  trip: TripCard | null;
  unassignedOrders: Order[];
  outletsById: Record<string, Outlet>;
  onClose: () => void;
  onSuccess?: (message: string) => void;
}

export const EditTripOrdersDrawer: React.FC<EditTripOrdersDrawerProps> = ({
  trip,
  unassignedOrders,
  outletsById,
  onClose,
  onSuccess,
}) => {
  const addOrderMutation = useAddOrderToTrip();
  const removeOrderMutation = useRemoveOrderFromTrip();

  // Staged changes
  const [stagedToAdd, setStagedToAdd] = useState<string[]>([]);
  const [stagedToRemove, setStagedToRemove] = useState<string[]>([]);
  const [isApplying, setIsApplying] = useState<boolean>(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  useEffect(() => {
    setStagedToAdd([]);
    setStagedToRemove([]);
    setErrorMessage(null);
  }, [trip]);

  if (!trip) return null;

  // Filter compatible unassigned orders (same brand, compatible temp, same depot if applicable)
  const isTripReefer =
    trip.vehicle?.temperature === 'chilled' ||
    (trip.vehicle as any)?.temp === 'chilled' ||
    trip.brand === 'Fresh';

  const compatibleOrders = (unassignedOrders || []).filter((order) => {
    const outlet = outletsById[order.outlet_id];
    const orderBrand = order.brand || outlet?.brand;
    // Must match brand if defined
    if (orderBrand && trip.brand && orderBrand.toLowerCase() !== trip.brand.toLowerCase()) {
      return false;
    }
    // Chilled orders must have reefer vehicle
    if (order.temp_requirement === 'chilled' && !isTripReefer) {
      return false;
    }
    return true;
  });

  // Calculate live payload weight
  const currentStops = trip.stops || [];
  const currentWeight = currentStops
    .filter((s) => !stagedToRemove.includes(s.order_id))
    .reduce((sum, s) => sum + (s.order_weight_kg || 0), 0);

  const addedWeight = stagedToAdd.reduce((sum, orderId) => {
    const ord = unassignedOrders.find((o) => o.id === orderId);
    return sum + (ord?.order_weight_kg || 0);
  }, 0);

  const removedWeight = stagedToRemove.reduce((sum, orderId) => {
    const stop = currentStops.find((s) => s.order_id === orderId);
    return sum + (stop?.order_weight_kg || 0);
  }, 0);

  const newTotalWeight = currentWeight + addedWeight;
  const weightCap = trip.weight_cap || 2200;
  const weightPct = Math.round((newTotalWeight / Math.max(weightCap, 1)) * 100);
  const remainingWeight = Math.max(0, weightCap - newTotalWeight);

  const toggleStagedAdd = (orderId: string) => {
    setStagedToAdd((prev) =>
      prev.includes(orderId) ? prev.filter((id) => id !== orderId) : [...prev, orderId]
    );
  };

  const toggleStagedRemove = (orderId: string) => {
    setStagedToRemove((prev) =>
      prev.includes(orderId) ? prev.filter((id) => id !== orderId) : [...prev, orderId]
    );
  };

  const handleReset = () => {
    setStagedToAdd([]);
    setStagedToRemove([]);
    setErrorMessage(null);
  };

  const handleApplyAmendments = async () => {
    if (stagedToAdd.length === 0 && stagedToRemove.length === 0) {
      onClose();
      return;
    }

    setIsApplying(true);
    setErrorMessage(null);

    try {
      // 1. Remove staged orders
      for (const orderId of stagedToRemove) {
        await removeOrderMutation.mutateAsync({
          tripId: trip.id,
          orderId,
        });
      }

      // 2. Add staged orders
      for (const orderId of stagedToAdd) {
        await addOrderMutation.mutateAsync({
          tripId: trip.id,
          orderId,
        });
      }

      const addedCount = stagedToAdd.length;
      const removedCount = stagedToRemove.length;
      const summaryMsg = `Trip ${trip.id} amended: ${addedCount} order(s) added, ${removedCount} order(s) removed.`;

      if (onSuccess) {
        onSuccess(summaryMsg);
      }
      onClose();
    } catch (err: any) {
      console.error('Failed to apply amendments:', err);
      const errMsg =
        err?.response?.data?.violations?.[0]?.message ||
        err?.response?.data?.message ||
        err?.response?.data?.detail ||
        err?.message ||
        'Unknown error';
      setErrorMessage(`Failed to apply amendments: ${errMsg}`);
    } finally {
      setIsApplying(false);
    }
  };

  const vehicleTypeLabel = isTripReefer ? 'Reefer' : 'Heavy Box';
  const vehicleName = `${vehicleTypeLabel} ${trip.vehicle_id || 'WP-CAB-3912'}`;

  return (
    <div className="w-full lg:w-[420px] shrink-0 bg-white border-l border-slate-200 shadow-xl flex flex-col h-full overflow-hidden animate-in slide-in-from-right duration-200">
      {/* Header */}
      <div className="p-4 border-b border-slate-100 flex items-start justify-between bg-slate-50/70">
        <div className="flex items-start space-x-3">
          <div className="p-2 rounded-lg bg-blue-600 text-white shadow-sm shrink-0">
            <svg
              className="w-4 h-4"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <line x1="8" y1="6" x2="21" y2="6" />
              <line x1="8" y1="12" x2="21" y2="12" />
              <line x1="8" y1="18" x2="21" y2="18" />
              <line x1="3" y1="6" x2="3.01" y2="6" />
              <line x1="3" y1="12" x2="3.01" y2="12" />
              <line x1="3" y1="18" x2="3.01" y2="18" />
            </svg>
          </div>
          <div>
            <h3 className="text-sm font-bold text-slate-900 tracking-tight">
              Add / Remove Orders
            </h3>
            <p className="text-[11px] text-blue-700 font-medium">
              Amending Trip #{trip.id} ({vehicleName})
            </p>
          </div>
        </div>
        <button
          onClick={onClose}
          className="text-slate-400 hover:text-slate-600 p-1 rounded-md hover:bg-slate-200/60 transition-colors"
          aria-label="Close drawer"
        >
          <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <line x1="18" y1="6" x2="6" y2="18" />
            <line x1="6" y1="6" x2="18" y2="18" />
          </svg>
        </button>
      </div>

      {/* Recalculated Payload Card */}
      <div className="p-4 border-b border-slate-100 bg-white">
        <div className="flex items-center justify-between text-xs mb-1.5">
          <span className="text-slate-500 font-medium">Recalculated Payload:</span>
          <span className="font-bold text-slate-800">
            {newTotalWeight.toLocaleString()} kg / {weightCap.toLocaleString()} kg ({weightPct}%)
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
        <div className="flex items-center justify-between text-[11px] text-slate-500 mt-2 font-medium">
          <span className={addedWeight > 0 ? 'text-emerald-700 font-semibold' : ''}>
            +{addedWeight} kg staged to add
            {removedWeight > 0 && ` (-${removedWeight} kg removed)`}
          </span>
          <span className="font-semibold text-slate-700">Remaining: {remainingWeight} kg</span>
        </div>
      </div>

      {/* Error Message */}
      {errorMessage && (
        <div className="m-3 p-2.5 bg-red-50 border border-red-200 text-red-800 text-xs rounded-lg flex items-center justify-between">
          <span>{errorMessage}</span>
          <button onClick={() => setErrorMessage(null)} className="text-red-500 font-bold ml-2">
            ×
          </button>
        </div>
      )}

      {/* Scrollable lists */}
      <div className="flex-1 overflow-y-auto p-4 space-y-5">
        {/* CURRENT STOPS IN MANIFEST */}
        <div className="space-y-2.5">
          <div className="flex items-center justify-between">
            <h4 className="text-[11px] font-bold uppercase tracking-wider text-slate-500">
              CURRENT STOPS IN MANIFEST
            </h4>
            <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-slate-100 text-slate-700">
              {currentStops.length - stagedToRemove.length} Stops Allocated
            </span>
          </div>

          {currentStops.length === 0 ? (
            <p className="text-xs text-slate-400 italic p-3 text-center bg-slate-50 rounded-lg">
              No orders currently in this trip manifest.
            </p>
          ) : (
            <div className="space-y-2">
              {currentStops.map((stop, idx) => {
                const isMarkedForRemoval = stagedToRemove.includes(stop.order_id);
                return (
                  <div
                    key={stop.id || stop.order_id}
                    className={`flex items-center justify-between p-2.5 rounded-lg border text-xs transition-colors ${
                      isMarkedForRemoval
                        ? 'bg-red-50/70 border-red-200 opacity-60'
                        : 'bg-white border-slate-200/90 shadow-sm'
                    }`}
                  >
                    <div className="flex items-center space-x-2.5 min-w-0">
                      <span className="w-5 h-5 rounded-full bg-emerald-700 text-white text-[10px] font-bold flex items-center justify-center shrink-0">
                        {stop.seq || idx + 1}
                      </span>
                      <div className="min-w-0">
                        <div className="font-bold text-slate-900 font-mono text-[11px] flex items-center gap-1.5">
                          <span className={isMarkedForRemoval ? 'line-through' : ''}>
                            {stop.order_id}
                          </span>
                          <span className="text-slate-400 font-normal">•</span>
                          <span className="text-slate-700 font-semibold truncate text-[11px]">
                            {stop.outlet_name || `Outlet ${stop.outlet_id}`}
                          </span>
                        </div>
                        <div className="text-[10px] text-slate-500">
                          {stop.order_weight_kg} kg • {trip.vehicle.temperature}
                        </div>
                      </div>
                    </div>

                    <button
                      type="button"
                      onClick={() => toggleStagedRemove(stop.order_id)}
                      className={`px-2 py-1 text-[11px] font-semibold rounded-md transition-colors ${
                        isMarkedForRemoval
                          ? 'bg-slate-200 text-slate-700 hover:bg-slate-300'
                          : 'text-amber-700 hover:text-amber-900 hover:bg-amber-50'
                      }`}
                    >
                      {isMarkedForRemoval ? 'Undo' : '⊘ Remove'}
                    </button>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* COMPATIBLE ORDERS TO ADD */}
        <div className="space-y-2.5 pt-2 border-t border-slate-100">
          <div className="flex items-center justify-between">
            <h4 className="text-[11px] font-bold uppercase tracking-wider text-slate-500">
              COMPATIBLE ORDERS TO ADD
            </h4>
            <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-800 border border-emerald-200">
              {isTripReefer ? 'Matched Refrigeration' : 'Matched Ambient'}
            </span>
          </div>
          <p className="text-[10px] text-slate-400">
            Select additional intake orders compatible with temperature & route corridor.
          </p>

          {compatibleOrders.length === 0 ? (
            <p className="text-xs text-slate-400 italic p-3 text-center bg-slate-50 rounded-lg">
              No compatible unassigned orders available.
            </p>
          ) : (
            <div className="space-y-2">
              {compatibleOrders.map((order) => {
                const isSelected = stagedToAdd.includes(order.id);
                const outlet = outletsById[order.outlet_id];
                const windowText = outlet
                  ? `${outlet.window_open_time} - ${outlet.window_close_time}`
                  : '05:00 - 07:00 AM';

                return (
                  <div
                    key={order.id}
                    onClick={() => toggleStagedAdd(order.id)}
                    className={`flex items-start p-2.5 rounded-lg border text-xs cursor-pointer select-none transition-all ${
                      isSelected
                        ? 'border-blue-500 bg-blue-50/60 shadow-sm'
                        : 'border-slate-200 hover:border-slate-300 bg-white hover:bg-slate-50/50'
                    }`}
                  >
                    <input
                      type="checkbox"
                      checked={isSelected}
                      onChange={(e) => {
                        e.stopPropagation();
                        toggleStagedAdd(order.id);
                      }}
                      className="mt-0.5 rounded border-slate-300 text-blue-600 focus:ring-blue-500 mr-2.5 cursor-pointer"
                    />
                    <div className="min-w-0 flex-1 space-y-0.5">
                      <div className="flex items-center justify-between">
                        <span className="font-mono font-bold text-slate-900 text-[11px]">
                          {order.id}
                        </span>
                        <span className="text-[10px] font-bold text-emerald-800 bg-emerald-100/80 px-1.5 py-0.2 rounded">
                          +{order.order_weight_kg} kg
                        </span>
                      </div>
                      <div className="text-[11px] font-semibold text-slate-800 truncate">
                        {outlet ? `${outlet.outlet_id} – ${outlet.brand}` : `Outlet ${order.outlet_id}`}
                      </div>
                      <div className="text-[10px] text-slate-500 flex items-center gap-2">
                        <span>Waypoint {outlet?.brand || order.brand || trip.brand}</span>
                        <span>•</span>
                        <span>Delivery: {windowText}</span>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>

      {/* Footer */}
      <div className="p-4 border-t border-slate-200 bg-slate-50 flex items-center justify-between gap-3">
        <button
          type="button"
          onClick={handleReset}
          disabled={isApplying || (stagedToAdd.length === 0 && stagedToRemove.length === 0)}
          className="px-3 py-2 text-xs font-semibold text-slate-600 hover:text-slate-800 bg-white border border-slate-300 rounded-lg hover:bg-slate-100 disabled:opacity-40 transition-colors"
        >
          Reset Changes
        </button>

        <button
          type="button"
          onClick={handleApplyAmendments}
          disabled={isApplying || (stagedToAdd.length === 0 && stagedToRemove.length === 0)}
          className="flex-1 inline-flex items-center justify-center space-x-1.5 px-4 py-2 bg-blue-700 hover:bg-blue-800 disabled:opacity-50 text-white text-xs font-bold rounded-lg shadow-sm transition-all"
        >
          {isApplying ? (
            <>
              <svg className="w-3.5 h-3.5 animate-spin mr-1" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
              </svg>
              <span>Saving...</span>
            </>
          ) : (
            <>
              <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z" />
                <polyline points="17 21 17 13 7 13 7 21" />
                <polyline points="7 3 7 8 15 8" />
              </svg>
              <span>Apply Amendments</span>
            </>
          )}
        </button>
      </div>
    </div>
  );
};
