import { describe, expect, it } from 'vitest';
import { normalizeUserRole } from './AuthContext';

describe('normalizeUserRole', () => {
  it('prefers the store manager role when the login username is a store manager account', () => {
    expect(
      normalizeUserRole('store@waypoint.test', {
        id: 'USR-STORE-001',
        username: 'store@waypoint.test',
        role: 'dispatcher',
        display_name: 'Store Manager',
      })
    ).toBe('store_manager');
  });

  it('keeps dispatcher roles for dispatcher accounts', () => {
    expect(
      normalizeUserRole('dispatcher@waypoint.test', {
        id: 'USR001',
        username: 'dispatcher@waypoint.test',
        role: 'dispatcher',
        display_name: 'Lead Dispatcher',
      })
    ).toBe('dispatcher');
  });
});
