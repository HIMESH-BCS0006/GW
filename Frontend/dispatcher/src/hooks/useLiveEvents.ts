import { useEffect, useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';

export type ConnectionStatus = 'online' | 'polling' | 'disconnected';

export function useLiveEvents() {
  const [status, setStatus] = useState<ConnectionStatus>('polling');
  const queryClient = useQueryClient();

  useEffect(() => {
    // TODO: Stream-token issuing endpoint (e.g. POST /auth/stream-token) is not in openapi.yaml.
    // We fall back to 15s polling and attempt EventSource connection if a stream_token is present in storage.
    const token = localStorage.getItem('token') || sessionStorage.getItem('token');
    const streamToken = localStorage.getItem('stream_token');

    let eventSource: EventSource | null = null;
    let pollingInterval: NodeJS.Timeout | null = null;

    const setupPolling = () => {
      setStatus('polling');
      pollingInterval = setInterval(() => {
        // Refetch active query caches on 15s interval fallback
        queryClient.invalidateQueries({ queryKey: ['/dashboard'] });
        queryClient.invalidateQueries({ queryKey: ['/dispatch/queue'] });
        queryClient.invalidateQueries({ queryKey: ['/plans'] });
        queryClient.invalidateQueries({ queryKey: ['/monitoring/live'] });
        queryClient.invalidateQueries({ queryKey: ['/alerts'] });
      }, 15000);
    };

    if (streamToken) {
      const baseUrl = (import.meta as any).env?.VITE_API_BASE_URL || 'http://localhost:4000/api/v1';
      const sseUrl = `${baseUrl}/events/stream?stream_token=${encodeURIComponent(streamToken)}`;

      try {
        eventSource = new EventSource(sseUrl);

        eventSource.onopen = () => {
          setStatus('online');
        };

        eventSource.onmessage = (event) => {
          try {
            const data = JSON.parse(event.data);
            if (data?.type) {
              queryClient.invalidateQueries();
            }
          } catch (e) {
            queryClient.invalidateQueries();
          }
        };

        eventSource.onerror = () => {
          if (eventSource) {
            eventSource.close();
            eventSource = null;
          }
          setupPolling();
        };
      } catch (err) {
        setupPolling();
      }
    } else {
      setupPolling();
    }

    return () => {
      if (eventSource) {
        eventSource.close();
      }
      if (pollingInterval) {
        clearInterval(pollingInterval);
      }
    };
  }, [queryClient]);

  return { connectionStatus: status };
}
