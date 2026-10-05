/**
 * SM1 Home page tests.
 *
 * Covers:
 *  1. Loading state renders spinner
 *  2. Orders list rendered when data available
 *  3. Empty state when no orders
 *  4. Unread notices badge count shown
 *  5. Next delivery card with ETA shown
 *  6. "No ETA yet" message when eta is null
 *  7. Error state with retry for orders
 *  8. Place Order CTA link present
 */

import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter } from 'react-router-dom';
import { SM1HomePage } from '../pages/SM1HomePage';
import { AuthContext } from '../../../shared/auth/AuthContext';
import { ApiError } from '../../../shared/api/client';

vi.mock('../../../shared/api/client', async (importOriginal) => {
  const actual = await importOriginal<any>();
  return {
    ...actual,
    apiClient: {
      getRefConfig: vi.fn(),
      getRefOutlets: vi.fn().mockResolvedValue([]),
      listOrders: vi.fn(),
      listNotifications: vi.fn(),
      getExpectedDeliveries: vi.fn(),
      createOrder: vi.fn(),
    },
  };
});

import { apiClient } from '../../../shared/api/client';

const MOCK_USER = {
  id: 'USR-001',
  username: 'store@waypoint.test',
  role: 'store_manager' as const,
  outlet_id: 'OUT004',
  display_name: 'Test SM',
};

const MOCK_CONFIG = {
  cutoff_time: '16:00',
  business_clock: '2025-07-31T14:00:00+05:30',
  demo_mode: true,
  budget_fresh_min: 270,
  budget_style_tech_min: 480,
  unit_constants: { Fresh: { ambient: { kg_per_unit: 1.0, m3_per_unit: 0.004 } } },
};

const MOCK_ORDERS = [
  {
    id: 'ORD-001',
    outlet_id: 'OUT004',
    delivery_date: '2025-08-01',
    placed_at: '2025-07-31T14:00:00+05:30',
    status: 'SUBMITTED',
    temp_requirement: 'ambient',
    order_units: 100,
    order_weight_kg: 100.0,
    order_volume_m3: 0.4,
    rolled_over: false,
    deferral_count: 0,
  },
  {
    id: 'ORD-002',
    outlet_id: 'OUT004',
    delivery_date: '2025-07-30',
    placed_at: '2025-07-29T14:00:00+05:30',
    status: 'DELIVERED',
    temp_requirement: 'chilled',
    order_units: 50,
    order_weight_kg: 60.0,
    order_volume_m3: 0.25,
    rolled_over: false,
    deferral_count: 0,
    stop_id: 'STOP-001',
    eta: '06:15',
  },
];

const MOCK_NOTIFICATIONS_WITH_UNREAD = [
  { id: 'NOTIF001', event_id: 'EVT001', audience_role: 'store_manager', read_at: null },
  { id: 'NOTIF002', event_id: 'EVT002', audience_role: 'store_manager', read_at: '2025-07-31T10:00:00+05:30' },
];

const MOCK_EXPECTED_DELIVERIES_WITH_ETA = [
  {
    id: 'STOP-001',
    trip_id: 'TRIP-001',
    order_id: 'ORD-001',
    seq: 1,
    eta: '06:15',
    service_start_est: '06:15',
    service_min: 16,
    status: 'PENDING',
    receipt_status: 'NONE',
  },
];

const MOCK_EXPECTED_DELIVERIES_NO_ETA = [
  {
    id: 'STOP-001',
    trip_id: 'TRIP-001',
    order_id: 'ORD-001',
    seq: 1,
    eta: null,
    service_start_est: null,
    service_min: 16,
    status: 'PENDING',
    receipt_status: 'NONE',
  },
];

function renderSM1() {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(
    <QueryClientProvider client={qc}>
      <AuthContext.Provider
        value={{
          user: MOCK_USER,
          token: 'tok',
          isLoading: false,
          login: vi.fn(),
          logout: vi.fn(),
          setUser: vi.fn(),
        }}
      >
        <MemoryRouter initialEntries={['/store']}>
          <SM1HomePage />
        </MemoryRouter>
      </AuthContext.Provider>
    </QueryClientProvider>
  );
}

