import React from 'react';
import { NavLink } from 'react-router-dom';

export const Sidebar: React.FC = () => {
  const navItems = [
    { label: 'Dashboard', path: '/' },
    { label: 'Orders', path: '/orders' },
    { label: 'Planning', path: '/planning' },
    { label: 'Deferred', path: '/deferred' },
    { label: 'Loading Coordination', path: '/loading' },
    { label: 'Live Monitoring', path: '/monitoring' },
  ];

  return (
    <aside className="w-40 lg:w-44 bg-white text-slate-700 min-h-screen flex flex-col border-r border-slate-200 shrink-0">
      <div className="px-4 py-3 border-b border-slate-200">
        <div className="flex items-center space-x-2">
          <span className="bg-brand-700 text-white font-black text-sm px-1.5 py-1 rounded">
            W
          </span>
          <div>
            <div className="font-bold text-slate-900 tracking-tight text-sm">Waypoint</div>
            <div className="text-[8px] text-brand-700 tracking-wider uppercase font-bold">
              Fleet Dispatch
            </div>
          </div>
        </div>
      </div>

      <nav className="flex-1 px-0 py-2 space-y-0.5">
        {navItems.map((item) => (
          <NavLink
            key={item.path}
            to={item.path}
            end={item.path === '/'}
            className={({ isActive }) =>
              `flex items-center px-3 py-2 text-[11px] font-medium rounded-none border-l-2 transition-colors ${
                isActive
                  ? 'bg-brand-50 text-brand-900 border-brand-700 font-semibold'
                  : 'text-slate-700 border-transparent hover:bg-slate-50 hover:text-brand-900'
              }`
            }
          >
            {item.label}
          </NavLink>
        ))}
      </nav>

      <div className="p-3 border-t border-slate-200 text-[9px] text-slate-400">
        Waypoint Delivery System
      </div>
    </aside>
  );
};
