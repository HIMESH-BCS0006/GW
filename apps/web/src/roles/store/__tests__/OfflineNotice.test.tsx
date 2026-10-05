import { render, screen, act } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { OfflineNotice } from '../../../shared/components/OfflineNotice';

describe('OfflineNotice Component', () => {
  it('does not render when online', () => {
    vi.stubGlobal('navigator', { onLine: true });
    render(<OfflineNotice />);
    expect(screen.queryByTestId('offline-notice')).not.toBeInTheDocument();
  });

  it('renders "Connect to continue" notice when navigator.onLine is false', () => {
    vi.stubGlobal('navigator', { onLine: false });
    render(<OfflineNotice message="Connect to continue" />);

    const notice = screen.getByTestId('offline-notice');
    expect(notice).toBeInTheDocument();
    expect(notice.textContent).toContain('Connect to continue');
    expect(notice.textContent).toContain('Store Manager is online-only');
  });

  it('responds dynamically to offline/online window events', () => {
    vi.stubGlobal('navigator', { onLine: true });
    render(<OfflineNotice />);

    expect(screen.queryByTestId('offline-notice')).not.toBeInTheDocument();

    act(() => {
      window.dispatchEvent(new Event('offline'));
    });

    expect(screen.getByTestId('offline-notice')).toBeInTheDocument();

    act(() => {
      window.dispatchEvent(new Event('online'));
    });

    expect(screen.queryByTestId('offline-notice')).not.toBeInTheDocument();
  });
});
