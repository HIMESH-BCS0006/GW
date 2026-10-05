import React from 'react';
import { Violation } from '../api/http';

interface ViolationListProps {
  violations?: Violation[];
}

export const ViolationList: React.FC<ViolationListProps> = ({ violations }) => {
  if (!violations || violations.length === 0) return null;

  return (
    <div className="bg-red-50 border border-red-200 rounded-lg p-4 my-3 text-xs space-y-2">
      <div className="font-semibold text-red-900 flex items-center space-x-1">
        <span>Constraint Violations ({violations.length})</span>
      </div>
      <ul className="space-y-2">
        {violations.map((v, index) => (
          <li key={index} className="bg-white p-3 rounded border border-red-100 shadow-xs">
            <div className="flex justify-between items-center mb-1">
              <span className="font-bold text-red-800 bg-red-100 px-2 py-0.5 rounded font-mono">
                {v.rule}
              </span>
              {(v.actual !== undefined || v.limit !== undefined) && (
                <span className="text-gray-500 text-[11px]">
                  Actual: <strong className="text-red-700">{String(v.actual ?? '-')}</strong> / Limit:{' '}
                  <strong className="text-gray-800">{String(v.limit ?? '-')}</strong>
                </span>
              )}
            </div>
            <p className="text-gray-700">{v.message}</p>
          </li>
        ))}
      </ul>
    </div>
  );
};
