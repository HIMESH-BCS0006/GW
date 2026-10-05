import React from 'react';
import { Link, useLocation } from 'react-router-dom';

interface NavbarProps {
  selectedDepot: string;
  onDepotChange: (depot: string) => void;
}

export const Navbar: React.FC<NavbarProps> = ({ selectedDepot, onDepotChange }) => {
  const location = useLocation();

  const navItems = [
    { label: 'Dashboard', path: '/' },
    { label: 'Dispatch Queue', path: '/queue' },
    { label: 'Planning', path: '/planning' },
    { label: 'Live Monitoring', path: '/monitoring' },
    { label: 'Reference Data', path: '/reference' },
  ];

  return (
    <header className="bg-slate-900 text-white shadow-md">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          <div className="flex items-center space-x-8">
            <Link to="/" className="flex items-center space-x-3">
              <span className="bg-indigo-600 text-white text-lg font-bold px-3 py-1 rounded shadow">
                WAYPOINT
              </span>
              <span className="text-sm text-gray-300 font-medium tracking-wide">
                Dispatcher Console
              </span>
            </Link>
            <nav className="hidden md:flex space-x-1">
              {navItems.map((item) => {
                const isActive = location.pathname === item.path;
                return (
                  <Link
                    key={item.path}
                    to={item.path}
                    className={`px-3 py-2 rounded-md text-sm font-medium transition-colors ${
                      isActive
                        ? 'bg-slate-800 text-white font-semibold'
                        : 'text-gray-300 hover:bg-slate-800 hover:text-white'
                    }`}
                  >
                    {item.label}
                  </Link>
                );
              })}
            </nav>
          </div>

          <div className="flex items-center space-x-4">
            <div className="flex items-center space-x-2">
              <label htmlFor="depot-select" className="text-xs text-gray-400 font-medium">
                Active Depot:
              </label>
              <select
                id="depot-select"
                value={selectedDepot}
                onChange={(e) => onDepotChange(e.target.value)}
                className="bg-slate-800 text-sm text-white border border-slate-700 rounded-md px-3 py-1 focus:outline-none focus:ring-2 focus:ring-indigo-500"
              >
                <option value="Peliyagoda">Peliyagoda Depot</option>
                <option value="Kandy">Kandy Regional Hub</option>
              </select>
            </div>
            <div className="bg-slate-800 text-xs px-2.5 py-1 rounded border border-slate-700 text-gray-300">
              Role: <span className="text-indigo-400 font-semibold">Dispatcher</span>
            </div>
          </div>
        </div>
      </div>
    </header>
  );
};
