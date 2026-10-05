import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { apiClient } from '../../../shared/api/client';
import { useAuth } from '../../../shared/auth/AuthContext';
import { useBusinessClock } from '../../../shared/hooks/useBusinessClock';
import { Store, User, Clock, AlertCircle, LogOut } from 'lucide-react';

export const StoreManagerHeader: React.FC = () => {
  const { user, logout } = useAuth();
  const { formattedClockDate, formattedClockTime, demoMode } = useBusinessClock();

  const { data: outlets } = useQuery({
    queryKey: ['ref', 'outlets'],
    queryFn: () => apiClient.getRefOutlets(),
    staleTime: Infinity,
  });

  const assignedOutlet = outlets?.find((o) => o.outlet_id === user?.outlet_id);

  return (
    <header className="sticky top-0 z-40 flex h-16 w-full items-center justify-between border-b border-brand-800 bg-brand-900 px-4 text-white shadow-md">
      {/* Brand Logo & Outlet Info (Departure 8: Displays SM Name + Outlet, NOT Driver ID) */}
      <div className="flex items-center gap-3">
        <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-brand-500 text-brand-950 font-bold">
          <Store className="h-5 w-5" />
        </div>
        <div>
          <h1 className="text-sm font-bold tracking-tight text-brand-100 flex items-center gap-1.5">
            <span>Waypoint</span>
            <span className="rounded bg-brand-800 px-1.5 py-0.5 text-[10px] uppercase font-semibold text-brand-300">
              Store Manager
            </span>
          </h1>
          <div className="flex items-center gap-2 text-xs text-brand-200">
            <span className="font-semibold text-white flex items-center gap-1">
              <User className="h-3 w-3" />
              {user?.display_name || 'Store Manager'}
            </span>
            <span>•</span>
            <span className="text-brand-300">
              {assignedOutlet
                ? `${assignedOutlet.brand} ${assignedOutlet.district} (${assignedOutlet.outlet_id})`
                : user?.outlet_id || 'OUT001'}
            </span>
          </div>
        </div>
      </div>

      {/* Business Clock & Demo Badge & Logout */}
      <div className="flex items-center gap-3">
        <div className="hidden sm:flex flex-col items-end text-xs">
          <div className="flex items-center gap-1 font-medium text-brand-100">
            <Clock className="h-3.5 w-3.5 text-brand-400" />
            <span>{formattedClockTime} Asia/Colombo</span>
          </div>
          <span className="text-[11px] text-brand-300">{formattedClockDate}</span>
        </div>

        {demoMode && (
          <span className="inline-flex items-center gap-1 rounded-full bg-amber-500/20 px-2 py-0.5 text-[10px] font-bold text-amber-300 border border-amber-500/30">
            <AlertCircle className="h-3 w-3" />
            DEMO
          </span>
        )}

        <button
          onClick={logout}
          title="Sign out or switch store"
          className="flex items-center gap-1 rounded-lg border border-brand-700 bg-brand-800/80 px-2.5 py-1.5 text-xs font-semibold text-brand-200 hover:bg-brand-700 hover:text-white transition-colors"
        >
          <LogOut className="h-3.5 w-3.5" />
          <span className="hidden md:inline">Switch Store</span>
        </button>
      </div>
    </header>
  );
};
