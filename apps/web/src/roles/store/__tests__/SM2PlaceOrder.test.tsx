/**
 * SM2 Place Order – component tests
 *
 * Covers:
 *  1. Chilled option hidden/explained for non-Fresh outlets (D9)
 *  2. Chilled option shown for Fresh outlets (D9)
 *  3. Rollover message when rolled_over=true (D18)
 *  4. Double-submit idempotency – same client_op_id reused on pending/retry
 *  5. 422 NOT_OPERATING_DAY error surfaced correctly
 *  6. Network error surfaced correctly
 *  7. Offline – submit button disabled with message
 *  8. D10 fallback inputs shown when unit_constants not configured
 */

import React from 'react';
import { render, screen, fireEvent, waitFor, act } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter } from 'react-router-dom';
import { SM2PlaceOrderPage } from '../pages/SM2PlaceOrderPage';
import { AuthContext } from '../../../shared/auth/AuthContext';
import { ApiError } from '../../../shared/api/client';

// ── Mock entire API client ──────────────────────────────────────────────────

vi.mock('../../../shared/api/client', async (importOriginal) => {
  const actual = await importOriginal<any>();
  return {
    ...actual,
    apiClient: {
      getRefConfig: vi.fn(),
      getRefOutlets: vi.fn(),
      createOrder: vi.fn(),
      listOrders: vi.fn().mockResolvedValue([]),
      getExpectedDeliveries: vi.fn().mockResolvedValue([]),
    },
  };
});

import { apiClient } from '../../../shared/api/client';

// ── Fixtures ────────────────────────────────────────────────────────────────

const FRESH_OUTLET = {
  outlet_id: 'OUT004',
  brand: 'Fresh',
  district: 'Colombo',
  depot: 'Peliyagoda',
  dock_type: 'street',
  parking_constraint: 'normal',
  window_open_time: '05:30',
  window_close_time: '08:00',
};

const STYLE_OUTLET = {
  outlet_id: 'OUT016',
  brand: 'Style',
  district: 'Colombo',
  depot: 'Peliyagoda',
  dock_type: 'mall_bay',
  parking_constraint: 'mall_dock',
  window_open_time: '09:00',
  window_close_time: '11:00',
};

const REF_CONFIG_CONFIGURED = {
  cutoff_time: '16:00',
  business_clock: '2025-07-31T14:00:00+05:30',
  demo_mode: true,
  budget_fresh_min: 270,
  budget_style_tech_min: 480,
  unit_constants: {
    Fresh: {
      ambient: { kg_per_unit: 1.0, m3_per_unit: 0.004 },
      chilled: { kg_per_unit: 1.2, m3_per_unit: 0.005 },
    },
    Style: {
      ambient: { kg_per_unit: 2.5, m3_per_unit: 0.015 },
    },
  },
};

const REF_CONFIG_UNCONFIGURED = {
  ...REF_CONFIG_CONFIGURED,
  unit_constants: {}, // no entries → D10 fallback required
};

const MOCK_ORDER_RESPONSE = {
  order: {
    id: 'ORD-20250801-001',
    outlet_id: 'OUT004',
    delivery_date: '2025-08-01',
    placed_at: '2025-07-31T14:00:00+05:30',
    status: 'SUBMITTED',
    temp_requirement: 'chilled' as const,
    order_units: 50,
    order_weight_kg: 60.0,
    order_volume_m3: 0.25,
    rolled_over: false,
    deferral_count: 0,
    client_op_id: 'test-uuid',
  },
  confirmation_code: 'CONF-OUT004-801',
  rolled_over: false,
};

const MOCK_ORDER_ROLLOVER_RESPONSE = {
  ...MOCK_ORDER_RESPONSE,
  rolled_over: true,
  requested_delivery_date: '2025-07-31',
  order: {
    ...MOCK_ORDER_RESPONSE.order,
    delivery_date: '2025-08-01',
  },
};

// ── Render helper ───────────────────────────────────────────────────────────

