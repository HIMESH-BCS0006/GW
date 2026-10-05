import React from 'react';
import { Navigate, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from './AuthContext';

interface RequireAuthProps {
  allowedRoles?: string[];
  children: React.ReactNode;
}

export const RequireAuth: React.FC<RequireAuthProps> = ({ allowedRoles, children }) => {
  const { user, isLoading, logout } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();

  if (isLoading) {
    return (
      <div className="flex h-screen w-full items-center justify-center bg-slate-50">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-emerald-600 border-t-transparent"></div>
      </div>
    );
  }

  if (!user) {
    const host = window.location.hostname || 'localhost';
    window.location.href = `http://${host}`;
    return null;
  }

  if (allowedRoles && !allowedRoles.includes(user.role)) {
    return (
      <div className="flex h-screen w-full flex-col items-center justify-center bg-slate-50 p-4 text-center">
        <h1 className="text-xl font-bold text-red-600">403 - Access Forbidden</h1>
        <p className="mt-2 text-slate-600">
          Your role <code className="font-mono font-semibold">{user.role}</code> does not have access to this portal.
        </p>
        <button
          type="button"
          onClick={() => {
            logout();
            navigate('/login', { replace: true, state: { from: location } });
          }}
          className="mt-5 rounded-lg bg-emerald-700 px-4 py-2 text-sm font-semibold text-white hover:bg-emerald-800"
        >
          Sign in as Store Manager
        </button>
      </div>
    );
  }

  return <>{children}</>;
};
