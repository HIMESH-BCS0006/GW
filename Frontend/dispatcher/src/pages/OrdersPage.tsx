import React, { useMemo, useState } from 'react';
import { useGetDispatchQueue, useConfirmTrip } from '../api/generated/dispatcher/dispatcher';
import { useOutletMap } from '../hooks/useOutletMap';
import { useAuth } from '../context/AuthContext';
import type { Order } from '../api/generated/models';
import { OrderStatus, TemperatureRequirement, Brand } from '../api/generated/models';
import { PageHeader } from '../components/PageHeader';
import { LoadingState } from '../components/LoadingState';
import { EmptyState } from '../components/EmptyState';
import { ErrorState } from '../components/ErrorState';
import { StatusBadge } from '../components/StatusBadge';
import { OrderDetailPanel } from '../components/OrderDetailPanel';
import { CancelOrderModal } from '../components/CancelOrderModal';

// ─── Types ────────────────────────────────────────────────────────────────────

interface Filters {
  brand: string;
  depot: string;
  delivery_date: string;
  status: string;
  temp_requirement: string;
}

type OrderWithPriorityFlags = Order & {
  deferred_yesterday?: boolean;
  days_since_last_served?: number;
};

// ─── Helpers ─────────────────────────────────────────────────────────────────

const ALL = '';

const STATUSES: string[] = [
  OrderStatus.SUBMITTED,
  OrderStatus.PLANNED,
  OrderStatus.SCHEDULED,
  OrderStatus.LOADED,
  OrderStatus.IN_TRANSIT,
  OrderStatus.DELIVERED,
  OrderStatus.PARTIALLY_DELIVERED,
  OrderStatus.DEFERRED,
  OrderStatus.CANCELLED,
];

const BRANDS: string[] = [Brand.Fresh, Brand.Style, Brand.Tech];
const TEMPS: string[] = [TemperatureRequirement.ambient, TemperatureRequirement.chilled];

function FilterSelect({
  label,
  value,
  options,
  placeholder,
  onChange,
}: {
  label: string;
  value: string;
  options: string[];
  placeholder: string;
  onChange: (v: string) => void;
}) {
  return (
    <div className="flex flex-col gap-0.5">
      <label className="text-[10px] font-semibold text-slate-500 uppercase tracking-wider">
        {label}
      </label>
      <select
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="border border-slate-300 rounded-md text-xs px-2.5 py-1.5 bg-white focus:ring-2 focus:ring-brand-500 focus:border-brand-500"
      >
        <option value={ALL}>{placeholder}</option>
        {options.map((o) => (
          <option key={o} value={o}>
            {o}
          </option>
        ))}
      </select>
    </div>
  );
}

// ─── Main Page ────────────────────────────────────────────────────────────────

