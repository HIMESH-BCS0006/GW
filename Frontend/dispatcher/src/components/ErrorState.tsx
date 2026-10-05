import React from 'react';
import { ApiError } from '../api/http';
import { ViolationList } from './ViolationList';

interface ErrorStateProps {
  error: ApiError | Error | unknown;
  onRetry?: () => void;
}

export const ErrorState: React.FC<ErrorStateProps> = ({ error, onRetry }) => {
  const isApiError = error instanceof ApiError;
  const errorCode = isApiError ? error.code : 'ERROR';
  const errorMessage =
    error instanceof Error
      ? error.message
      : typeof error === 'string'
      ? error
      : 'An unexpected error occurred.';

  const violations = isApiError ? error.details?.violations : undefined;

  return (
    <div className="bg-red-50 border border-red-200 rounded-lg p-6 my-4">
      <div className="flex items-start justify-between">
        <div>
          <div className="flex items-center space-x-2">
            <span className="bg-red-600 text-white font-mono font-bold text-xs px-2 py-0.5 rounded">
              {errorCode}
            </span>
            <h3 className="text-base font-bold text-red-900">Request Failed</h3>
          </div>
          <p className="text-sm text-red-700 mt-2">{errorMessage}</p>
        </div>
        {onRetry && (
          <button
            onClick={onRetry}
            className="bg-red-600 hover:bg-red-700 text-white font-medium text-xs px-3 py-1.5 rounded transition-colors"
          >
            Retry
          </button>
        )}
      </div>

      {violations && violations.length > 0 && <ViolationList violations={violations} />}
    </div>
  );
};
