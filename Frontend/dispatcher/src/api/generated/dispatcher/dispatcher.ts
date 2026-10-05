import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { customInstance } from '../../http';
export { useGetPlanningTrips } from '../../pending/planning';
import type {
  DashboardSummary,
  Order,
  PlanRun,
  TripDetail,
  Trip,
  ValidatePlanRequest,
  ValidatePlanResponse,
  GeneratePlanRequest,
  AlertItem,
  LiveMonitoringResponse,
  Deferral,
  LoadCheck,
  ResolveLoadCheckRequest,
  ExceptionDecisionRequest,
  Exception,
  VehicleAvailability,
  FuelLedger,
  PlanRunSummaryResponse,
} from '../models';

export function useGetDashboard(params?: { depot_id?: string }) {
  return useQuery({
    queryKey: ['dashboard', params?.depot_id],
    queryFn: ({ signal }) =>
      customInstance<DashboardSummary>({
        url: '/dashboard',
        method: 'GET',
        params,
        signal,
      }),
    refetchInterval: 4000,
  });
}

export function useGetDispatchQueue(params?: { depot_id?: string }) {
  return useQuery({
    queryKey: ['dispatchQueue', params?.depot_id],
    queryFn: ({ signal }) =>
      customInstance<Order[]>({
        url: '/dispatch/queue',
        method: 'GET',
        params,
        signal,
      }),
    refetchInterval: 4000,
  });
}

export function useListAlerts(params?: { depot_id?: string }) {
  return useQuery({
    queryKey: ['alerts', params?.depot_id],
    queryFn: ({ signal }) =>
      customInstance<AlertItem[]>({
        url: '/alerts',
        method: 'GET',
        params,
        signal,
      }),
    refetchInterval: 15000,
  });
}

export function useListPlans(params?: { depot_id?: string }) {
  return useQuery({
    queryKey: ['plans', params?.depot_id],
    queryFn: ({ signal }) =>
      customInstance<PlanRun[]>({
        url: '/plans',
        method: 'GET',
        params,
        signal,
      }),
  });
}

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

export function useGeneratePlan() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: GeneratePlanRequest) =>
      customInstance<PlanRun>({
        url: '/plans/generate',
        method: 'POST',
        data,
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['plans'] });
      queryClient.invalidateQueries({ queryKey: ['planTrips'] });
      queryClient.invalidateQueries({ queryKey: ['planningTrips'] });
      queryClient.invalidateQueries({ queryKey: ['unplannedOrders'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard'] });
      queryClient.invalidateQueries({ queryKey: ['dispatchQueue'] });
    },
  });
}

export function useValidatePlan() {
  return useMutation({
    mutationFn: (data: ValidatePlanRequest) =>
      customInstance<ValidatePlanResponse>({
        url: '/plans/validate',
        method: 'POST',
        data,
      }),
  });
}

export function useConfirmTrip() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (tripId: string) =>
      customInstance<TripDetail>({
        url: `/trips/${tripId}/confirm`,
        method: 'POST',
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['plans'] });
      queryClient.invalidateQueries({ queryKey: ['planTrips'] });
      queryClient.invalidateQueries({ queryKey: ['planningTrips'] });
      queryClient.invalidateQueries({ queryKey: ['unplannedOrders'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard'] });
      queryClient.invalidateQueries({ queryKey: ['dispatchQueue'] });
    },
  });
}

export function useCancelTrip() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (tripId: string) =>
      customInstance<Trip>({
        url: `/trips/${tripId}/cancel`,
        method: 'POST',
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['plans'] });
      queryClient.invalidateQueries({ queryKey: ['planTrips'] });
      queryClient.invalidateQueries({ queryKey: ['planningTrips'] });
      queryClient.invalidateQueries({ queryKey: ['unplannedOrders'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard'] });
      queryClient.invalidateQueries({ queryKey: ['dispatchQueue'] });
    },
  });
}

export function useAddOrderToTrip() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ tripId, orderId }: { tripId: string; orderId: string }) =>
      customInstance<Trip>({
        url: `/trips/${tripId}/orders`,
        method: 'POST',
        data: { order_id: orderId },
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['plans'] });
      queryClient.invalidateQueries({ queryKey: ['planTrips'] });
      queryClient.invalidateQueries({ queryKey: ['planningTrips'] });
      queryClient.invalidateQueries({ queryKey: ['unplannedOrders'] });
      queryClient.invalidateQueries({ queryKey: ['dispatchQueue'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard'] });
    },
  });
}

