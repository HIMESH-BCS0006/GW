import '@testing-library/jest-dom';
import React from 'react';
import { render, screen } from '@testing-library/react';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import { describe, it, expect, vi } from 'vitest';
import { RequireDispatcher } from '../components/RequireDispatcher';
import * as AuthContextModule from '../context/AuthContext';

describe('Route Guard & Role Enforcement', () => {
  it('redirects unauthenticated users to /login page', () => {
    vi.spyOn(AuthContextModule, 'useAuth').mockReturnValue({
      user: null,
      token: null,
      role: null,
      depotIds: [],
      selectedDepot: 'Peliyagoda',
      setSelectedDepot: vi.fn(),
      deliveryDate: '2025-08-01',
      setDeliveryDate: vi.fn(),
      login: vi.fn(),
      logout: vi.fn(),
      isLoading: false,
    });

    render(
      <MemoryRouter initialEntries={['/dashboard']}>
        <Routes>
          <Route path="/login" element={<div>Mock Login Page</div>} />
          <Route
            path="/dashboard"
            element={
              <RequireDispatcher>
                <div>Protected Dashboard</div>
              </RequireDispatcher>
            }
          />
        </Routes>
      </MemoryRouter>
    );

    expect(screen.getByText('Mock Login Page')).toBeInTheDocument();
    expect(screen.queryByText('Protected Dashboard')).not.toBeInTheDocument();
  });

  it('displays WrongRolePage when user has non-dispatcher role', () => {
    vi.spyOn(AuthContextModule, 'useAuth').mockReturnValue({
      user: {
        id: 'USR002',
        username: 'driver@waypoint.test',
        role: 'driver',
        depot_ids: [],
        display_name: 'Lead Driver',
      },
      token: 'fake-driver-token',
      role: 'driver',
      depotIds: [],
      selectedDepot: 'Peliyagoda',
      setSelectedDepot: vi.fn(),
      deliveryDate: '2025-08-01',
      setDeliveryDate: vi.fn(),
      login: vi.fn(),
      logout: vi.fn(),
      isLoading: false,
    });

    render(
      <MemoryRouter initialEntries={['/dashboard']}>
        <Routes>
          <Route
            path="/dashboard"
            element={
              <RequireDispatcher>
                <div>Protected Dashboard</div>
              </RequireDispatcher>
            }
          />
        </Routes>
      </MemoryRouter>
    );

    expect(screen.getByText('Access Restricted')).toBeInTheDocument();
    expect(screen.getByText(/driver/i)).toBeInTheDocument();
    expect(screen.queryByText('Protected Dashboard')).not.toBeInTheDocument();
  });

  it('renders protected route when logged in as dispatcher', () => {
    vi.spyOn(AuthContextModule, 'useAuth').mockReturnValue({
      user: {
        id: 'USR001',
        username: 'dispatcher@waypoint.test',
        role: 'dispatcher',
        depot_ids: ['Peliyagoda', 'Kandy'],
        display_name: 'Lead Dispatcher',
      },
      token: 'fake-dispatcher-token',
      role: 'dispatcher',
      depotIds: ['Peliyagoda', 'Kandy'],
      selectedDepot: 'Peliyagoda',
      setSelectedDepot: vi.fn(),
      deliveryDate: '2025-08-01',
      setDeliveryDate: vi.fn(),
      login: vi.fn(),
      logout: vi.fn(),
      isLoading: false,
    });

    render(
      <MemoryRouter initialEntries={['/dashboard']}>
        <Routes>
          <Route
            path="/dashboard"
            element={
              <RequireDispatcher>
                <div>Protected Dashboard</div>
              </RequireDispatcher>
            }
          />
        </Routes>
      </MemoryRouter>
    );

    expect(screen.getByText('Protected Dashboard')).toBeInTheDocument();
  });
});
