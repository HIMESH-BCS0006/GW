import { useQuery } from '@tanstack/react-query';
import { customInstance } from '../http';
import type { TripDetail } from '../generated/models/tripDetail';

export function useGetPlanTrips(planRunId: string, params?: { depot_id?: string }) {
  return useQuery({
    queryKey: ['planTrips', planRunId, params?.depot_id],
    queryFn: ({ signal }) =>
      customInstance<TripDetail[]>({
        url: `/plans/${planRunId}/trips`,
        method: 'GET',
        params,
        signal,
      }),
    enabled: Boolean(planRunId),
  });
}
