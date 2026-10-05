import React from 'react';
import { useAuth } from '../context/AuthContext';
import { useBusinessNow } from '../hooks/useBusinessNow';
import { useLiveEvents } from '../hooks/useLiveEvents';
import { formatColomboDateTime } from '../lib/time';

export const Header: React.FC = () => {
  const {
    user,
    depotIds,
    selectedDepot,
    setSelectedDepot,
    deliveryDate,
    setDeliveryDate,
    logout,
  } = useAuth();

  const { businessNow } = useBusinessNow();
  const { connectionStatus } = useLiveEvents();

  const getStatusBadge = () => {
    switch (connectionStatus) {
      case 'online':
        return (
          <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-semibold bg-emerald-100 text-emerald-800 border border-emerald-200">
            <span className="w-2 h-2 bg-emerald-500 rounded-full mr-1.5 animate-pulse" />
            Online (SSE)
          </span>
        );
      case 'polling':
        return null;
      case 'disconnected':
      default:
        return (
          <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-semibold bg-rose-100 text-rose-800 border border-rose-200">
            <span className="w-2 h-2 bg-rose-500 rounded-full mr-1.5" />
            Disconnected
          </span>
        );
    }
  };

  return (
    <header className="bg-white text-slate-900 border-b border-slate-200 px-5 py-2 flex flex-wrap items-center justify-between gap-3">
      <div className="flex items-center space-x-4 min-w-0">
        {/* Depot Selector */}
        <div className="flex items-center space-x-2">
          <label htmlFor="header-depot" className="text-[10px] text-slate-500 font-medium">
            Depot:
          </label>
          <select
            id="header-depot"
            value={selectedDepot}
            onChange={(e) => setSelectedDepot(e.target.value)}
            className="bg-white text-slate-800 text-[10px] border-0 border-b border-slate-300 rounded-none px-1 py-0.5 focus:outline-none focus:ring-1 focus:ring-brand-500 font-medium"
          >
            {depotIds.map((depot) => (
              <option key={depot} value={depot}>
                {depot} Depot
              </option>
            ))}
          </select>
        </div>

        {/* Delivery Date Picker */}
        <div className="flex items-center space-x-2">
          <label htmlFor="header-date" className="text-[10px] text-slate-500 font-medium">
            Delivery Date:
          </label>
          <input
            id="header-date"
            type="date"
            value={deliveryDate}
            onChange={(e) => setDeliveryDate(e.target.value)}
            className="bg-white text-slate-800 text-[10px] border-0 border-b border-slate-300 rounded-none px-1 py-0.5 focus:outline-none focus:ring-1 focus:ring-brand-500 font-mono"
          />
        </div>

        {/* Connection Status */}
        {getStatusBadge()}

      </div>

      <div className="flex items-center space-x-4">
        {/* Business Clock Display */}
        <div className="hidden xl:block text-xs text-slate-400">
          Clock:{' '}
          <span className="font-mono text-slate-200">
            {formatColomboDateTime(businessNow)}
          </span>
        </div>

        {/* User Info & Logout */}
        <div className="flex items-center space-x-3">
          <div className="text-xs text-right">
            <div className="font-semibold text-slate-800">{user?.display_name || user?.username}</div>
            <div className="text-brand-700 text-[9px] uppercase font-bold tracking-wide">
              {user?.role || 'dispatcher'}
            </div>
          </div>
          <button
            onClick={logout}
            className="text-[10px] bg-white hover:bg-slate-50 text-slate-600 border border-slate-300 rounded px-2 py-1 transition-colors"
          >
            Logout
          </button>
        </div>
      </div>
    </header>
  );
};
