import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { ErrorState } from '../../../shared/components/ErrorState';
import { ApiError } from '../../../shared/api/client';

describe('ErrorState Component', () => {
  it('renders standard error format { error: { code, message } }', () => {
    const errorObj = {
      error: {
        code: 'NOT_OPERATING_DAY',
        message: 'Delivery date is not an operating day',
      },
    };

    render(<ErrorState error={errorObj} />);

    expect(screen.getByText('[NOT_OPERATING_DAY]')).toBeInTheDocument();
    expect(screen.getByText('Delivery date is not an operating day')).toBeInTheDocument();
  });

  it('renders ApiError instance correctly', () => {
    const apiError = new ApiError('FORBIDDEN_SCOPE', 'Access denied to target outlet');

    render(<ErrorState error={apiError} />);

    expect(screen.getByText('[FORBIDDEN_SCOPE]')).toBeInTheDocument();
    expect(screen.getByText('Access denied to target outlet')).toBeInTheDocument();
  });

  it('calls onRetry when retry button is clicked', () => {
    const onRetryMock = vi.fn();
    render(<ErrorState error={new Error('Network failure')} onRetry={onRetryMock} />);

    const retryButton = screen.getByRole('button', { name: /retry/i });
    expect(retryButton).toBeInTheDocument();

    fireEvent.click(retryButton);
    expect(onRetryMock).toHaveBeenCalledTimes(1);
  });
});
