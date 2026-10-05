import React from 'react';
import { useAuth } from '../context/AuthContext';

export const WrongRolePage: React.FC = () => {
  const { user, logout } = useAuth();

  return (
    <div className="min-h-screen bg-slate-100 flex items-center justify-center p-4">
      <div className="bg-white rounded-lg shadow-md border border-slate-200 max-w-md w-full p-8 text-center">
        <div className="w-12 h-12 bg-red-100 text-red-600 rounded-full flex items-center justify-center font-bold text-xl mx-auto mb-4">
          !
        </div>
        <h1 className="text-xl font-bold text-slate-900">Access Restricted</h1>
        <p className="text-sm text-slate-600 mt-2">
          You are currently logged in as{' '}
          <strong className="text-indigo-600 font-semibold">{user?.role || 'another role'}</strong>.
        </p>
        <p className="text-xs text-slate-500 mt-2">
          This console is strictly restricted to the <strong>Dispatcher</strong> role. Please log out and sign in with a dispatcher account.
        </p>
        <button
          onClick={logout}
          className="mt-6 w-full bg-slate-900 hover:bg-slate-800 text-white font-medium text-sm py-2 px-4 rounded-md transition-colors shadow-sm"
        >
          Sign Out & Return to Login
        </button>
      </div>
    </div>
  );
};
