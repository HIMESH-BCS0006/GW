import React from 'react';
import { LoadingState } from '../../components/LoadingState';
import { ErrorState } from '../../components/ErrorState';
import { EmptyState } from '../../components/EmptyState';
import { useGetDashboard } from '../../api/pending/dashboard';

export const DispatcherDashboardPage: React.FC = () => {
  const { data, isLoading, isError } = useGetDashboard();

  if (isLoading) return <LoadingState />;
  if (isError) return <ErrorState error={null as any} />;
  if (!data) return <EmptyState title="No dashboard data" description="The API returned no data." />;

  return (
    <div className="p-4">
      <h1 className="text-xl font-bold mb-4">Dispatcher Dashboard</h1>
      {/* Simple display of key fields */}
      <pre>{JSON.stringify(data, null, 2)}</pre>
    </div>
  );
};
