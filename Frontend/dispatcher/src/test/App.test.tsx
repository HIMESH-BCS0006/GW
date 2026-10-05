import '@testing-library/jest-dom';
import React from 'react';
import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import App from '../App';

describe('Waypoint Dispatcher Console App', () => {
  it('renders application portal and login form initially (smoke test)', () => {
    render(<App />);
    expect(screen.getByText('WAYPOINT')).toBeInTheDocument();
    expect(screen.getByText('Dispatcher Portal')).toBeInTheDocument();
    expect(screen.getByText('Sign In to Dispatcher Console')).toBeInTheDocument();
  });
});
