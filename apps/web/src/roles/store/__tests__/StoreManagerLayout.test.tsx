import React from 'react';
import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { MemoryRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { StoreManagerLayout } from '../components/StoreManagerLayout';
import { AuthContext } from '../../../shared/auth/AuthContext';

vi.mock('../../../shared/api/client', () => ({
  apiClient: {
    getRefOutlets: vi.fn().mockResolvedValue([
      {
        outlet_id: 'OUT004',
        brand: 'Fresh',
        district: 'Colombo',
        depot: 'Peliyagoda',
      },
    ]),
    getRefConfig: vi.fn().mockResolvedValue({
      cutoff_time: '16:00',
      business_clock: '2025-07-31T14:00:00+05:30',
      demo_mode: true,
    }),
  },
}));

describe('StoreManagerLayout Component', () => {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });

  const mockUser = {
    id: 'USR-STORE-001',
    username: 'store@waypoint.test',
    role: 'store_manager' as const,
    outlet_id: 'OUT004',
    display_name: 'Store Manager John',
  };

  const renderLayout = () => {
    return render(
      <QueryClientProvider client={queryClient}>
        <AuthContext.Provider
          value={{
            user: mockUser,
            token: 'mock-token',
            isLoading: false,
            login: vi.fn(),
            logout: vi.fn(),
            setUser: vi.fn(),
          }}
        >
          <MemoryRouter initialEntries={['/store']}>
            <StoreManagerLayout />
          </MemoryRouter>
        </AuthContext.Provider>
      </QueryClientProvider>
    );
  };

  it('renders header with display_name and outlet (Departure 8), not driver ID', async () => {
    renderLayout();

    expect(await screen.findByText('Store Manager John')).toBeInTheDocument();
    expect(await screen.findByText('Fresh Colombo (OUT004)')).toBeInTheDocument();
    expect(screen.queryByText(/DRV-/i)).not.toBeInTheDocument();
  });

  it('renders bottom navigation for mobile screen', () => {
    renderLayout();
    const bottomNav = screen.getByTestId('bottom-navigation');
    expect(bottomNav).toBeInTheDocument();
    expect(screen.getByText('Home')).toBeInTheDocument();
    expect(screen.getByText('New Order')).toBeInTheDocument();
    expect(screen.getByText('Notices')).toBeInTheDocument();
    expect(screen.getByText('Orders')).toBeInTheDocument();
  });
});
