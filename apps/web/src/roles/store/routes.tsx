import React from 'react';
import { RouteObject } from 'react-router-dom';
import { RequireAuth } from '../../shared/auth/RequireAuth';
import { StoreManagerLayout } from './components/StoreManagerLayout';
import { SM1HomePage } from './pages/SM1HomePage';
import { SMOrdersPage } from './pages/SMOrdersPage';
import { SM2PlaceOrderPage } from './pages/SM2PlaceOrderPage';
import { SM3NotificationsPage } from './pages/SM3NotificationsPage';
import { SM4TrackingPage } from './pages/SM4TrackingPage';
import { SM5ReceiptPage } from './pages/SM5ReceiptPage';

export const storeManagerRoutes: RouteObject = {
  path: 'store',
  element: (
    <RequireAuth allowedRoles={['store_manager']}>
      <StoreManagerLayout />
    </RequireAuth>
  ),
  children: [
    { index: true, element: <SM1HomePage /> },
    { path: 'orders/new', element: <SM2PlaceOrderPage /> },
    { path: 'notifications', element: <SM3NotificationsPage /> },
    { path: 'orders', element: <SMOrdersPage /> },
    { path: 'orders/:id', element: <SM4TrackingPage /> },
    { path: 'orders/:id/receipt', element: <SM5ReceiptPage /> },
  ],
};
