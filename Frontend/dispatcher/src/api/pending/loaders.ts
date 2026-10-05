// Mock loaders for planning page selection
import { useQuery } from '@tanstack/react-query';

type Loader = {
  id: string;
  name: string;
  email: string;
};

const mockLoaders: Loader[] = [
  { id: 'LDR-001', name: 'Alice Loader', email: 'alice.loader@example.com' },
  { id: 'LDR-002', name: 'Bob Loader', email: 'bob.loader@example.com' },
];

export function useGetLoaders() {
  return useQuery({
    queryKey: ['loaders'],
    queryFn: () => mockLoaders,
    initialData: mockLoaders,
  });
}
