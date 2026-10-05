import React, { useState } from 'react';
import {
  useGetRefOutlets,
  useGetRefVehicles,
  useGetRefCalendar,
  useGetRefConfig,
} from '../api/generated/reference/reference';

export const ReferencePage: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'outlets' | 'vehicles' | 'calendar' | 'config'>('outlets');

  const { data: outlets, isLoading: loadingOutlets } = useGetRefOutlets();
  const { data: vehicles, isLoading: loadingVehicles } = useGetRefVehicles();
  const { data: calendar, isLoading: loadingCalendar } = useGetRefCalendar();
  const { data: config, isLoading: loadingConfig } = useGetRefConfig();

  return (
    <div className="space-y-6">
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h1 className="text-2xl font-bold text-gray-900">Reference Data Catalog</h1>
        <p className="text-sm text-gray-600 mt-1">
          Dynamically loaded network parameters, outlet capabilities, vehicle specs, and system configs from <code className="bg-gray-100 px-1 py-0.5 rounded text-indigo-700">/ref/*</code> endpoints.
        </p>

        <div className="flex space-x-2 mt-6 border-b border-gray-200 pb-2">
          {(['outlets', 'vehicles', 'calendar', 'config'] as const).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`px-4 py-2 text-sm font-medium rounded-md capitalize transition-colors ${
                activeTab === tab
                  ? 'bg-indigo-600 text-white'
                  : 'text-gray-600 hover:bg-gray-100'
              }`}
            >
              {tab}
            </button>
          ))}
        </div>
      </div>

      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 overflow-x-auto">
        {activeTab === 'outlets' && (
          <div>
            <h2 className="text-lg font-semibold text-gray-900 mb-4">Outlets ({outlets?.length || 0})</h2>
            {loadingOutlets ? (
              <div className="text-gray-500">Loading outlets from /ref/outlets...</div>
            ) : (
              <table className="min-w-full divide-y divide-gray-200 text-xs">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-4 py-2 text-left font-semibold text-gray-600">ID</th>
                    <th className="px-4 py-2 text-left font-semibold text-gray-600">Name</th>
                    <th className="px-4 py-2 text-left font-semibold text-gray-600">Brand</th>
                    <th className="px-4 py-2 text-left font-semibold text-gray-600">Depot</th>
                    <th className="px-4 py-2 text-left font-semibold text-gray-600">Window</th>
                    <th className="px-4 py-2 text-left font-semibold text-gray-600">Reefer Required</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {outlets?.map((outlet: any) => (
                    <tr key={outlet.id} className="hover:bg-gray-50">
                      <td className="px-4 py-2 font-mono font-bold text-indigo-600">{outlet.id}</td>
                      <td className="px-4 py-2 font-medium text-gray-900">{outlet.name}</td>
                      <td className="px-4 py-2 text-gray-700">{outlet.brand}</td>
                      <td className="px-4 py-2 text-gray-700">{outlet.depot_id}</td>
                      <td className="px-4 py-2 text-gray-700">
                        {outlet.window_open} - {outlet.window_close}
                      </td>
                      <td className="px-4 py-2">
                        {outlet.requires_reefer ? (
                          <span className="bg-blue-100 text-blue-800 text-[10px] px-2 py-0.5 rounded font-semibold">
                            YES
                          </span>
                        ) : (
                          <span className="text-gray-400">NO</span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        )}

        {activeTab === 'vehicles' && (
          <div>
            <h2 className="text-lg font-semibold text-gray-900 mb-4">Vehicles ({vehicles?.length || 0})</h2>
            {loadingVehicles ? (
              <div className="text-gray-500">Loading vehicles from /ref/vehicles...</div>
            ) : (
              <table className="min-w-full divide-y divide-gray-200 text-xs">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-4 py-2 text-left font-semibold text-gray-600">ID</th>
                    <th className="px-4 py-2 text-left font-semibold text-gray-600">Name</th>
                    <th className="px-4 py-2 text-left font-semibold text-gray-600">Type</th>
                    <th className="px-4 py-2 text-left font-semibold text-gray-600">Depot</th>
                    <th className="px-4 py-2 text-left font-semibold text-gray-600">Capacity (Kg / m³)</th>
                    <th className="px-4 py-2 text-left font-semibold text-gray-600">Reefer</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {vehicles?.map((vehicle: any) => (
                    <tr key={vehicle.id} className="hover:bg-gray-50">
                      <td className="px-4 py-2 font-mono font-bold text-indigo-600">{vehicle.id}</td>
                      <td className="px-4 py-2 font-medium text-gray-900">{vehicle.name}</td>
                      <td className="px-4 py-2 text-gray-700">{vehicle.type}</td>
                      <td className="px-4 py-2 text-gray-700">{vehicle.depot_id}</td>
                      <td className="px-4 py-2 text-gray-700">
                        {vehicle.max_weight_kg} kg / {vehicle.max_volume_m3} m³
                      </td>
                      <td className="px-4 py-2">
                        {vehicle.is_reefer ? (
                          <span className="bg-green-100 text-green-800 text-[10px] px-2 py-0.5 rounded font-semibold">
                            REEFER
                          </span>
                        ) : (
                          <span className="text-gray-400">DRY BOX</span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        )}

        {activeTab === 'calendar' && (
          <div>
            <h2 className="text-lg font-semibold text-gray-900 mb-4">Operating Calendar</h2>
            {loadingCalendar ? (
              <div className="text-gray-500">Loading calendar from /ref/calendar...</div>
            ) : (
              <pre className="bg-gray-50 p-4 rounded text-xs font-mono overflow-auto max-h-96">
                {JSON.stringify(calendar, null, 2)}
              </pre>
            )}
          </div>
        )}

        {activeTab === 'config' && (
          <div>
            <h2 className="text-lg font-semibold text-gray-900 mb-4">System Parameters & Rules</h2>
            {loadingConfig ? (
              <div className="text-gray-500">Loading config from /ref/config...</div>
            ) : (
              <pre className="bg-gray-50 p-4 rounded text-xs font-mono overflow-auto max-h-96">
                {JSON.stringify(config, null, 2)}
              </pre>
            )}
          </div>
        )}
      </div>
    </div>
  );
};
