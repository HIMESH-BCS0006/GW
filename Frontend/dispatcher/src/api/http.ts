import Axios, { AxiosRequestConfig, AxiosError } from 'axios';

export interface Violation {
  rule: string;
  message: string;
  actual?: number | string | boolean;
  limit?: number | string | boolean;
}

export interface ApiErrorDetails {
  violations?: Violation[];
  [key: string]: unknown;
}

export interface ApiErrorEnvelope {
  code: string;
  message: string;
  details?: ApiErrorDetails;
}

export class ApiError extends Error {
  code: string;
  details?: ApiErrorDetails;

  constructor(envelope: ApiErrorEnvelope) {
    super(envelope.message || 'API Error');
    this.name = 'ApiError';
    this.code = envelope.code || 'UNKNOWN_ERROR';
    this.details = envelope.details;
  }
}

const getBaseUrl = (): string => {
  if (typeof process !== 'undefined' && process.env && process.env.VITE_API_BASE_URL) {
    return process.env.VITE_API_BASE_URL;
  }
  try {
    const metaEnv = (import.meta as any).env;
    if (metaEnv && metaEnv.VITE_API_BASE_URL) {
      return metaEnv.VITE_API_BASE_URL;
    }
  } catch (e) {
    // ignore
  }
  if (typeof window !== 'undefined' && window.location && window.location.hostname) {
    return `http://${window.location.hostname}:8000/api/v1`;
  }
  // Docker API runs on port 8000 with /api/v1 prefix
  return 'http://localhost:8000/api/v1';
};

export const AXIOS_INSTANCE = Axios.create({
  baseURL: getBaseUrl(),
});

AXIOS_INSTANCE.interceptors.request.use((config) => {
  // Skip auth header for login endpoint
  if (config.url?.includes('/auth/login')) {
    return config;
  }
  const token =
    (typeof localStorage !== 'undefined' && localStorage.getItem('token')) ||
    (typeof sessionStorage !== 'undefined' && sessionStorage.getItem('token')) ||
    'mock-bearer-token';
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

AXIOS_INSTANCE.interceptors.response.use(
  (response) => response,
  (error: AxiosError<any>) => {
    if (error.response && error.response.data) {
      const data = error.response.data;
      if (data.error && typeof data.error === 'object') {
        return Promise.reject(new ApiError(data.error));
      } else if (data.code && data.message) {
        return Promise.reject(new ApiError(data));
      }
    }
    return Promise.reject(error);
  }
);

// Custom mutator function required by Orval
export const customInstance = <T>(
  config: AxiosRequestConfig,
  options?: AxiosRequestConfig
): Promise<T> => {
  const source = Axios.CancelToken.source();
  const promise = AXIOS_INSTANCE({
    ...config,
    ...options,
    cancelToken: source.token,
  }).then(({ data }) => data);

  // @ts-ignore
  promise.cancel = () => {
    source.cancel('Query was cancelled');
  };

  return promise;
};

export default customInstance;
