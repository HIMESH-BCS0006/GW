import React from 'react';
import { useGetDispatchQueue } from '../api/generated/dispatcher/dispatcher';
import { useAuth } from '../context/AuthContext';
import { getStatusColor } from '../lib/utils';

export const DispatchQueuePage: React.FC = () => {
  const { selectedDepot } = useAuth();
  const { data: queue, isLoading, isError, error } = useGetDispatchQueue(
    selectedDepot ? { depot_id: selectedDepot } : undefined
  );

  return (
    <div className="space-y-6">
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Dispatch Queue</h1>
          <p className="text-sm text-gray-600 mt-1">
            Orders pending allocation for the upcoming operating run ({selectedDepot}).
          </p>
        </div>
        <div className="text-right">
          <span className="text-xs text-gray-500 font-medium">Cutoff Rule:</span>
          <span className="ml-2 bg-indigo-50 text-indigo-700 px-2.5 py-1 rounded text-xs font-semibold">
            14:00 Colombo Time (D11)
          </span>
        </div>
      </div>

      <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        {isLoading ? (
          <div className="p-8 text-center text-gray-500">Loading order queue...</div>
        ) : isError ? (
          <div className="p-8 text-center text-red-600">
            Failed to load queue. {(error as any)?.message || 'Check backend connection.'}
          </div>
        ) : !queue || queue.length === 0 ? (
          <div className="p-8 text-center text-gray-500">
            No orders currently pending in the dispatch queue.
          </div>
        ) : (
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Order ID
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Outlet ID
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Delivery Date
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Temp Req
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Units / Weight / Vol
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Status
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200 text-sm">
              {queue.map((item: any) => (
                <tr key={item.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap font-medium text-indigo-600">
                    {item.id}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-gray-800 font-medium">
                    {item.outlet_id}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-gray-600">
                    {item.delivery_date}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span
                      className={`px-2 py-0.5 rounded text-xs font-semibold ${
                        item.temp_requirement === 'chilled' || item.temp_requirement === 'frozen'
                          ? 'bg-blue-100 text-blue-800'
                          : 'bg-amber-100 text-amber-800'
                      }`}
                    >
                      {item.temp_requirement}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-gray-600">
                    {item.order_units} u | {item.order_weight_kg ?? '-'} kg | {item.order_volume_m3 ?? '-'} m³
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span
                      className={`px-2.5 py-1 rounded-full text-xs font-semibold ${getStatusColor(
                        item.status
                      )}`}
                    >
                      {item.status}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
};
