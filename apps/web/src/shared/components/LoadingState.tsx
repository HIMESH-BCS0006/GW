import React from 'react';

interface LoadingStateProps {
  message?: string;
  className?: string;
}

export const LoadingState: React.FC<LoadingStateProps> = ({
  message = 'Loading...',
  className = '',
}) => {
  return (
    <div
      data-testid="loading-state"
      className={`flex flex-col items-center justify-center p-8 text-center ${className}`}
    >
      <div className="h-8 w-8 animate-spin rounded-full border-4 border-emerald-600 border-t-transparent"></div>
      <p className="mt-3 text-sm font-medium text-slate-600">{message}</p>
    </div>
  );
};
