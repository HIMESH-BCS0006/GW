import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient } from '../../../shared/api/client';
import type {
  CreateOrderRequest,
  CreateOrderResponse,
  Order,
  OutletRef,
} from '../types';

// ── Reference data ─────────────────────────────────────────────────────────

export const OUTLETS_QUERY_KEY = ['ref', 'outlets'] as const;

export function useRefOutlets() {
  return useQuery<OutletRef[]>({
    queryKey: OUTLETS_QUERY_KEY,
    queryFn: () => apiClient.getRefOutlets() as Promise<OutletRef[]>,
    staleTime: Infinity,      // Reference data; never re-fetched automatically
  });
}

// ── Order list ──────────────────────────────────────────────────────────────

export const ORDERS_QUERY_KEY = ['store-manager', 'orders'] as const;

export function useOrders() {
  return useQuery<Order[]>({
    queryKey: ORDERS_QUERY_KEY,
    queryFn: () => apiClient.listOrders() as Promise<Order[]>,
    staleTime: 3000,
    refetchInterval: 4000,
  });
}

// ── Single order ────────────────────────────────────────────────────────────

export function useOrder(id: string | undefined) {
  return useQuery<Order>({
    queryKey: ['store-manager', 'orders', id],
    queryFn: () => apiClient.getOrderById(id!) as Promise<Order>,
    enabled: Boolean(id),
    staleTime: 3000,
    refetchInterval: 4000,
  });
}

// ── Create order (SM2) ──────────────────────────────────────────────────────

export function useCreateOrder() {
  const qc = useQueryClient();

  return useMutation<CreateOrderResponse, Error, CreateOrderRequest>({
    mutationFn: (payload) =>
      apiClient.createOrder(payload) as Promise<CreateOrderResponse>,
    onSuccess: () => {
      // Invalidate the orders list so SM1 / orders list reflects the new order
      qc.invalidateQueries({ queryKey: ORDERS_QUERY_KEY });
      qc.invalidateQueries({ queryKey: ['store-manager', 'expected-deliveries'] });
    },
  });
}

// ── Cancel order ────────────────────────────────────────────────────────────

export function useCancelOrder() {
  const qc = useQueryClient();

  return useMutation<Order, Error, { id: string; reason: string; note?: string }>({
    mutationFn: ({ id, reason, note }) =>
      apiClient.cancelOrder(id, { reason, note }) as Promise<Order>,
    onSuccess: (_, { id }) => {
      qc.invalidateQueries({ queryKey: ORDERS_QUERY_KEY });
      qc.invalidateQueries({ queryKey: ['store-manager', 'orders', id] });
    },
  });
}

// ── Expected deliveries ─────────────────────────────────────────────────────

export function useExpectedDeliveries(outletId: string | undefined) {
  return useQuery({
    queryKey: ['store-manager', 'expected-deliveries', outletId],
    queryFn: () => apiClient.getExpectedDeliveries(outletId!),
    enabled: Boolean(outletId),
    staleTime: 15000,
  });
}

// ── Notifications ───────────────────────────────────────────────────────────

export const NOTIFICATIONS_QUERY_KEY = ['store-manager', 'notifications'] as const;

export function useNotifications() {
  return useQuery({
    queryKey: NOTIFICATIONS_QUERY_KEY,
    queryFn: () => apiClient.listNotifications(),
    staleTime: 15000,
  });
}

export function useMarkNotificationRead() {
  const qc = useQueryClient();
  return useMutation<unknown, Error, string>({
    mutationFn: (id) => apiClient.markNotificationRead(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: NOTIFICATIONS_QUERY_KEY });
    },
  });
}
