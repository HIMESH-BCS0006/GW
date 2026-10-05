import React, { createContext, useContext, useEffect, useState } from 'react';
import { apiClient, setAuthToken, clearAuthToken, getAuthToken } from '../api/client';

export interface UserProfile {
  id: string;
  username: string;
  role: 'dispatcher' | 'loader' | 'driver' | 'store_manager';
  outlet_id?: string;
  vehicle_id?: string;
  depot_ids?: string[];
  display_name: string;
}

interface AuthContextType {
  user: UserProfile | null;
  token: string | null;
  isLoading: boolean;
  login: (username: string, password: string) => Promise<void>;
  logout: () => void;
  setUser: (user: UserProfile | null) => void;
}

export const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function normalizeUserRole(
  username: string,
  user?: Partial<UserProfile> | null
): UserProfile['role'] {
  const normalizedUsername = (username || user?.username || '').toLowerCase();

  if (normalizedUsername.includes('dispatcher')) {
    return 'dispatcher';
  }

  if (normalizedUsername.includes('loader')) {
    return 'loader';
  }

  if (normalizedUsername.includes('driver')) {
    return 'driver';
  }

  if (normalizedUsername.includes('store') || normalizedUsername.includes('manager')) {
    return 'store_manager';
  }

  return user?.role ?? 'store_manager';
}

export function normalizeUserProfile(
  user: Partial<UserProfile> | null | undefined,
  preferredUsername?: string
): UserProfile | null {
  if (!user) {
    return null;
  }

  const username = preferredUsername || user.username || '';

  return {
    ...user,
    username,
    role: normalizeUserRole(username, user),
  } as UserProfile;
}

function parseJwt(token: string): any {
  try {
    const base64Url = token.split('.')[1];
    if (!base64Url) return null;
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    const jsonPayload = decodeURIComponent(
      atob(base64)
        .split('')
        .map((c) => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
        .join('')
    );
    return JSON.parse(jsonPayload);
  } catch (e) {
    return null;
  }
}

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<UserProfile | null>(null);
  const [token, setTokenState] = useState<string | null>(getAuthToken());
  const [isLoading, setIsLoading] = useState<boolean>(true);

  useEffect(() => {
    async function loadUser() {
      const urlParams = new URLSearchParams(window.location.search);
      const tokenFromUrl = urlParams.get('token');
      if (tokenFromUrl) {
        setAuthToken(tokenFromUrl);
        setTokenState(tokenFromUrl);
        window.history.replaceState({}, document.title, window.location.pathname);
      }

      const activeToken = tokenFromUrl || getAuthToken();
      if (activeToken) {
        const decoded = parseJwt(activeToken);
        if (decoded) {
          const fallbackUsername = decoded.username || decoded.sub || 'storemanager@waypoint.com';
          setUser(
            normalizeUserProfile(
              {
                id: decoded.user_id || decoded.sub || fallbackUsername,
                username: fallbackUsername,
                role: decoded.role || 'store_manager',
                outlet_id: decoded.outlet_id || 'OUT004',
                vehicle_id: decoded.vehicle_id,
                depot_ids: decoded.depot_ids || [],
                display_name: decoded.display_name || fallbackUsername,
              },
              fallbackUsername
            )
          );
        }

        try {
          const profile = await apiClient.getMe();
          if (profile) {
            setUser(normalizeUserProfile(profile, profile?.username));
          }
        } catch (err) {
          console.warn('Could not refresh store manager profile from /me, using JWT token claims:', err);
          if (!decoded) {
            clearAuthToken();
            setTokenState(null);
            setUser(null);
          }
        }
      }
      setIsLoading(false);
    }
    loadUser();
  }, []);

  const login = async (username: string, password: string) => {
    setIsLoading(true);
    try {
      const res = await apiClient.login({ username, password });
      setAuthToken(res.access_token);
      setTokenState(res.access_token);

      const profile = normalizeUserProfile(
        {
          id: res.user_id,
          username: res.username,
          role: res.role as UserProfile['role'],
          outlet_id: res.outlet_id,
          vehicle_id: res.vehicle_id,
          depot_ids: res.depot_ids,
          display_name: res.display_name,
        },
        res.username
      );

      setUser(profile);
    } catch (err) {
      setIsLoading(false);
      throw err;
    }
    setIsLoading(false);
  };

  const logout = () => {
    clearAuthToken();
    setTokenState(null);
    setUser(null);
    const host = window.location.hostname || 'localhost';
    window.location.href = `http://${host}`;
  };

  return (
    <AuthContext.Provider value={{ user, token, isLoading, login, logout, setUser }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
