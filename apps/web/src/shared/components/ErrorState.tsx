import React from 'react';
import { AlertTriangle, RefreshCw } from 'lucide-react';
import { ApiError } from '../api/client';

export interface StandardErrorFormat {
  error: {
    code: string;
    message: string;
    details?: any;
  };
}

interface ErrorStateProps {
  error: ApiError | StandardErrorFormat | Error | unknown;
  onRetry?: () => void;
  title?: string;
}

export const ErrorState: React.FC<ErrorStateProps> = ({
  error,
  onRetry,
  title = 'An error occurred',
}) => {
  let code = 'ERROR';
  let message = 'An unexpected error occurred. Please try again.';

  if (error && typeof error === 'object') {
    if ('error' in error && (error as StandardErrorFormat).error) {
      const e = (error as StandardErrorFormat).error;
      code = e.code || 'ERROR';
      message = e.message || message;
    } else if (error instanceof ApiError) {
      code = error.code;
      message = error.message;
    } else if ('code' in error && 'message' in error) {
      code = String((error as any).code);
      message = String((error as any).message);
    } else if (error instanceof Error) {
      message = error.message;
    }
  }

  return (
    <div
      data-testid="error-state"
      className="flex flex-col items-center justify-center rounded-lg border border-red-200 bg-red-50 p-6 text-center"
    >
      <div className="flex h-12 w-12 items-center justify-center rounded-full bg-red-100 text-red-600">
        <AlertTriangle className="h-6 w-6" />
      </div>
      <h3 className="mt-3 text-base font-semibold text-red-900">{title}</h3>
      <div className="mt-2 rounded bg-white px-3 py-1.5 border border-red-100 font-mono text-xs font-bold text-red-700">
        [{code}]
      </div>
      <p className="mt-2 text-sm text-red-600 max-w-md">{message}</p>
      {onRetry && (
        <button
          onClick={onRetry}
          className="mt-4 inline-flex items-center gap-2 rounded-md bg-red-600 px-4 py-2 text-xs font-medium text-white hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2"
        >
          <RefreshCw className="h-3.5 w-3.5" />
          Retry
        </button>
      )}
    </div>
  );
};
