import React from 'react';
import { PageHeader } from '../components/PageHeader';
import { LoadingState } from '../components/LoadingState';
import { ErrorState } from '../components/ErrorState';
import { useGetDashboard, useListAlerts } from '../api/generated/dispatcher/dispatcher';
import { AlertItem } from '../api/generated/models/alertItem';
import { useAuth } from '../context/AuthContext';
import { useNavigate } from 'react-router-dom';

/**
 * Dashboard (P1) – dispatcher overview.
 * Shows orders summary, planning progress, vehicle states, active trips, and alerts.
 * Cutoff countdown uses the server-provided `minutes_remaining` (no browser clock).
 */
export const DashboardPage: React.FC = () => {
  const navigate = useNavigate();
  const { selectedDepot } = useAuth();

  // Live dashboard summary data (GET /dashboard?depot_id=...)
  const dashboardQuery = useGetDashboard(selectedDepot ? { depot_id: selectedDepot } : undefined);

  // Live alerts list (GET /alerts?depot_id=...)
  const alertsQuery = useListAlerts(selectedDepot ? { depot_id: selectedDepot } : undefined);

  if (dashboardQuery.isLoading || alertsQuery.isLoading) return <LoadingState />;
  if (dashboardQuery.isError) return <ErrorState error={dashboardQuery.error as any} />;
  if (alertsQuery.isError) return <ErrorState error={alertsQuery.error as any} />;

  const data = dashboardQuery.data!;
  const alerts = alertsQuery.data ?? [];

  const renderAlert = (alert: AlertItem) => {
    const handleClick = () => {
      switch (alert.type) {
        case 'shortfall':
          navigate('/loading');
          break;
        case 'exception':
        case 'sync_conflict':
          navigate('/monitoring');
          break;
        case 'repeat_deferral':
          navigate('/deferred');
          break;
        default:
          break;
      }
    };
    return (
      <div
        key={alert.id}
        className="p-3 border rounded-lg cursor-pointer bg-amber-50/50 border-amber-200 hover:bg-amber-100/50 transition-colors"
        onClick={handleClick}
      >
        <div className="flex items-center justify-between">
          <div className="font-semibold text-xs text-amber-900 capitalize">
            {alert.type?.replace(/_/g, ' ')}
          </div>
          <span
            className={`text-[10px] px-1.5 py-0.5 rounded font-medium ${
              alert.severity === 'critical'
                ? 'bg-red-100 text-red-800'
                : alert.severity === 'warning'
                ? 'bg-amber-100 text-amber-800'
                : 'bg-blue-100 text-blue-800'
            }`}
          >
            {alert.severity}
          </span>
        </div>
        <div className="text-xs text-slate-700 mt-1">{alert.message}</div>
      </div>
    );
  };

  //const cutoffPassed = data.cutoff?.passed || (data.cutoff?.minutes_remaining ?? 0) <= 0;

  return (
    <div className="space-y-4">
      <PageHeader
        title="Dispatcher Dashboard"
        description={`Overview metrics and live operational status for ${selectedDepot || 'All Depots'}`}
      />

      {/* Cutoff countdown */}
      {/* <div className="px-4 py-3 bg-white border border-slate-200 rounded-lg shadow-sm flex items-center justify-between">
        <h3 className="text-xs uppercase tracking-wider text-slate-500 font-semibold">
          Order Cutoff Status
        </h3>
        {cutoffPassed ? (
          <span className="text-xs text-red-600 font-bold px-2 py-0.5 bg-red-50 rounded">
            Cutoff Passed (14:00)
          </span>
        ) : (
          <span className="text-xs text-emerald-700 font-bold px-2 py-0.5 bg-emerald-50 rounded">
            {data.cutoff?.minutes_remaining} minute(s) remaining until 14:00 cutoff
          </span>
        )}
      </div> */}

      {/* Summary cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        {/* Orders */}
        <div className="p-4 bg-white border border-slate-200 rounded-lg shadow-sm">
          <h4 className="text-xs uppercase tracking-wider text-slate-500 font-semibold">
            Total Orders
          </h4>
          <p className="text-3xl font-extrabold text-slate-900 mt-1">
            {data.orders?.total ?? 0}
          </p>
          <p className="text-xs text-slate-500 mt-0.5">
            {data.orders?.unassigned ?? 0} awaiting planning
          </p>
          <ul className="mt-3 pt-3 border-t border-slate-100 text-xs text-slate-600 space-y-1">
            {Object.entries(data.orders?.by_brand ?? {}).map(([brand, cnt]) => (
              <li key={brand} className="flex justify-between font-medium">
                <span>{brand}</span>
                <span className="text-slate-900 font-semibold">{cnt}</span>
              </li>
            ))}
          </ul>
        </div>

        {/* Planning progress */}
        <div className="p-4 bg-white border border-slate-200 rounded-lg shadow-sm">
          <h4 className="text-xs uppercase tracking-wider text-slate-500 font-semibold">
            Planning Progress
          </h4>
          <p className="text-3xl font-extrabold text-brand-600 mt-1">
            {data.planning_progress?.planned ?? 0}
          </p>
          <p className="text-xs text-slate-500 mt-0.5">
            of {data.planning_progress?.total ?? 0} trips confirmed
          </p>
          <div className="h-2 bg-slate-100 rounded-full mt-4 overflow-hidden">
            <div
              className="h-full bg-brand-500 rounded-full transition-all duration-500"
              style={{
                width: `${Math.round(
                  ((data.planning_progress?.planned ?? 0) /
                    Math.max(data.planning_progress?.total ?? 1, 1)) *
                    100
                )}%`,
              }}
            />
          </div>
        </div>

        {/* Vehicles */}
        <div className="p-4 bg-white border border-slate-200 rounded-lg shadow-sm">
          <h4 className="text-xs uppercase tracking-wider text-slate-500 font-semibold">
            Fleet Status
          </h4>
          <p className="text-3xl font-extrabold text-slate-900 mt-1">
            {data.vehicles?.total ?? 0}
          </p>
          <div className="grid grid-cols-2 gap-2 mt-3 text-xs text-slate-600">
            <div className="p-1.5 bg-slate-50 rounded">
              Available <b className="text-slate-900 block font-semibold">{data.vehicles?.available ?? 0}</b>
            </div>
            <div className="p-1.5 bg-emerald-50 rounded">
              Active <b className="text-emerald-700 block font-semibold">{data.vehicles?.active ?? 0}</b>
            </div>
            <div className="p-1.5 bg-amber-50 rounded">
              Loading <b className="text-amber-800 block font-semibold">{data.vehicles?.loading ?? 0}</b>
            </div>
            <div className="p-1.5 bg-blue-50 rounded">
              Allocated <b className="text-blue-800 block font-semibold">{data.vehicles?.allocated ?? 0}</b>
            </div>
          </div>
        </div>

        {/* Active trips */}
        <div className="p-4 bg-white border border-slate-200 rounded-lg shadow-sm">
          <h4 className="text-xs uppercase tracking-wider text-slate-500 font-semibold">
            Active Trips
          </h4>
          {(data.active_trips ?? []).length === 0 ? (
            <p className="text-xs text-slate-400 mt-3">No active trips currently in transit</p>
          ) : (
            <div className="mt-2 space-y-2 max-h-36 overflow-y-auto">
              {(data.active_trips ?? []).map((tripItem) => (
                <div key={tripItem.trip?.id} className="pb-2 border-b border-slate-100 last:border-0">
                  <p className="font-semibold text-xs text-slate-800">Trip {tripItem.trip?.id}</p>
                  <p className="text-[11px] text-slate-500">
                    {tripItem.stops_completed ?? 0} / {tripItem.stops_total ?? 0} stops completed
                  </p>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Alerts */}
        <div className="p-4 bg-white border border-slate-200 rounded-lg shadow-sm xl:col-span-4">
          <div className="flex items-center justify-between mb-3">
            <h4 className="text-xs uppercase tracking-wider text-slate-500 font-semibold">
              Live Alerts & Exceptions
            </h4>
            <span className="text-xs bg-slate-100 text-slate-700 px-2 py-0.5 rounded font-medium">
              {alerts.length} Active
            </span>
          </div>
          {alerts.length === 0 ? (
            <p className="text-xs text-slate-400 py-3 text-center bg-slate-50 rounded">
              No operational alerts currently open. All systems running normally.
            </p>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
              {alerts.map(renderAlert)}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
