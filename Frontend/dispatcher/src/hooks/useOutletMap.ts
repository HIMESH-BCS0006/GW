import { useMemo } from 'react';
import { useGetRefOutlets } from '../api/generated/reference/reference';
import type { Outlet } from '../api/generated/models';

/**
 * Returns a lookup map from outlet_id -> Outlet, loaded from /ref/outlets.
 * Used to join brand / district / depot info onto Order rows which only carry outlet_id.
 */
export function useOutletMap(): {
  outletsById: Record<string, Outlet>;
  isLoading: boolean;
  isError: boolean;
} {
  const { data: outlets, isLoading, isError } = useGetRefOutlets();

  const outletsById = useMemo(() => {
    if (!outlets) return {} as Record<string, Outlet>;
    return outlets.reduce<Record<string, Outlet>>((acc, o) => {
      if (o.outlet_id) acc[o.outlet_id] = o;
      if ((o as any).id) acc[(o as any).id] = o;
      return acc;
    }, {});
  }, [outlets]);

  return { outletsById, isLoading, isError };
}
