export interface ApiErrorPayload {
  error: {
    code: string;
    message: string;
    details?: any;
  };
}

export class ApiError extends Error {
  code: string;
  details?: any;

  constructor(code: string, message: string, details?: any) {
    super(message);
    this.name = 'ApiError';
    this.code = code;
    this.details = details;
  }
}

export function getBaseUrl(): string {
  if (typeof window !== 'undefined' && window.location && window.location.hostname) {
    return `http://${window.location.hostname}:8000/api/v1`;
  }
  return import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api/v1';
}

export const getAuthToken = (): string | null => {
  return localStorage.getItem('waypoint_token');
};

export const setAuthToken = (token: string) => {
  localStorage.setItem('waypoint_token', token);
};

export const clearAuthToken = () => {
  localStorage.removeItem('waypoint_token');
};

export async function fetchApi<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<T> {
  const token = getAuthToken();
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const response = await fetch(`${getBaseUrl()}${endpoint}`, {
    ...options,
    headers,
  });

  const contentType = response.headers.get('content-type');
  let data: any = null;
  if (contentType && contentType.includes('application/json')) {
    data = await response.json();
  }

  if (!response.ok) {
    if (data && data.error) {
      throw new ApiError(data.error.code, data.error.message, data.error.details);
    }
    throw new ApiError(
      `HTTP_${response.status}`,
      data?.message || response.statusText || 'An unexpected error occurred'
    );
  }

  return data as T;
}

export const apiClient = {
  // Auth & User
  login: (credentials: { username: string; password: string }) =>
    fetchApi<{
      access_token: string;
      token_type: string;
      user_id: string;
      username: string;
      role: 'dispatcher' | 'loader' | 'driver' | 'store_manager';
      display_name: string;
      depot_ids?: string[];
      outlet_id?: string;
      vehicle_id?: string;
    }>('/auth/login', {
      method: 'POST',
      body: JSON.stringify(credentials),
    }),
  getMe: () => fetchApi<any>('/me'),

  // Reference
  getRefOutlets: () => fetchApi<any[]>('/ref/outlets'),
  getRefVehicles: () => fetchApi<any[]>('/ref/vehicles'),
  getRefCalendar: () => fetchApi<any[]>('/ref/calendar'),
  getRefConfig: () =>
    fetchApi<{
      cutoff_time: string;
      budget_fresh_min: number;
      budget_style_tech_min: number;
      unit_constants: Record<string, any>;
      business_clock: string;
      demo_mode: boolean;
    }>('/ref/config'),

  // Store Manager
  listOrders: () => fetchApi<any[]>('/orders'),
  getOrderById: (id: string) => fetchApi<any>(`/orders/${id}`),
  createOrder: (order: any) =>
    fetchApi<any>('/orders', {
      method: 'POST',
      body: JSON.stringify(order),
    }),
  cancelOrder: (id: string, payload: { reason: string; note?: string }) =>
    fetchApi<any>(`/orders/${id}/cancel`, {
      method: 'POST',
      body: JSON.stringify(payload),
    }),
  getExpectedDeliveries: (outletId: string) =>
    fetchApi<any[]>(`/outlets/${outletId}/expected-deliveries`),
  recordReceipt: (stopId: string, payload: { outcome: 'full' | 'discrepancy'; note?: string; client_op_id?: string }) =>
    fetchApi<any>(`/stops/${stopId}/receipt`, {
      method: 'POST',
      body: JSON.stringify(payload),
    }),
  listNotifications: () => fetchApi<any[]>('/notifications'),
  markNotificationRead: (id: string) =>
    fetchApi<any>(`/notifications/${id}/read`, {
      method: 'POST',
    }),
};
