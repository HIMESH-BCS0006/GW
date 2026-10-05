import React, { createContext, useContext, useState, useEffect } from 'react';
import { User } from '../api/generated/models';
import { getCurrentUser } from '../api/generated/auth/auth';
import { DEFAULT_DEPOT, DEFAULT_DELIVERY_DATE } from '../lib/constants';

interface AuthContextType {
  user: User | null;
  token: string | null;
  role: string | null;
  depotIds: string[];
  selectedDepot: string;
  setSelectedDepot: (depot: string) => void;
  deliveryDate: string;
  setDeliveryDate: (date: string) => void;
  login: (token: string, user: User) => void;
  logout: () => void;
  isLoading: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [token, setToken] = useState<string | null>(() => {
    const urlParams = new URLSearchParams(window.location.search);
    const tokenFromUrl = urlParams.get('token');
    if (tokenFromUrl) {
      localStorage.setItem('token', tokenFromUrl);
      window.history.replaceState({}, document.title, window.location.pathname);
      return tokenFromUrl;
    }
    return localStorage.getItem('token') || sessionStorage.getItem('token');
  });
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [selectedDepot, setSelectedDepot] = useState<string>(DEFAULT_DEPOT);
  const [deliveryDate, setDeliveryDate] = useState<string>(DEFAULT_DELIVERY_DATE);

  useEffect(() => {
    if (!token) {
      setUser(null);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    getCurrentUser()
      .then((data) => {
        setUser(data);
        if (data.depot_ids && data.depot_ids.length > 0) {
          setSelectedDepot(data.depot_ids[0]);
        }
      })
      .catch((err) => {
        // Token invalid or expired
        setToken(null);
        localStorage.removeItem('token');
        sessionStorage.removeItem('token');
        setUser(null);
      })
      .finally(() => {
        setIsLoading(false);
      });
  }, [token]);

  const handleLogin = (newToken: string, newUser: User) => {
    localStorage.setItem('token', newToken);
    setToken(newToken);
    setUser(newUser);
    if (newUser.depot_ids && newUser.depot_ids.length > 0) {
      setSelectedDepot(newUser.depot_ids[0]);
    }
  };

  const handleLogout = () => {
    localStorage.removeItem('token');
    sessionStorage.removeItem('token');
    setToken(null);
    setUser(null);
    const host = window.location.hostname || 'localhost';
    window.location.href = `http://${host}`;
  };

  const role = user?.role || null;
  const depotIds = user?.depot_ids || [DEFAULT_DEPOT, 'Kandy'];

  return (
    <AuthContext.Provider
      value={{
        user,
        token,
        role,
        depotIds,
        selectedDepot,
        setSelectedDepot,
        deliveryDate,
        setDeliveryDate,
        login: handleLogin,
        logout: handleLogout,
        isLoading,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export function useAuth(): AuthContextType {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
