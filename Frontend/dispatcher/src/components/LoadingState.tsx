import React from 'react';

interface LoadingStateProps {
  message?: string;
}

export const LoadingState: React.FC<LoadingStateProps> = ({ message = 'Loading data...' }) => {
  return (
    <div className="bg-white rounded-lg border border-slate-200 p-12 text-center my-4 flex flex-col items-center justify-center">
      <div className="w-8 h-8 border-4 border-mint-200 border-t-mint-600 rounded-full animate-spin mb-3" />
      <span className="text-sm font-medium text-slate-600">{message}</span>
    </div>
  );
};