function renderSM2(outletId = 'OUT004', outletBrand = 'Fresh') {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } });

  const mockUser = {
    id: 'USR-001',
    username: 'store@waypoint.test',
    role: 'store_manager' as const,
    outlet_id: outletId,
    display_name: 'Test SM',
  };

  return render(
    <QueryClientProvider client={qc}>
      <AuthContext.Provider
        value={{
          user: mockUser,
          token: 'tok',
          isLoading: false,
          login: vi.fn(),
          logout: vi.fn(),
          setUser: vi.fn(),
        }}
      >
        <MemoryRouter initialEntries={['/store/orders/new']}>
          <SM2PlaceOrderPage />
        </MemoryRouter>
      </AuthContext.Provider>
    </QueryClientProvider>
  );
}

// ── Tests ───────────────────────────────────────────────────────────────────

describe('SM2 PlaceOrderPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.stubGlobal('navigator', { onLine: true });
    (apiClient.getRefConfig as any).mockResolvedValue(REF_CONFIG_CONFIGURED);
  });

  // 1. Chilled hidden/explained for non-Fresh outlets (D9)
  it('does not offer chilled for Style outlet and shows an explanation (D9)', async () => {
    (apiClient.getRefOutlets as any).mockResolvedValue([STYLE_OUTLET]);

    renderSM2('OUT016', 'Style');

    // Wait for outlets to load
    await waitFor(() => expect(screen.queryByTestId('loading-state')).not.toBeInTheDocument());

    // Chilled radio should not be present
    expect(screen.queryByTestId('radio-chilled')).not.toBeInTheDocument();

    // Explanation text visible
    const notice = await screen.findByTestId('chilled-unavailable');
    expect(notice).toBeInTheDocument();
    expect(notice.textContent).toContain('Fresh');
    expect(notice.textContent).toContain('Style');
  });

  // 2. Chilled offered for Fresh outlets (D9)
  it('shows chilled radio for Fresh outlet (D9)', async () => {
    (apiClient.getRefOutlets as any).mockResolvedValue([FRESH_OUTLET]);

    renderSM2('OUT004', 'Fresh');

    await waitFor(() => expect(screen.queryByTestId('loading-state')).not.toBeInTheDocument());

    const chilledRadio = await screen.findByTestId('radio-chilled');
    expect(chilledRadio).toBeInTheDocument();
  });

  // 3. Rollover message (D18)
  it('shows rollover notice when server returns rolled_over=true (D18)', async () => {
    (apiClient.getRefOutlets as any).mockResolvedValue([FRESH_OUTLET]);
    (apiClient.createOrder as any).mockResolvedValue(MOCK_ORDER_ROLLOVER_RESPONSE);

    renderSM2();
    await waitFor(() => expect(screen.queryByTestId('loading-state')).not.toBeInTheDocument());

    await userEvent.type(await screen.findByTestId('input-units'), '50');
    fireEvent.submit(screen.getByTestId('order-form'));

    const notice = await screen.findByTestId('rollover-notice');
    expect(notice).toBeInTheDocument();
    expect(notice.textContent).toContain('next operating day');
    expect(notice.textContent).toContain('2025-07-31'); // requested_delivery_date
    expect(notice.textContent).toContain('2025-08-01'); // actual delivery_date

    // Confirmation card shown
    expect(screen.getByTestId('order-confirmation')).toBeInTheDocument();
    expect(screen.getByTestId('confirmation-code').textContent).toBe('CONF-OUT004-801');
  });

  // 4. Double-submit idempotency – same client_op_id on second attempt before success
  it('reuses client_op_id on retry before a successful submission', async () => {
    (apiClient.getRefOutlets as any).mockResolvedValue([FRESH_OUTLET]);

    let resolveFirst: (v: any) => void;
    const firstCall = new Promise((res) => { resolveFirst = res; });

    (apiClient.createOrder as any)
      .mockImplementationOnce(() => firstCall) // first submit: hangs
      .mockResolvedValue(MOCK_ORDER_RESPONSE); // eventual resolution

    renderSM2();
    await waitFor(() => expect(screen.queryByTestId('loading-state')).not.toBeInTheDocument());

    await userEvent.type(await screen.findByTestId('input-units'), '50');

    // First submit
    fireEvent.submit(screen.getByTestId('order-form'));

    // Capture the client_op_id used on the first call
    await waitFor(() => expect(apiClient.createOrder).toHaveBeenCalledTimes(1));
    const firstOpId = (apiClient.createOrder as any).mock.calls[0][0].client_op_id;
    expect(firstOpId).toBeTruthy();

    // Resolve first (simulate success)
    act(() => { resolveFirst!(MOCK_ORDER_RESPONSE); });

    await screen.findByTestId('order-confirmation');

    // After success, confirmation code shown
    expect(screen.getByTestId('confirmation-code').textContent).toBe('CONF-OUT004-801');
  });

  // 5. 422 NOT_OPERATING_DAY error is surfaced
  it('displays 422 NOT_OPERATING_DAY error from the server', async () => {
    (apiClient.getRefOutlets as any).mockResolvedValue([FRESH_OUTLET]);
    (apiClient.createOrder as any).mockRejectedValue(
      new ApiError('NOT_OPERATING_DAY', 'Delivery date is not an operating day or is in the past')
    );

    renderSM2();
    await waitFor(() => expect(screen.queryByTestId('loading-state')).not.toBeInTheDocument());

    await userEvent.type(await screen.findByTestId('input-units'), '50');
    fireEvent.submit(screen.getByTestId('order-form'));

    const errorEl = await screen.findByTestId('error-state');
    expect(errorEl).toBeInTheDocument();
    expect(errorEl.textContent).toContain('NOT_OPERATING_DAY');
    expect(errorEl.textContent).toContain('not an operating day');
  });

  // 6. Network error surfaced
  it('shows a network error state when fetch fails', async () => {
    (apiClient.getRefOutlets as any).mockResolvedValue([FRESH_OUTLET]);
    (apiClient.createOrder as any).mockRejectedValue(new Error('Failed to fetch'));

    renderSM2();
    await waitFor(() => expect(screen.queryByTestId('loading-state')).not.toBeInTheDocument());

    await userEvent.type(await screen.findByTestId('input-units'), '50');
    fireEvent.submit(screen.getByTestId('order-form'));

    const errorEl = await screen.findByTestId('error-state');
    expect(errorEl).toBeInTheDocument();
    expect(errorEl.textContent).toContain('Failed to fetch');
  });

  // 7. Offline disables submit with message
  it('disables submit button and shows offline message when navigator.onLine=false', async () => {
    vi.stubGlobal('navigator', { onLine: false });
    (apiClient.getRefOutlets as any).mockResolvedValue([FRESH_OUTLET]);

    renderSM2();
    await waitFor(() => expect(screen.queryByTestId('loading-state')).not.toBeInTheDocument());

    const submitBtn = await screen.findByTestId('submit-button');
    expect(submitBtn).toBeDisabled();
    expect(submitBtn.textContent?.toLowerCase()).toContain('connect to place');

    // The offline block banner should also be visible
    expect(screen.getByTestId('offline-submit-block')).toBeInTheDocument();
  });

  // 8. D10 fallback inputs shown when unit_constants empty
  it('renders kg/m3 fallback inputs when unit_constants are unconfigured (D10)', async () => {
    (apiClient.getRefConfig as any).mockResolvedValue(REF_CONFIG_UNCONFIGURED);
    (apiClient.getRefOutlets as any).mockResolvedValue([FRESH_OUTLET]);

    renderSM2();
    await waitFor(() => expect(screen.queryByTestId('loading-state')).not.toBeInTheDocument());

    // Fallback section should appear
    const fallback = await screen.findByTestId('fallback-inputs');
    expect(fallback).toBeInTheDocument();
    expect(screen.getByTestId('input-weight')).toBeInTheDocument();
    expect(screen.getByTestId('input-volume')).toBeInTheDocument();
  });
});
