import React from 'react';
import { NavLink, Outlet } from 'react-router-dom';
import { StoreManagerHeader } from './StoreManagerHeader';
import { OfflineNotice } from '../../../shared/components/OfflineNotice';
import { Home, PlusCircle, Bell, Package, ChevronRight } from 'lucide-react';
import { clsx } from 'clsx';

const navItems = [
  { to: '/store', label: 'Home', icon: Home, end: true },
  { to: '/store/orders/new', label: 'New Order', icon: PlusCircle },
  { to: '/store/notifications', label: 'Notices', icon: Bell },
  { to: '/store/orders', label: 'Orders', icon: Package },
];

export const StoreManagerLayout: React.FC = () => {
  return (
    <div className="min-h-screen bg-slate-50 flex flex-col font-sans">
      {/* Offline Notice Banner (Store manager online-only) */}
      <OfflineNotice message="Connect to continue" />

      {/* Header (Departure 8) */}
      <StoreManagerHeader />

      {/* Main Layout Container */}
      <div className="flex flex-1 w-full max-w-7xl mx-auto px-0 lg:px-6 py-0 lg:py-6 gap-6">
        {/* Desktop Sidebar (>= 1024px) */}
        <aside className="hidden lg:flex w-64 flex-col gap-2 rounded-xl border border-slate-200 bg-white p-4 shadow-sm h-fit">
          <div className="px-3 py-2 text-xs font-bold uppercase tracking-wider text-slate-400">
            Navigation
          </div>
          <nav className="flex flex-col gap-1">
            {navItems.map((item) => {
              const Icon = item.icon;
              return (
                <NavLink
                  key={item.to}
                  to={item.to}
                  end={item.end}
                  className={({ isActive }) =>
                    clsx(
                      'flex items-center justify-between rounded-lg px-3 py-2.5 text-sm font-semibold transition-colors',
                      isActive
                        ? 'bg-brand-50 text-brand-900 border border-brand-200'
                        : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900'
                    )
                  }
                >
                  <div className="flex items-center gap-3">
                    <Icon className="h-5 w-5 text-brand-600" />
                    <span>
                      {item.label === 'Home'
                        ? 'Overview'
                        : item.label === 'New Order'
                          ? 'Create Order'
                          : item.label === 'Notices'
                            ? 'Alerts'
                            : item.label}
                    </span>
                  </div>
                  <ChevronRight className="h-4 w-4 text-slate-400" />
                </NavLink>
              );
            })}
          </nav>

          <div className="mt-6 border-t border-slate-100 pt-4 px-3 text-xs text-slate-500">
            <p className="font-semibold text-slate-700">Cutoff Policy</p>
            <p className="mt-1">Orders for next-day delivery close daily at 16:00 (D-1).</p>
          </div>
        </aside>

        {/* Content Area (Mobile full-width / Desktop two-column flexible) */}
        <main className="flex-1 w-full pb-20 lg:pb-0">
          <Outlet />
        </main>
      </div>

      {/* Mobile Bottom Navigation Bar (390px Mobile-first) */}
      <nav
        data-testid="bottom-navigation"
        className="lg:hidden fixed bottom-0 left-0 right-0 z-40 flex h-16 w-full items-center justify-around border-t border-slate-200 bg-white shadow-lg"
      >
        {navItems.map((item) => {
          const Icon = item.icon;
          return (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.end}
              className={({ isActive }) =>
                clsx(
                  'flex flex-col items-center justify-center gap-1 w-full h-full text-[11px] font-semibold transition-colors',
                  isActive ? 'text-brand-700 font-bold' : 'text-slate-500 hover:text-slate-800'
                )
              }
            >
              <Icon className="h-5 w-5" />
              <span>{item.label}</span>
            </NavLink>
          );
        })}
      </nav>
    </div>
  );
};
