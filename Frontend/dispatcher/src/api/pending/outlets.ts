// Mock reference outlets for development and tests
import { useQuery } from '@tanstack/react-query';

type Outlet = {
  outlet_id: string;
  brand: string;
  district: string;
  depot: string;
  dock_type?: string;
  parking_constraint?: string;
  window_open_time?: string;
  window_close_time?: string;
};

const mockOutlets: Outlet[] = [
  {
    outlet_id: 'OUT001',
    brand: 'Fresh',
    district: 'Colombo',
    depot: 'Peliyagoda',
    dock_type: 'DOCK',
    parking_constraint: 'NONE',
    window_open_time: '05:00',
    window_close_time: '08:00',
  },
  {
    outlet_id: 'OUT002',
    brand: 'Style',
    district: 'Kandy',
    depot: 'Kandy',
    dock_type: 'STREET',
    parking_constraint: 'NARROW',
    window_open_time: '09:00',
    window_close_time: '17:00',
  },
];

export function useGetRefOutlets() {
  return useQuery({
    queryKey: ['refOutlets'],
    queryFn: () => mockOutlets,
    initialData: mockOutlets,
  });
}
