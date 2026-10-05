// Mock drivers for planning page selection
import { useQuery } from '@tanstack/react-query';

type Driver = {
  id: string;
  name: string;
  email: string;
};

const mockDrivers: Driver[] = [
  { id: 'DRV-001', name: 'Charlie Driver', email: 'charlie.driver@example.com' },
  { id: 'DRV-002', name: 'Dana Driver', email: 'dana.driver@example.com' },
];

export function useGetDrivers() {
  return useQuery({
    queryKey: ['drivers'],
    queryFn: () => mockDrivers,
    initialData: mockDrivers,
  });
}
