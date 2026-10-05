import React, { useEffect, useState } from 'react';
import { WifiOff } from 'lucide-react';

interface OfflineNoticeProps {
  message?: string;
}

export const OfflineNotice: React.FC<OfflineNoticeProps> = ({
  message = 'Connect to continue',
}) => {
  const [isOffline, setIsOffline] = useState(!navigator.onLine);

  useEffect(() => {
    const handleOnline = () => setIsOffline(false);
    const handleOffline = () => setIsOffline(true);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  if (!isOffline) return null;

  return (
    <div
      data-testid="offline-notice"
      className="sticky top-0 z-50 flex items-center justify-center gap-2 bg-amber-600 px-4 py-2.5 text-sm font-semibold text-white shadow-md"
    >
      <WifiOff className="h-4 w-4 shrink-0" />
      <span>You are offline. {message} (Store Manager is online-only).</span>
    </div>
  );
};
