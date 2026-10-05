import React from 'react';
import { Routes, Route, Outlet } from 'react-router-dom';
import { LoginPage } from '../pages/LoginPage';
import { DashboardPage } from '../pages/DashboardPage';
import { OrdersPage } from '../pages/OrdersPage';
import { PlanningPage } from '../pages/PlanningPage';
import { DeferredPage } from '../pages/DeferredPage';
import { LoadingPage } from '../pages/LoadingPage';
import { MonitoringPage } from '../pages/MonitoringPage';
import { NotFoundPage } from '../pages/NotFoundPage';
import { Layout } from '../components/Layout';
import { RequireDispatcher } from '../components/RequireDispatcher';

export const AppRoutes: React.FC = () => {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />

      <Route
        element={
          <RequireDispatcher>
            <Layout>
              <Outlet />
            </Layout>
          </RequireDispatcher>
        }
      >
        <Route path="/" element={<DashboardPage />} />
        <Route path="/orders" element={<OrdersPage />} />
        <Route path="/planning" element={<PlanningPage />} />
        <Route path="/deferred" element={<DeferredPage />} />
        <Route path="/loading" element={<LoadingPage />} />
        <Route path="/monitoring" element={<MonitoringPage />} />
      </Route>

      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  );
};