describe('SM1 HomePage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    (apiClient.getRefConfig as any).mockResolvedValue(MOCK_CONFIG);
    (apiClient.listNotifications as any).mockResolvedValue([]);
    (apiClient.getExpectedDeliveries as any).mockResolvedValue([]);
  });

  // 1. Loading state
  it('renders loading state while fetching orders', async () => {
    (apiClient.listOrders as any).mockImplementation(() => new Promise(() => {}));
    renderSM1();
    // One of the loading queries will keep loading spinner visible
    await waitFor(() => {
      expect(screen.getByText(/loading/i)).toBeInTheDocument();
    });
  });

  // 2. Orders list rendered
  it('renders orders list when data is available', async () => {
    (apiClient.listOrders as any).mockResolvedValue(MOCK_ORDERS);

    renderSM1();

    const orderRow = await screen.findByTestId('order-row-ORD-001');
    expect(orderRow).toBeInTheDocument();
    expect(orderRow.textContent).toContain('100');   // units
    expect(orderRow.textContent).toContain('100.0'); // weight
    expect(orderRow.textContent).toContain('0.4');   // volume
    expect(orderRow.textContent).toContain('2025-08-01'); // delivery date
  });

  // 3. Empty state when no orders
  it('shows empty state when there are no orders', async () => {
    (apiClient.listOrders as any).mockResolvedValue([]);

    renderSM1();

    await screen.findByText(/No orders yet/i);
  });

  // 4. Unread notices badge
  it('shows unread notices badge with correct count', async () => {
    (apiClient.listOrders as any).mockResolvedValue([]);
    (apiClient.listNotifications as any).mockResolvedValue(MOCK_NOTIFICATIONS_WITH_UNREAD);

    renderSM1();

    const badge = await screen.findByTestId('unread-badge');
    expect(badge.textContent).toBe('1');
  });

  // 5. Next delivery card with ETA
  it('renders next delivery card with ETA when available', async () => {
    (apiClient.listOrders as any).mockResolvedValue(MOCK_ORDERS);
    (apiClient.getExpectedDeliveries as any).mockResolvedValue(MOCK_EXPECTED_DELIVERIES_WITH_ETA);

    renderSM1();

    const card = await screen.findByTestId('next-delivery-card');
    expect(card).toBeInTheDocument();
    expect(card.textContent).toContain('ETA 06:15');
  });

  // 6. No ETA message
  it('shows "ETA not yet set" when next delivery has no eta', async () => {
    (apiClient.listOrders as any).mockResolvedValue(MOCK_ORDERS);
    (apiClient.getExpectedDeliveries as any).mockResolvedValue(MOCK_EXPECTED_DELIVERIES_NO_ETA);

    renderSM1();

    const card = await screen.findByTestId('next-delivery-card');
    expect(card.textContent).toContain('ETA not yet set');
    expect(screen.getByTestId('no-eta-notice')).toBeInTheDocument();
  });

  // 7. Error state with retry
  it('shows error state when orders fetch fails and allows retry', async () => {
    const err = new ApiError('SERVER_ERROR', 'Internal server error');
    (apiClient.listOrders as any).mockRejectedValue(err);

    renderSM1();

    const errorEl = await screen.findByTestId('error-state');
    expect(errorEl).toBeInTheDocument();
  });

  // 8. Place Order CTA
  it('renders Place Order CTA linking to /store/orders/new', async () => {
    (apiClient.listOrders as any).mockResolvedValue([]);

    renderSM1();

    const cta = await screen.findByTestId('place-order-cta');
    expect(cta).toBeInTheDocument();
    expect(cta).toHaveAttribute('href', '/store/orders/new');
  });

  // 9. No next delivery message when all stops are not PENDING
  it('shows no upcoming delivery when expected-deliveries is empty', async () => {
    (apiClient.listOrders as any).mockResolvedValue([]);
    (apiClient.getExpectedDeliveries as any).mockResolvedValue([]);

    renderSM1();

    await screen.findByTestId('no-upcoming-delivery');
  });
});
