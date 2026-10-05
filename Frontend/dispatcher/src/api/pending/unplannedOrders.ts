import { useQuery } from '@tanstack/react-query';
import { customInstance } from '../http';
import type { Order } from '../generated/models/order';

export const useGetUnplannedOrders = (params?: { depot_id?: string }) => {
  return useQuery({
    queryKey: ['unplannedOrders', params?.depot_id],
    queryFn: async ({ signal }) => {
      const orders = await customInstance<Order[]>({
        url: '/dispatch/queue',
        method: 'GET',
        params,
        signal,
      });
      return (orders || []).filter(
        (o) => o.status === 'SUBMITTED'
      );
    },
  });
};
