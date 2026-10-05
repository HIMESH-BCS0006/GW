import React from 'react';
import { renderHook, waitFor } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useBusinessClock, formatColomboTime, formatColomboDate } from '../../../shared/hooks/useBusinessClock';
import { apiClient } from '../../../shared/api/client';

vi.mock('../../../shared/api/client', () => ({
  apiClient: {
    getRefConfig: vi.fn(),
  },
}));

describe('useBusinessClock Hook', () => {
  const createWrapper = () => {
    const queryClient = new QueryClient({
      defaultOptions: { queries: { retry: false } },
    });
    return ({ children }: { children: React.ReactNode }) => (
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    );
  };

  it('calculates business clock cutoff and time in Asia/Colombo', async () => {
    (apiClient.getRefConfig as any).mockResolvedValue({
      cutoff_time: '16:00',
      business_clock: '2025-07-31T14:00:00+05:30',
      demo_mode: true,
      budget_fresh_min: 270,
      budget_style_tech_min: 480,
      unit_constants: {},
    });

    const { result } = renderHook(() => useBusinessClock(), {
      wrapper: createWrapper(),
    });

    await waitFor(() => expect(result.current.isLoading).toBe(false));

    expect(result.current.cutoffTime).toBe('16:00');
    expect(result.current.formattedClockTime).toBe('14:00');
    expect(result.current.formattedClockDate).toBe('2025-07-31');
    expect(result.current.isCutoffPassed).toBe(false);
    expect(result.current.minutesUntilCutoff).toBe(120); // 16:00 - 14:00 = 120 minutes
  });

  it('correctly flags isCutoffPassed when business clock is past 16:00', async () => {
    (apiClient.getRefConfig as any).mockResolvedValue({
      cutoff_time: '16:00',
      business_clock: '2025-07-31T16:30:00+05:30',
      demo_mode: true,
    });

    const { result } = renderHook(() => useBusinessClock(), {
      wrapper: createWrapper(),
    });

    await waitFor(() => expect(result.current.isLoading).toBe(false));

    expect(result.current.formattedClockTime).toBe('16:30');
    expect(result.current.isCutoffPassed).toBe(true);
    expect(result.current.minutesUntilCutoff).toBe(-30);
  });

  it('formats UTC ISO strings to Asia/Colombo time HH:MM and date YYYY-MM-DD', () => {
    const utcTime = '2025-08-01T00:30:00Z'; // 06:00 AM Asia/Colombo
    expect(formatColomboTime(utcTime)).toBe('06:00');
    expect(formatColomboDate(utcTime)).toBe('2025-08-01');
  });
});
