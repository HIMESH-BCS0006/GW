import React from 'react';

interface EmptyStateProps {
  title: string;
  description?: string;
  actionLabel?: string;
  onAction?: () => void;
}

export const EmptyState: React.FC<EmptyStateProps> = ({
  title,
  description,
  actionLabel,
  onAction,
}) => {
  return (
    <div className="bg-white rounded border border-slate-200 p-10 text-center my-4 flex flex-col items-center justify-center">
      <div className="w-10 h-10 bg-brand-50 text-brand-700 rounded flex items-center justify-center font-bold text-lg mb-3">
        +
      </div>
      <h3 className="text-base font-semibold text-slate-800">{title}</h3>
      {description && <p className="text-sm text-slate-500 mt-1 max-w-md">{description}</p>}
      {actionLabel && onAction && (
        <button
          onClick={onAction}
          className="mt-4 bg-brand-600 hover:bg-brand-700 text-white font-medium text-xs px-4 py-2 rounded-md shadow-sm transition-colors"
        >
          {actionLabel}
        </button>
      )}
    </div>
  );
};
