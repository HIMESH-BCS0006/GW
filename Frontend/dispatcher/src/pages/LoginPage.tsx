import React, { useEffect } from 'react';

export const LoginPage: React.FC = () => {
  useEffect(() => {
    const host = window.location.hostname || 'localhost';
    window.location.href = `http://${host}`;
  }, []);

  return (
    <div className="min-h-screen bg-slate-900 flex items-center justify-center p-4">
      <div className="text-center text-slate-300">
        <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-teal-500 mb-4"></div>
        <p className="text-sm font-medium">Redirecting to Waypoint Central Login...</p>
      </div>
    </div>
  );
};