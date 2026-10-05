import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, beforeEach, vi } from 'vitest';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { SM5ReceiptPage } from '../pages/SM5ReceiptPage';
import { ApiError, apiClient } from '../../../shared/api/client';

vi.mock('../../../shared/api/client', async (importOriginal) => {
  const actual = await importOriginal<any>();
  return {
    ...actual,
    apiClient: {
      ...actual.apiClient,
      getOrderById: vi.fn(),
      recordReceipt: vi.fn(),
    },
  };
});

const ORDER = {
  id: 'ORD-001',
  outlet_id: 'OUT004',
  delivery_date: '2025-08-01',
  placed_at: '2025-07-31T14:00:00+05:30',
  status: 'DELIVERED',
  temp_requirement: 'chilled' as const,
  order_units: 10,
  order_weight_kg: 12,
  order_volume_m3: 0.05,
  rolled_over: false,
  deferral_count: 0,
  stop_id: 'STOP-001',
};

function renderReceipt() {
  const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter initialEntries={['/store/orders/ORD-001/receipt']}>
        <Routes>
          <Route path="/store/orders/:id/receipt" element={<SM5ReceiptPage />} />
        </Routes>
      </MemoryRouter>
    </QueryClientProvider>,
  );
}

describe('SM5ReceiptPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    (apiClient.getOrderById as any).mockResolvedValue(ORDER);
  });

  it('requires a note for discrepancies', async () => {
    (apiClient.recordReceipt as any).mockResolvedValue({});
    renderReceipt();

    await userEvent.click(await screen.findByLabelText(/Report discrepancy/i));
    await userEvent.click(screen.getByRole('button', { name: 'Submit receipt' }));

    expect(await screen.findByText('A discrepancy note is required.')).toBeInTheDocument();
    expect(apiClient.recordReceipt).not.toHaveBeenCalled();
  });

  it('reuses the same client_op_id after a failed retry', async () => {
    (apiClient.recordReceipt as any)
      .mockRejectedValueOnce(new Error('Network failed'))
      .mockResolvedValueOnce({});
    renderReceipt();

    const submit = await screen.findByRole('button', { name: 'Submit receipt' });
    await userEvent.click(submit);
    await screen.findByText('Network failed');
    await userEvent.click(screen.getByRole('button', { name: 'Submit receipt' }));

    await waitFor(() => expect(apiClient.recordReceipt).toHaveBeenCalledTimes(2));
    expect((apiClient.recordReceipt as any).mock.calls[0][1].client_op_id)
      .toBe((apiClient.recordReceipt as any).mock.calls[1][1].client_op_id);
    expect(await screen.findByText('Receipt already confirmed')).toBeInTheDocument();
  });

  it('shows an already-confirmed state from the order response', async () => {
    (apiClient.getOrderById as any).mockResolvedValue({ ...ORDER, receipt_status: 'CONFIRMED' });
    renderReceipt();

    expect(await screen.findByTestId('receipt-already-confirmed')).toBeInTheDocument();
    expect(apiClient.recordReceipt).not.toHaveBeenCalled();
  });
});