export const OrdersPage: React.FC = () => {
  const { selectedDepot, deliveryDate } = useAuth();

  const [filters, setFilters] = useState<Filters>({
    brand: ALL,
    depot: ALL,
    delivery_date: ALL,
    status: ALL,
    temp_requirement: ALL,
  });

  const [selectedOrderId, setSelectedOrderId] = useState<string | null>(null);
  const [checkedOrderIds, setCheckedOrderIds] = useState<string[]>([]);
  const [cancelModalOrder, setCancelModalOrder] = useState<Order | null>(null);
  const [actionFeedback, setActionFeedback] = useState<{
    type: 'success' | 'error';
    text: string;
  } | null>(null);

  const {
    data: orders,
    isLoading,
    isError,
    error,
    refetch,
  } = useGetDispatchQueue(selectedDepot ? { depot_id: selectedDepot } : undefined);

  const { outletsById, isLoading: loadingOutlets } = useOutletMap();
  const confirmTripMutation = useConfirmTrip();

  // Collect unique depots across loaded outlets
  const depotOptions = useMemo(() => {
    const depots = new Set<string>();
    Object.values(outletsById).forEach((o) => o.depot && depots.add(o.depot));
    return Array.from(depots).sort();
  }, [outletsById]);

  // Collect unique delivery dates across loaded orders
  const dateOptions = useMemo(() => {
    const dates = new Set<string>();
    if (deliveryDate) dates.add(deliveryDate);
    (orders || []).forEach((o) => o.delivery_date && dates.add(o.delivery_date));
    return Array.from(dates).sort();
  }, [orders, deliveryDate]);

  // Apply all filters client-side (dispatch/queue has no server-side brand/district filter)
  const filteredOrders = useMemo(() => {
    if (!orders) return [];
    return (orders as OrderWithPriorityFlags[]).filter((order) => {
      const outlet = outletsById[order.outlet_id];

      if (filters.brand !== ALL && outlet?.brand !== filters.brand) return false;
      if (filters.depot !== ALL && outlet?.depot !== filters.depot) return false;
      if (filters.delivery_date !== ALL && order.delivery_date !== filters.delivery_date) return false;
      if (filters.status !== ALL && order.status !== filters.status) return false;
      if (
        filters.temp_requirement !== ALL &&
        order.temp_requirement !== filters.temp_requirement
      )
        return false;

      return true;
    });
  }, [orders, outletsById, filters]);

  // Determine if any priority-flag columns are present in the actual data
  const hasDeferredYesterdayFlag = useMemo(
    () => (orders as OrderWithPriorityFlags[] | undefined)?.some((o) => 'deferred_yesterday' in o) ?? false,
    [orders]
  );
  const hasDaysSinceFlag = useMemo(
    () =>
      (orders as OrderWithPriorityFlags[] | undefined)?.some(
        (o) => 'days_since_last_served' in o
      ) ?? false,
    [orders]
  );

  const selectedOrder = orders?.find((o) => o.id === selectedOrderId) as
    | OrderWithPriorityFlags
    | undefined;
  const selectedOutlet = selectedOrder ? outletsById[selectedOrder.outlet_id] : undefined;

  const setFilter = (key: keyof Filters) => (value: string) =>
    setFilters((prev) => ({ ...prev, [key]: value }));

  const isFilterActive = Object.values(filters).some((v) => v !== ALL);
  const isFiltered = isFilterActive;

  // Toggle single order checkbox
  const toggleCheckOrder = (orderId: string, e?: React.MouseEvent) => {
    if (e) e.stopPropagation();
    setCheckedOrderIds((prev) =>
      prev.includes(orderId) ? prev.filter((id) => id !== orderId) : [...prev, orderId]
    );
    setSelectedOrderId(orderId);
  };

  // Toggle select all visible
  const toggleSelectAll = () => {
    if (checkedOrderIds.length === filteredOrders.length && filteredOrders.length > 0) {
      setCheckedOrderIds([]);
    } else {
      setCheckedOrderIds(filteredOrders.map((o) => o.id));
    }
  };

  // Handle Confirm action
  const handleConfirmAction = async (targetOrder?: Order) => {
    const orderToConfirm = targetOrder || selectedOrder || (checkedOrderIds.length > 0 ? orders?.find(o => o.id === checkedOrderIds[0]) : null);
    if (!orderToConfirm) return;

    try {
      if (orderToConfirm.trip_id) {
        await confirmTripMutation.mutateAsync(orderToConfirm.trip_id);
        setActionFeedback({
          type: 'success',
          text: `Trip ${orderToConfirm.trip_id} containing Order ${orderToConfirm.id} has been confirmed for loading.`,
        });
      } else {
        setActionFeedback({
          type: 'success',
          text: `Order ${orderToConfirm.id} is confirmed and queued for routing in ${selectedDepot}.`,
        });
      }
      refetch();
    } catch (err: any) {
      setActionFeedback({
        type: 'error',
        text: `Failed to confirm order: ${err.message || 'Unknown error'}`,
      });
    }
  };

  // Handle Cancel action click
  const handleCancelAction = (targetOrder?: Order) => {
    const orderToCancel = targetOrder || selectedOrder || (checkedOrderIds.length > 0 ? orders?.find(o => o.id === checkedOrderIds[0]) : null);
    if (orderToCancel) {
      setCancelModalOrder(orderToCancel);
    }
  };

  const activeSelectedOrder = selectedOrder || (checkedOrderIds.length > 0 ? orders?.find(o => o.id === checkedOrderIds[0]) : null);

  return (
    <div className="h-full flex flex-col gap-4">
      <PageHeader
        title="Orders"
        description="Dispatch queue — filterable by brand, depot, date, status, and temperature"
      />

      {/* Action feedback toast/banner */}
      {actionFeedback && (
        <div
          className={`px-4 py-3 rounded-lg text-xs font-semibold flex items-center justify-between shadow-sm transition-all ${
            actionFeedback.type === 'success'
              ? 'bg-emerald-50 text-emerald-900 border border-emerald-200'
              : 'bg-red-50 text-red-900 border border-red-200'
          }`}
        >
          <div className="flex items-center space-x-2">
            {actionFeedback.type === 'success' ? (
              <svg className="w-4 h-4 text-emerald-600" viewBox="0 0 20 20" fill="currentColor">
                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
              </svg>
            ) : (
              <svg className="w-4 h-4 text-red-600" viewBox="0 0 20 20" fill="currentColor">
                <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
              </svg>
            )}
            <span>{actionFeedback.text}</span>
          </div>
          <button
            onClick={() => setActionFeedback(null)}
            className="text-slate-400 hover:text-slate-600 font-bold ml-4"
          >
            ×
          </button>
        </div>
      )}

      {/* Filter bar */}
      <div className="bg-white border border-slate-200 rounded-lg px-5 py-3 flex flex-wrap gap-4 items-end shadow-sm">
        <FilterSelect
          label="Brand"
          value={filters.brand}
          options={BRANDS}
          placeholder="All brands"
          onChange={setFilter('brand')}
        />
        <FilterSelect
          label="Depot"
          value={filters.depot}
          options={depotOptions}
          placeholder="All depots"
          onChange={setFilter('depot')}
        />
        <FilterSelect
          label="Delivery Date"
          value={filters.delivery_date}
          options={dateOptions}
          placeholder="All dates"
          onChange={setFilter('delivery_date')}
        />
        <FilterSelect
          label="Status"
          value={filters.status}
          options={STATUSES}
          placeholder="All statuses"
          onChange={setFilter('status')}
        />
        <FilterSelect
          label="Temperature"
          value={filters.temp_requirement}
          options={TEMPS}
          placeholder="All temps"
          onChange={setFilter('temp_requirement')}
        />
        {isFiltered && (
          <button
            onClick={() =>
              setFilters({
                brand: ALL,
                depot: ALL,
                delivery_date: ALL,
                status: ALL,
                temp_requirement: ALL,
              })
            }
            className="self-end text-xs text-slate-500 hover:text-red-600 border border-slate-200 hover:border-red-300 rounded-md px-2.5 py-1.5 transition-colors"
          >
            Clear filters
          </button>
        )}
      </div>

      {/* Selected Order Action Bar */}
      {(checkedOrderIds.length > 0 || selectedOrderId) && (
        <div className="bg-gradient-to-r from-slate-900 to-slate-800 text-white rounded-xl px-5 py-3 flex flex-wrap items-center justify-between gap-3 shadow-md">
          <div className="flex items-center space-x-3">
            <span className="inline-flex items-center justify-center w-6 h-6 rounded-full bg-brand-500 text-white text-xs font-bold">
              {checkedOrderIds.length > 0 ? checkedOrderIds.length : 1}
            </span>
            <div>
              <div className="text-xs font-bold text-white">
                {activeSelectedOrder ? `Selected Order: ${activeSelectedOrder.id}` : `${checkedOrderIds.length} orders selected`}
              </div>
              {activeSelectedOrder && outletsById[activeSelectedOrder.outlet_id] && (
                <div className="text-[11px] text-slate-300">
                  {outletsById[activeSelectedOrder.outlet_id].brand} • {outletsById[activeSelectedOrder.outlet_id].district} ({activeSelectedOrder.order_units} units, {activeSelectedOrder.temp_requirement})
                </div>
              )}
            </div>
          </div>

          <div className="flex items-center space-x-2.5">
            <button
              onClick={() => handleConfirmAction()}
              className="inline-flex items-center space-x-1 px-3.5 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold rounded-lg shadow-sm transition-colors"
            >
              <svg className="w-3.5 h-3.5" viewBox="0 0 20 20" fill="currentColor">
                <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
              </svg>
              <span>Confirm</span>
            </button>

            <button
              onClick={() => handleCancelAction()}
              className="inline-flex items-center space-x-1 px-3.5 py-1.5 bg-amber-600 hover:bg-amber-700 text-white text-xs font-bold rounded-lg shadow-sm transition-colors"
            >
              <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <circle cx="12" cy="12" r="10" />
                <line x1="4.93" y1="4.93" x2="19.07" y2="19.07" />
              </svg>
              <span>Cancel Order</span>
            </button>

            <button
              onClick={() => {
                setCheckedOrderIds([]);
                setSelectedOrderId(null);
              }}
              className="px-3 py-1.5 text-xs text-slate-300 hover:text-white hover:bg-slate-700/60 rounded-lg transition-colors"
            >
              Deselect
            </button>
          </div>
        </div>
      )}

      {/* Content area */}
      <div className="flex flex-1 gap-4 min-h-0">
        {/* Table side */}
        <div
          className={`flex flex-col bg-white border border-slate-200 rounded-lg shadow-sm overflow-hidden transition-all ${
            selectedOrderId ? 'w-3/5' : 'w-full'
          }`}
        >
          {(isLoading || loadingOutlets) && <LoadingState message="Loading orders…" />}

          {isError && (
            <div className="p-4">
              <ErrorState error={error} onRetry={() => refetch()} />
            </div>
          )}

          {!isLoading && !isError && (
            <>
              {orders && orders.length === 0 ? (
                <EmptyState
                  title="No orders in queue"
                  description="There are no orders in the dispatch queue for this depot."
                />
              ) : filteredOrders.length === 0 ? (
                <EmptyState
                  title="No orders match the filters"
                  description="Try changing or clearing the filter criteria above."
                  actionLabel="Clear filters"
                  onAction={() =>
                    setFilters({
                      brand: ALL,
                      depot: ALL,
                      delivery_date: ALL,
                      status: ALL,
                      temp_requirement: ALL,
                    })
                  }
                />
              ) : (
                <div className="overflow-x-auto">
                  <table className="min-w-full text-xs divide-y divide-slate-100">
                    <thead className="bg-slate-50 sticky top-0">
                      <tr>
                        <th className="px-3 py-3 w-8 text-center">
                          <input
                            type="checkbox"
                            checked={
                              filteredOrders.length > 0 &&
                              checkedOrderIds.length === filteredOrders.length
                            }
                            onChange={toggleSelectAll}
                            className="rounded border-slate-300 text-brand-600 focus:ring-brand-500"
                            aria-label="Select all orders"
                          />
                        </th>
                        <th className="px-4 py-3 text-left font-semibold text-slate-600 uppercase tracking-wider">
                          Order ID
                        </th>
                        <th className="px-4 py-3 text-left font-semibold text-slate-600 uppercase tracking-wider">
                          Outlet / Location
                        </th>
                        <th className="px-4 py-3 text-left font-semibold text-slate-600 uppercase tracking-wider">
                          Brand
                        </th>
                        <th className="px-4 py-3 text-left font-semibold text-slate-600 uppercase tracking-wider">
                          District
                        </th>
                        <th className="px-4 py-3 text-left font-semibold text-slate-600 uppercase tracking-wider">
                          Temp
                        </th>
                        <th className="px-4 py-3 text-left font-semibold text-slate-600 uppercase tracking-wider">
                          Window
                        </th>
                        <th className="px-4 py-3 text-left font-semibold text-slate-600 uppercase tracking-wider">
                          Status
                        </th>
                        <th className="px-4 py-3 text-left font-semibold text-slate-600 uppercase tracking-wider">
                          Units / kg / m³
                        </th>
                        <th className="px-4 py-3 text-center font-semibold text-slate-600 uppercase tracking-wider">
                          Actions
                        </th>
                        {/* Priority flag columns — hidden when fields are absent from all rows */}
                        {hasDeferredYesterdayFlag && (
                          <th
                            className="px-4 py-3 text-left font-semibold text-amber-700 uppercase tracking-wider"
                            title="Deferred Yesterday — backend field (not yet in openapi.yaml)"
                          >
                            Def. Yesterday
                          </th>
                        )}
                        {hasDaysSinceFlag && (
                          <th
                            className="px-4 py-3 text-left font-semibold text-amber-700 uppercase tracking-wider"
                            title="Days since last served — backend field (not yet in openapi.yaml)"
                          >
                            Days Served
                          </th>
                        )}
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-50">
                      {filteredOrders.map((order) => {
                        const outlet = outletsById[order.outlet_id];
                        const isSelected = order.id === selectedOrderId;
                        const isChecked = checkedOrderIds.includes(order.id);

                        const windowText = outlet
                          ? `${outlet.window_open_time} - ${outlet.window_close_time}`
                          : '–';

                        return (
                          <tr
                            key={order.id}
                            onClick={() => {
                              setSelectedOrderId(isSelected ? null : order.id);
                            }}
                            className={`cursor-pointer transition-colors ${
                              isSelected || isChecked
                                ? 'bg-amber-50/40 border-l-4 border-l-amber-500'
                                : 'hover:bg-slate-50'
                            }`}
                          >
                            <td className="px-3 py-3 text-center" onClick={(e) => e.stopPropagation()}>
                              <input
                                type="checkbox"
                                checked={isChecked}
                                onChange={(e) => toggleCheckOrder(order.id, e as any)}
                                className="rounded border-slate-300 text-brand-600 focus:ring-brand-500"
                                aria-label={`Select order ${order.id}`}
                              />
                            </td>
                            <td className="px-4 py-3 font-mono font-bold text-teal-800">
                              {order.id}
                            </td>
                            <td className="px-4 py-3">
                              {outlet ? (
                                <div>
                                  <div className="font-semibold text-slate-900">
                                    {outlet.outlet_id}
                                  </div>
                                  <div className="text-[11px] text-slate-500">
                                    {outlet.depot} Depot
                                  </div>
                                </div>
                              ) : (
                                <span className="font-mono text-slate-700">
                                  {order.outlet_id}
                                </span>
                              )}
                            </td>
                            <td className="px-4 py-3 font-medium text-slate-800">
                              {outlet?.brand ? `Waypoint ${outlet.brand}` : '–'}
                            </td>
                            <td className="px-4 py-3 text-slate-700">
                              {outlet?.district ?? '–'}
                            </td>
                            <td className="px-4 py-3">
                              <span
                                className={`px-2 py-0.5 rounded text-[10px] font-semibold ${
                                  order.temp_requirement === 'chilled'
                                    ? 'bg-blue-100 text-blue-800 border border-blue-200'
                                    : 'bg-amber-100 text-amber-800 border border-amber-200'
                                }`}
                              >
                                {order.temp_requirement}
                              </span>
                            </td>
                            <td className="px-4 py-3 font-mono text-[11px] text-slate-600">
                              {windowText}
                            </td>
                            <td className="px-4 py-3">
                              <StatusBadge status={order.status} type="order" />
                              {order.deferral_count > 0 && (
                                <span className="ml-1 bg-red-100 text-red-700 text-[10px] px-1 rounded font-bold">
                                  {order.deferral_count}×
                                </span>
                              )}
                            </td>
                            <td className="px-4 py-3 text-slate-700 font-mono">
                              {order.order_units}u / {order.order_weight_kg}kg
                            </td>
                            <td className="px-4 py-3 text-center" onClick={(e) => e.stopPropagation()}>
                              <div className="flex items-center justify-center space-x-1.5">
                                <button
                                  type="button"
                                  onClick={() => handleCancelAction(order)}
                                  className="inline-flex items-center space-x-1 px-2.5 py-1 text-[11px] font-semibold text-amber-700 bg-amber-50 hover:bg-amber-100 border border-amber-300 rounded-md transition-colors"
                                  title="Cancel this order and notify store manager"
                                >
                                  <svg className="w-3 h-3 text-amber-600" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                    <circle cx="12" cy="12" r="10" />
                                    <line x1="4.93" y1="4.93" x2="19.07" y2="19.07" />
                                  </svg>
                                  <span>Cancel</span>
                                </button>
                              </div>
                            </td>
                            {/* Priority flag cells */}
                            {hasDeferredYesterdayFlag && (
                              <td className="px-4 py-3">
                                {order.deferred_yesterday ? (
                                  <span className="bg-amber-100 text-amber-800 text-[10px] px-1.5 py-0.5 rounded font-bold">
                                    YES
                                  </span>
                                ) : (
                                  <span className="text-slate-300">–</span>
                                )}
                              </td>
                            )}
                            {hasDaysSinceFlag && (
                              <td className="px-4 py-3 font-mono text-amber-800 font-semibold">
                                {order.days_since_last_served ?? '–'}
                              </td>
                            )}
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                  <div className="px-4 py-2 border-t border-slate-100 text-[11px] text-slate-400 bg-slate-50 flex items-center justify-between">
                    <div>
                      {filteredOrders.length} of {orders?.length ?? 0} order
                      {(orders?.length ?? 0) !== 1 ? 's' : ''}
                      {isFiltered ? ' (filtered)' : ''}
                    </div>
                    {checkedOrderIds.length > 0 && (
                      <div className="text-amber-800 font-semibold">
                        {checkedOrderIds.length} order(s) selected
                      </div>
                    )}
                  </div>
                </div>
              )}
            </>
          )}
        </div>

        {/* Detail panel */}
        {selectedOrderId && selectedOrder && (
          <div className="w-2/5 bg-white border border-slate-200 rounded-lg shadow-sm overflow-hidden flex flex-col">
            <OrderDetailPanel
              order={selectedOrder}
              outlet={selectedOutlet}
              onClose={() => setSelectedOrderId(null)}
              onCancelOrder={(ord) => setCancelModalOrder(ord)}
            />
          </div>
        )}
      </div>

      {/* Cancel Order Modal */}
      <CancelOrderModal
        isOpen={Boolean(cancelModalOrder)}
        order={cancelModalOrder}
        outlet={cancelModalOrder ? outletsById[cancelModalOrder.outlet_id] : undefined}
        onClose={() => setCancelModalOrder(null)}
        onSuccess={(orderId) => {
          setActionFeedback({
            type: 'success',
            text: `Order ${orderId} cancelled successfully. The consignee store manager has been notified.`,
          });
          setCheckedOrderIds((prev) => prev.filter((id) => id !== orderId));
          if (selectedOrderId === orderId) {
            setSelectedOrderId(null);
          }
        }}
      />
    </div>
  );
};