export function useRemoveOrderFromTrip() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ tripId, orderId }: { tripId: string; orderId: string }) =>
      customInstance<Trip>({
        url: `/trips/${tripId}/orders/${orderId}`,
        method: 'DELETE',
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['plans'] });
      queryClient.invalidateQueries({ queryKey: ['planTrips'] });
      queryClient.invalidateQueries({ queryKey: ['planningTrips'] });
      queryClient.invalidateQueries({ queryKey: ['unplannedOrders'] });
      queryClient.invalidateQueries({ queryKey: ['dispatchQueue'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard'] });
    },
  });
}

export function useDeferOrder() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({
      orderId,
      reason_code,
      reason_text,
    }: {
      orderId: string;
      reason_code: string;
      reason_text?: string;
    }) =>
      customInstance<any>({
        url: `/orders/${orderId}/defer`,
        method: 'POST',
        data: { reason_code, reason_text },
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['dispatchQueue'] });
      queryClient.invalidateQueries({ queryKey: ['deferrals'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard'] });
    },
  });
}

export function useRequeueOrder() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (orderId: string) =>
      customInstance<Order>({
        url: `/orders/${orderId}/requeue`,
        method: 'POST',
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['dispatchQueue'] });
      queryClient.invalidateQueries({ queryKey: ['deferrals'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard'] });
    },
  });
}

export function useGetLiveMonitoring(params?: { depot_id?: string }) {
  return useQuery({
    queryKey: ['liveMonitoring', params?.depot_id],
    queryFn: ({ signal }) =>
      customInstance<LiveMonitoringResponse>({
        url: '/monitoring/live',
        method: 'GET',
        params,
        signal,
      }),
    refetchInterval: 10000,
  });
}

export function useListDeferrals(params?: { depot_id?: string }) {
  return useQuery({
    queryKey: ['deferrals', params?.depot_id],
    queryFn: ({ signal }) =>
      customInstance<Deferral[]>({
        url: '/deferrals',
        method: 'GET',
        params,
        signal,
      }),
    refetchInterval: 15000,
  });
}

export function useListLoadChecks(params?: { depot_id?: string; status?: string }) {
  return useQuery({
    queryKey: ['loadChecks', params?.depot_id, params?.status],
    queryFn: ({ signal }) =>
      customInstance<LoadCheck[]>({
        url: '/load-checks',
        method: 'GET',
        params,
        signal,
      }),
    refetchInterval: 15000,
  });
}

export function useResolveLoadCheck() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({
      loadCheckId,
      resolution,
      notes,
    }: {
      loadCheckId: string;
      resolution: string;
      notes?: string;
    }) =>
      customInstance<LoadCheck>({
        url: `/load-checks/${loadCheckId}/resolve`,
        method: 'POST',
        data: { resolution, notes },
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['loadChecks'] });
      queryClient.invalidateQueries({ queryKey: ['alerts'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard'] });
    },
  });
}

export function useResolveExceptionDecision() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({
      exceptionId,
      decision,
      notes,
    }: {
      exceptionId: string;
      decision: string;
      notes?: string;
    }) =>
      customInstance<Exception>({
        url: `/exceptions/${exceptionId}/decision`,
        method: 'POST',
        data: { decision, notes },
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['liveMonitoring'] });
      queryClient.invalidateQueries({ queryKey: ['alerts'] });
    },
  });
}

export function useGetFleetAvailability(params?: { depot_id?: string; date?: string }) {
  return useQuery({
    queryKey: ['fleetAvailability', params?.depot_id, params?.date],
    queryFn: ({ signal }) =>
      customInstance<VehicleAvailability[]>({
        url: '/fleet',
        method: 'GET',
        params,
        signal,
      }),
  });
}

export function useGetFuelState(params?: { depot_id?: string }) {
  return useQuery({
    queryKey: ['fuelState', params?.depot_id],
    queryFn: ({ signal }) =>
      customInstance<FuelLedger[]>({
        url: '/fuel',
        method: 'GET',
        params,
        signal,
      }),
  });
}

export function useGetPlansSummary(params?: { depot_id?: string }) {
  return useQuery({
    queryKey: ['plansSummary', params?.depot_id],
    queryFn: ({ signal }) =>
      customInstance<PlanRunSummaryResponse>({
        url: '/plans/summary',
        method: 'GET',
        params,
        signal,
      }),
  });
}
