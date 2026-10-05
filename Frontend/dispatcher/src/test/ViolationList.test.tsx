import '@testing-library/jest-dom';
import React from 'react';
import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { ViolationList } from '../components/ViolationList';
import { Violation } from '../api/http';

describe('ViolationList Component', () => {
  it('renders details.violations[] as rule ID, message, and actual vs limit', () => {
    const violations: Violation[] = [
      {
        rule: 'H1_TEMP_CAPABILITY',
        message: 'Chilled order requires refrigerated vehicle',
        actual: 'ambient',
        limit: 'reefer',
      },
      {
        rule: 'H3_MAX_WEIGHT',
        message: 'Vehicle weight capacity exceeded',
        actual: 4200,
        limit: 4000,
      },
    ];

    render(<ViolationList violations={violations} />);

    expect(screen.getByText('Constraint Violations (2)')).toBeInTheDocument();
    expect(screen.getByText('H1_TEMP_CAPABILITY')).toBeInTheDocument();
    expect(screen.getByText('Chilled order requires refrigerated vehicle')).toBeInTheDocument();
    expect(screen.getByText('H3_MAX_WEIGHT')).toBeInTheDocument();
    expect(screen.getByText('Vehicle weight capacity exceeded')).toBeInTheDocument();
    expect(screen.getByText('4200')).toBeInTheDocument();
    expect(screen.getByText('4000')).toBeInTheDocument();
  });

  it('renders nothing when violations list is empty or undefined', () => {
    const { container } = render(<ViolationList violations={[]} />);
    expect(container.firstChild).toBeNull();
  });
});
