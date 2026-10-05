import React, { useMemo, useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { PageHeader } from '../components/PageHeader';
import { LoadingState } from '../components/LoadingState';
import { EmptyState } from '../components/EmptyState';
import { useListDeferrals, useRequeueOrder } from '../api/generated/dispatcher/dispatcher';
import { useOutletMap } from '../hooks/useOutletMap';
import { useAuth } from '../context/AuthContext';
import { customInstance } from '../api/http';

export const DeferredPage: React.FC = () => {
  const { selectedDepot, deliveryDate } = useAuth();
  const queryClient = useQueryClient();
  const { outletsById } = useOutletMap();

  const { data, isLoading, isError, refetch } = useListDeferrals(
    selectedDepot ? { depot_id: selectedDepot } : undefined
  );

  const requeueMutation = useRequeueOrder();
  const [activeMessage, setActiveMessage] = useState<{
    type: 'success' | 'info' | 'error';
    text: string;
  } | null>(null);

  // Filters and Search state
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'deferred' | 'requeued' | 'planned'>('all');
  const [brandFilter, setBrandFilter] = useState<string>('all');
  const [tempFilter, setTempFilter] = useState<string>('all');
  const [checkedOrderIds, setCheckedOrderIds] = useState<string[]>([]);
  const [isBatchRequeuing, setIsBatchRequeuing] = useState(false);

  const rawDeferrals = data ?? [];

  // Deduplicate deferrals by order_id, keeping the latest decided deferral for each order
  const latestDeferrals = useMemo(() => {
    const map = new Map<string, any>();
    for (const d of rawDeferrals) {
      const orderKey = d.order_id || d.id;
      if (!map.has(orderKey)) {
        map.set(orderKey, d);
      } else {
        const existing = map.get(orderKey);
        const existingTime = new Date(existing.decided_at || existing.created_at || 0).getTime();
        const currentTime = new Date(d.decided_at || d.created_at || 0).getTime();
        if (currentTime > existingTime) {
          map.set(orderKey, d);
        }
      }
    }
    return Array.from(map.values());
  }, [rawDeferrals]);

  // Aggregate Metrics
  const metrics = useMemo(() => {
    let awaitingRequeue = 0;
    let requeued = 0;
    let planned = 0;

    latestDeferrals.forEach((d) => {
      const status = d.order_status || (d.is_requeued ? 'SUBMITTED' : 'DEFERRED');
      if (status === 'DEFERRED') {
        awaitingRequeue++;
      } else if (status === 'SUBMITTED' || d.is_requeued) {
        requeued++;
      } else if (['PLANNED', 'SCHEDULED', 'LOADED', 'IN_TRANSIT', 'DELIVERED'].includes(status)) {
        planned++;
      } else {
        awaitingRequeue++;
      }
    });

    return {
      total: latestDeferrals.length,
      awaitingRequeue,
      requeued,
      planned,
    };
  }, [latestDeferrals]);

  // Filter deferrals
  const filteredDeferrals = useMemo(() => {
    return latestDeferrals.filter((d) => {
      const outlet = d.outlet_id ? outletsById[d.outlet_id] : null;
      const brand = d.brand || outlet?.brand || '';
      const status = d.order_status || (d.is_requeued ? 'SUBMITTED' : 'DEFERRED');

      // Status filter
      if (statusFilter === 'deferred' && status !== 'DEFERRED') return false;
      if (statusFilter === 'requeued' && status !== 'SUBMITTED' && !d.is_requeued) return false;
      if (statusFilter === 'planned' && !['PLANNED', 'SCHEDULED', 'LOADED', 'IN_TRANSIT', 'DELIVERED'].includes(status)) return false;

      // Brand filter
      if (brandFilter !== 'all' && brand.toLowerCase() !== brandFilter.toLowerCase()) return false;

      // Temperature filter
      if (tempFilter !== 'all' && d.temp_requirement?.toLowerCase() !== tempFilter.toLowerCase()) return false;

      // Search term
      if (searchTerm.trim()) {
        const term = searchTerm.toLowerCase();
        const matchesId = (d.order_id || d.id || '').toLowerCase().includes(term);
        const matchesOutlet = (d.outlet_id || '').toLowerCase().includes(term) || (outlet?.display_name || '').toLowerCase().includes(term);
        const matchesReason = (d.reason_text || '').toLowerCase().includes(term) || (d.reason_code || '').toLowerCase().includes(term);
        if (!matchesId && !matchesOutlet && !matchesReason) return false;
      }

      return true;
    });
  }, [latestDeferrals, outletsById, statusFilter, brandFilter, tempFilter, searchTerm]);

  // Handle single order re-queue
  const handleRequeue = async (orderId: string) => {
    try {
      await requeueMutation.mutateAsync(orderId);
      setActiveMessage({
        type: 'success',
        text: `Order #${orderId} successfully re-queued! It is now active in the dispatch queue for the next plan generation.`,
      });
      // Invalidate all related caches
      queryClient.invalidateQueries({ queryKey: ['/deferrals'] });
      queryClient.invalidateQueries({ queryKey: ['/dispatch/queue'] });
      queryClient.invalidateQueries({ queryKey: ['unplannedOrders'] });
      queryClient.invalidateQueries({ queryKey: ['planningTrips'] });
      refetch();
    } catch (err: any) {
      const msg = err?.response?.data?.message || err?.message || 'Unknown error';
      setActiveMessage({
        type: 'error',
        text: `Failed to re-queue Order #${orderId}: ${msg}`,
      });
    }
  };

  // Handle batch re-queue of selected orders
  const handleBatchRequeue = async () => {
    if (checkedOrderIds.length === 0) return;
    setIsBatchRequeuing(true);
    try {
      await customInstance<any>({
        url: '/deferrals/requeue',
        method: 'POST',
        data: { order_ids: checkedOrderIds },
      });

      setActiveMessage({
        type: 'success',
        text: `Successfully re-queued ${checkedOrderIds.length} order(s) into the planning queue!`,
      });
      setCheckedOrderIds([]);
      queryClient.invalidateQueries({ queryKey: ['/deferrals'] });
      queryClient.invalidateQueries({ queryKey: ['/dispatch/queue'] });
      queryClient.invalidateQueries({ queryKey: ['unplannedOrders'] });
      queryClient.invalidateQueries({ queryKey: ['planningTrips'] });
      refetch();
    } catch (err: any) {
      // Fallback: requeue sequentially if batch route is unreachable
      try {
        for (const orderId of checkedOrderIds) {
          await requeueMutation.mutateAsync(orderId);
        }
        setActiveMessage({
          type: 'success',
          text: `Successfully re-queued ${checkedOrderIds.length} order(s) into the planning queue!`,
        });
        setCheckedOrderIds([]);
        refetch();
      } catch (innerErr: any) {
        setActiveMessage({
          type: 'error',
          text: `Failed to batch re-queue orders: ${innerErr?.message || 'Unknown error'}`,
        });
      }
    } finally {
      setIsBatchRequeuing(false);
    }
  };

  // Checkbox toggle logic
  const toggleCheckOrder = (orderId: string) => {
    setCheckedOrderIds((prev) =>
      prev.includes(orderId) ? prev.filter((id) => id !== orderId) : [...prev, orderId]
    );
  };

  const toggleSelectAll = () => {
    const selectable = filteredDeferrals
      .filter((d) => (d.order_status || (d.is_requeued ? 'SUBMITTED' : 'DEFERRED')) === 'DEFERRED')
      .map((d) => d.order_id || d.id);

    if (checkedOrderIds.length === selectable.length && selectable.length > 0) {
      setCheckedOrderIds([]);
    } else {
      setCheckedOrderIds(selectable);
    }
  };

  if (isLoading) return <LoadingState />;
  if (isError)
    return (
      <EmptyState
        title="Error loading deferrals"
        description="Could not connect to deferral records."
      />
    );

  return (
    <div className="space-y-6">
      <PageHeader
        title="Deferred Orders Queue"
        description={`Audit trail and re-queue console for deferred or rolled-over deliveries (${selectedDepot})`}
      />

      {/* Top Metrics Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm flex items-center justify-between">
          <div>
            <p className="text-[11px] font-bold uppercase tracking-wider text-slate-500">Total Deferrals</p>
            <h3 className="text-xl font-extrabold text-slate-900 mt-1">{metrics.total}</h3>
          </div>
          <div className="w-10 h-10 rounded-xl bg-slate-100 flex items-center justify-center text-slate-600">
            <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z" />
              <polyline points="14 2 14 8 20 8" />
              <line x1="16" y1="13" x2="8" y2="13" />
              <line x1="16" y1="17" x2="8" y2="17" />
              <polyline points="10 9 9 9 8 9" />
            </svg>
          </div>
        </div>

        <div className="bg-white p-4 rounded-xl border border-amber-200 shadow-sm flex items-center justify-between bg-amber-50/20">
          <div>
            <p className="text-[11px] font-bold uppercase tracking-wider text-amber-800">Awaiting Re-queue</p>
            <h3 className="text-xl font-extrabold text-amber-900 mt-1">{metrics.awaitingRequeue}</h3>
          </div>
          <div className="w-10 h-10 rounded-xl bg-amber-100 flex items-center justify-center text-amber-700">
            <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <circle cx="12" cy="12" r="10" />
              <polyline points="12 6 12 12 16 14" />
            </svg>
          </div>
        </div>

        <div className="bg-white p-4 rounded-xl border border-emerald-200 shadow-sm flex items-center justify-between bg-emerald-50/20">
          <div>
            <p className="text-[11px] font-bold uppercase tracking-wider text-emerald-800">Re-queued (Pending Run)</p>
            <h3 className="text-xl font-extrabold text-emerald-900 mt-1">{metrics.requeued}</h3>
          </div>
          <div className="w-10 h-10 rounded-xl bg-emerald-100 flex items-center justify-center text-emerald-700">
            <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2" />
            </svg>
          </div>
        </div>

        <div className="bg-white p-4 rounded-xl border border-blue-200 shadow-sm flex items-center justify-between bg-blue-50/20">
          <div>
            <p className="text-[11px] font-bold uppercase tracking-wider text-blue-800">Planned on Route</p>
            <h3 className="text-xl font-extrabold text-blue-900 mt-1">{metrics.planned}</h3>
          </div>
          <div className="w-10 h-10 rounded-xl bg-blue-100 flex items-center justify-center text-blue-700">
            <svg className="w-5 h-5" viewBox="0 0 20 20" fill="currentColor">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
            </svg>
          </div>
        </div>
      </div>

      {/* Notifications / Toast Banner */}
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

      {/* Filter and Search Bar */}
      <div className="bg-white border border-slate-200 rounded-xl p-4 shadow-sm space-y-3">
        <div className="flex flex-wrap items-center justify-between gap-3">
          {/* Search box */}
          <div className="flex-1 min-w-[240px] relative">
            <input
              type="text"
              placeholder="Search by Order ID, outlet, or reason code..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-9 pr-3 py-1.5 text-xs border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-brand-500 bg-slate-50/50"
            />
            <svg
              className="w-4 h-4 text-slate-400 absolute left-3 top-2"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
              />
            </svg>
          </div>

          {/* Quick Filter dropdowns */}
          <div className="flex flex-wrap items-center gap-2">
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value as any)}
              className="text-xs px-2.5 py-1.5 border border-slate-300 rounded-lg bg-white focus:ring-2 focus:ring-brand-500"
            >
              <option value="all">All Lifecycle States</option>
              <option value="deferred">Awaiting Re-queue ({metrics.awaitingRequeue})</option>
              <option value="requeued">Re-queued for Next Plan ({metrics.requeued})</option>
              <option value="planned">Planned on Route ({metrics.planned})</option>
            </select>

            <select
              value={brandFilter}
              onChange={(e) => setBrandFilter(e.target.value)}
              className="text-xs px-2.5 py-1.5 border border-slate-300 rounded-lg bg-white focus:ring-2 focus:ring-brand-500"
            >
              <option value="all">All Brands</option>
              <option value="Fresh">Waypoint Fresh</option>
              <option value="Style">Waypoint Style</option>
              <option value="Tech">Waypoint Tech</option>
            </select>

            <select
              value={tempFilter}
              onChange={(e) => setTempFilter(e.target.value)}
              className="text-xs px-2.5 py-1.5 border border-slate-300 rounded-lg bg-white focus:ring-2 focus:ring-brand-500"
            >
              <option value="all">All Temperatures</option>
              <option value="ambient">Ambient</option>
              <option value="chilled">Chilled 2°C</option>
            </select>
          </div>
        </div>

        {/* Batch Selection Action Bar */}
        {checkedOrderIds.length > 0 && (
          <div className="pt-3 border-t border-slate-100 flex flex-wrap items-center justify-between gap-3 bg-brand-50/50 p-2.5 rounded-lg">
            <div className="flex items-center space-x-2">
              <span className="w-5 h-5 rounded-full bg-brand-600 text-white text-xs font-bold flex items-center justify-center">
                {checkedOrderIds.length}
              </span>
              <span className="text-xs font-bold text-brand-900">
                {checkedOrderIds.length} deferred order(s) selected
              </span>
            </div>

            <div className="flex items-center space-x-2">
              <button
                type="button"
                onClick={handleBatchRequeue}
                disabled={isBatchRequeuing || requeueMutation.isPending}
                className="inline-flex items-center space-x-1.5 px-4 py-1.5 bg-gradient-to-r from-brand-600 to-indigo-600 hover:from-brand-700 hover:to-indigo-700 text-white text-xs font-bold rounded-lg shadow-sm transition-all disabled:opacity-50"
              >
                {isBatchRequeuing ? (
                  <>
                    <svg className="w-3.5 h-3.5 animate-spin" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
                    </svg>
                    <span>Re-queueing...</span>
                  </>
                ) : (
                  <>
                    <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                      <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2" />
                    </svg>
                    <span>Re-queue Selected ({checkedOrderIds.length}) into Next Plan</span>
                  </>
                )}
              </button>

              <button
                type="button"
                onClick={() => setCheckedOrderIds([])}
                className="px-3 py-1.5 text-xs text-slate-600 hover:text-slate-900 hover:bg-slate-200/60 rounded-lg transition-colors"
              >
                Deselect
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Main Deferred Orders List */}
      {filteredDeferrals.length === 0 ? (
        <div className="bg-white border border-slate-200 rounded-xl p-10 text-center shadow-sm">
          <div className="w-12 h-12 bg-emerald-50 rounded-full flex items-center justify-center mx-auto mb-3 text-emerald-600">
            <svg className="w-6 h-6" viewBox="0 0 20 20" fill="currentColor">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
            </svg>
          </div>
          <h3 className="text-base font-bold text-slate-800">
            {searchTerm || statusFilter !== 'all' || brandFilter !== 'all'
              ? 'No matching deferrals found'
              : `No Deferred Orders for ${selectedDepot}`}
          </h3>
          <p className="text-xs text-slate-500 mt-1 max-w-md mx-auto">
            {searchTerm || statusFilter !== 'all' || brandFilter !== 'all'
              ? 'Try changing or clearing your search and filter criteria.'
              : `All submitted customer orders for ${selectedDepot} are currently scheduled on active routes.`}
          </p>
        </div>
      ) : (
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {filteredDeferrals.map((d) => {
            const orderId = d.order_id || d.id;
            const outlet = d.outlet_id ? outletsById[d.outlet_id] : null;
            const brand = d.brand || outlet?.brand || 'Fresh';
            const district = d.district || outlet?.district || selectedDepot;
            const status = d.order_status || (d.is_requeued ? 'SUBMITTED' : 'DEFERRED');
            const isRequeued = status === 'SUBMITTED' || d.is_requeued === true;
            const isPlanned = ['PLANNED', 'SCHEDULED', 'LOADED', 'IN_TRANSIT', 'DELIVERED'].includes(status);
            const isAwaiting = status === 'DEFERRED';
            const isChecked = checkedOrderIds.includes(orderId);
            const deferralCount = d.deferral_count || 1;

            return (
              <div
                key={d.id || orderId}
                className={`p-5 bg-white border rounded-xl shadow-sm flex flex-col justify-between transition-all hover:shadow-md ${
                  isChecked
                    ? 'border-brand-500 ring-2 ring-brand-500/20 bg-brand-50/20'
                    : isRequeued
                    ? 'border-emerald-200 bg-emerald-50/10'
                    : isPlanned
                    ? 'border-blue-200 bg-blue-50/10'
                    : 'border-slate-200 hover:border-slate-300'
                }`}
              >
                <div>
                  {/* Card Header with Checkbox & Status Badges */}
                  <div className="flex items-start justify-between gap-2 pb-3 border-b border-slate-100">
                    <div className="flex items-center space-x-2.5">
                      {isAwaiting && (
                        <input
                          type="checkbox"
                          checked={isChecked}
                          onChange={() => toggleCheckOrder(orderId)}
                          className="rounded border-slate-300 text-brand-600 focus:ring-brand-500 cursor-pointer"
                        />
                      )}
                      <div>
                        <span className="font-mono font-bold text-slate-900 text-sm">
                          {`#${orderId}`}
                        </span>
                        <div className="text-[11px] text-slate-500 font-medium">
                          {outlet?.display_name || (d.outlet_id ? `Outlet ${d.outlet_id}` : 'Customer Outlet')}
                        </div>
                      </div>
                    </div>

                    <div className="flex flex-col items-end gap-1">
                      {/* Lifecycle Badge */}
                      {isAwaiting && (
                        <span className="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-100 text-amber-900 border border-amber-200">
                          ⏳ Awaiting Re-queue
                        </span>
                      )}
                      {isRequeued && (
                        <span className="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-100 text-emerald-900 border border-emerald-200">
                          🚀 Re-queued (Pending Plan)
                        </span>
                      )}
                      {isPlanned && (
                        <span className="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold bg-blue-100 text-blue-900 border border-blue-200">
                          ✓ Planned on Route
                        </span>
                      )}

                      {deferralCount > 1 && (
                        <span className="text-[9px] font-extrabold px-1.5 py-0.2 bg-red-100 text-red-700 rounded">
                          {deferralCount}× Consecutive Deferrals
                        </span>
                      )}
                    </div>
                  </div>

                  {/* Outlet & Brand details */}
                  <div className="mt-3 flex flex-wrap items-center gap-1.5 text-[11px]">
                    <span className="px-2 py-0.5 rounded font-bold bg-slate-100 text-slate-800">
                      Waypoint {brand}
                    </span>
                    <span className="px-2 py-0.5 rounded font-medium bg-slate-100 text-slate-700">
                      {district}
                    </span>
                    <span
                      className={`px-2 py-0.5 rounded font-bold ${
                        d.temp_requirement === 'chilled'
                          ? 'bg-blue-100 text-blue-800 border border-blue-200'
                          : 'bg-amber-100 text-amber-800 border border-amber-200'
                      }`}
                    >
                      {d.temp_requirement === 'chilled' ? 'Chilled 2°C' : 'Ambient'}
                    </span>
                    {d.order_units && (
                      <span className="text-slate-500 font-mono">
                        {d.order_units}u • {d.order_weight_kg}kg • {d.order_volume_m3}m³
                      </span>
                    )}
                  </div>

                  {/* Deferral Reason & Diagnostics Box */}
                  <div className="mt-3 p-3 bg-slate-50 border border-slate-100 rounded-xl space-y-1.5">
                    <div className="flex items-center justify-between text-[11px]">
                      <span className="font-bold text-slate-700 font-mono uppercase">
                        {d.reason_code || 'UNAVOIDABLE'}
                      </span>
                      <span
                        className={`text-[9px] uppercase font-extrabold px-1.5 py-0.5 rounded ${
                          d.reason_class === 'UNAVOIDABLE'
                            ? 'bg-slate-200 text-slate-800'
                            : d.reason_class === 'CHOICE'
                            ? 'bg-blue-100 text-blue-800'
                            : 'bg-amber-100 text-amber-800'
                        }`}
                      >
                        {d.reason_class || 'OPERATIONAL'}
                      </span>
                    </div>

                    <p className="text-xs text-slate-800 font-medium leading-relaxed">
                      {d.reason_text}
                    </p>

                    {d.consequence_text && (
                      <p className="text-[11px] text-slate-500 italic">
                        ↳ {d.consequence_text}
                      </p>
                    )}

                    <div className="pt-2 border-t border-slate-200/60 flex items-center justify-between text-[10px] text-slate-400 font-mono">
                      <span>Decided by: {d.decided_by || 'optimization engine'}</span>
                      <span>
                        {d.decided_at || d.created_at
                          ? new Date(d.decided_at || d.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
                          : '–'}
                      </span>
                    </div>
                  </div>
                </div>

                {/* Card Action Footer */}
                <div className="mt-4 pt-3 border-t border-slate-100">
                  {isAwaiting && (
                    <button
                      className="w-full bg-gradient-to-r from-brand-600 to-teal-600 hover:from-brand-700 hover:to-teal-700 text-white text-xs font-bold py-2 px-3 rounded-xl shadow-sm transition-all flex items-center justify-center space-x-1.5 disabled:opacity-50"
                      onClick={() => handleRequeue(orderId)}
                      disabled={requeueMutation.isPending}
                    >
                      {requeueMutation.isPending ? (
                        <>
                          <svg className="w-3.5 h-3.5 animate-spin" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
                          </svg>
                          <span>Re-queuing...</span>
                        </>
                      ) : (
                        <>
                          <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                            <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2" />
                          </svg>
                          <span>Re-queue into Next Plan</span>
                        </>
                      )}
                    </button>
                  )}

                  {isRequeued && (
                    <div className="space-y-1 text-center">
                      <button
                        disabled
                        className="w-full bg-emerald-50 text-emerald-800 border border-emerald-300 text-xs font-bold py-2 px-3 rounded-xl cursor-default flex items-center justify-center space-x-1.5 shadow-sm"
                      >
                        <svg className="w-4 h-4 text-emerald-600" viewBox="0 0 20 20" fill="currentColor">
                          <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                        </svg>
                        <span>✓ Re-queued (Pending Plan Run)</span>
                      </button>
                      <p className="text-[10px] text-slate-500 font-medium">
                        Click "Generate Plan" in Planning Screen to allocate.
                      </p>
                    </div>
                  )}

                  {isPlanned && (
                    <button
                      disabled
                      className="w-full bg-blue-50 text-blue-800 border border-blue-200 text-xs font-bold py-2 px-3 rounded-xl cursor-default flex items-center justify-center space-x-1.5"
                    >
                      <svg className="w-4 h-4 text-blue-600" viewBox="0 0 20 20" fill="currentColor">
                        <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                      </svg>
                      <span>✓ Assigned to Active Trip</span>
                    </button>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};
