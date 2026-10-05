import { useQuery } from '@tanstack/react-query';
import { customInstance } from '../http';
import type { LoadCheck } from '../generated/models/loadCheck';
import type { Order } from '../generated/models/order';

export type LoadingSummary = {
  shortfall: number;
  pendingOrders: number;
  vehiclesLoading: number;
};

export function useGetLoading(params?: { depot_id?: string }) {
  return useQuery({
    queryKey: ['loadingSummary', params?.depot_id],
    queryFn: async ({ signal }) => {
      try {
        const [loadChecks, orders, loadingTrips] = await Promise.all([
          customInstance<LoadCheck[]>({
            url: '/load-checks',
            method: 'GET',
            params,
            signal,
          }).catch(() => []),
          customInstance<Order[]>({
            url: '/dispatch/queue',
            method: 'GET',
            params,
            signal,
          }).catch(() => []),
          customInstance<any[]>({
            url: '/loading/trips',
            method: 'GET',
            params,
            signal,
          }).catch(() => []),
        ]);

        const shortfallCount = (loadChecks || []).filter(
          (lc) => lc.issue === 'shortfall' || lc.status === 'open'
        ).length;
        const pendingCount = (orders || []).filter(
          (o) => o.status === 'SUBMITTED' || o.status === 'PLANNED'
        ).length;
        const vehiclesLoadingCount = (loadingTrips || []).length;

        return {
          shortfall: shortfallCount,
          pendingOrders: pendingCount,
          vehiclesLoading: vehiclesLoadingCount,
        };
      } catch (e) {
        return {
          shortfall: 0,
          pendingOrders: 0,
          vehiclesLoading: 0,
        };
      }
    },
    refetchInterval: 10000,
  });
}