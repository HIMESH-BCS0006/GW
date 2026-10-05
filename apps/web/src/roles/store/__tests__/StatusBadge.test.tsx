import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { StatusBadge, OrderState } from '../../../shared/components/StatusBadge';

describe('StatusBadge Component', () => {
  const states: OrderState[] = [
    'SUBMITTED',
    'PLANNED',
    'SCHEDULED',
    'LOADED',
    'IN_TRANSIT',
    'DELIVERED',
    'PARTIALLY_DELIVERED',
    'DEFERRED',
    'CANCELLED',
  ];

  states.forEach((state) => {
    it(`renders correctly for state: ${state}`, () => {
      render(<StatusBadge status={state} />);
      const badge = screen.getByTestId('status-badge');
      expect(badge).toBeInTheDocument();
      expect(badge.textContent?.toUpperCase()).toContain(state.replace('_', ' '));
    });
  });

  it('handles unknown status gracefully', () => {
    render(<StatusBadge status="CUSTOM_STATUS" />);
    const badge = screen.getByTestId('status-badge');
    expect(badge).toBeInTheDocument();
    expect(badge.textContent).toBe('CUSTOM_STATUS');
  });
});
