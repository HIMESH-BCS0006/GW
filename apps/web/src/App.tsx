import { BrowserRouter, Navigate, useRoutes } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from './shared/auth/AuthContext';
import { LoginPage } from './shared/pages/LoginPage';
import { storeManagerRoutes } from './roles/store';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: { retry: 1, refetchOnWindowFocus: false, staleTime: 15_000 },
  },
});

function AppRoutes() {
  return useRoutes([
    { path: '/login', element: <LoginPage /> },
    { path: '/', element: <Navigate to="/store" replace /> },
    storeManagerRoutes, // a RouteObject, with its own children
    { path: '*', element: <Navigate to="/store" replace /> },
  ]);
}

export function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <BrowserRouter>
          <AppRoutes />
        </BrowserRouter>
      </AuthProvider>
    </QueryClientProvider>
  );
}

export default App;