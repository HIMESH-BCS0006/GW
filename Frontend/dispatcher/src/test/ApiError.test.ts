import { describe, it, expect } from 'vitest';
import { ApiError } from '../api/http';

describe('ApiError Envelope Parsing', () => {
  it('parses error envelope into typed ApiError with code, message, and details.violations[]', () => {
    const errorEnvelope = {
      code: 'CONSTRAINT_VIOLATION',
      message: 'Vehicle weight capacity exceeded for trip',
      details: {
        violations: [
          {
            rule: 'H3_MAX_WEIGHT',
            message: 'Vehicle maximum weight capacity exceeded',
            actual: 4500,
            limit: 4000,
          },
        ],
      },
    };

    const apiError = new ApiError(errorEnvelope);

    expect(apiError).toBeInstanceOf(Error);
    expect(apiError).toBeInstanceOf(ApiError);
    expect(apiError.name).toBe('ApiError');
    expect(apiError.code).toBe('CONSTRAINT_VIOLATION');
    expect(apiError.message).toBe('Vehicle weight capacity exceeded for trip');
    expect(apiError.details?.violations).toHaveLength(1);
    expect(apiError.details?.violations?.[0].rule).toBe('H3_MAX_WEIGHT');
    expect(apiError.details?.violations?.[0].actual).toBe(4500);
    expect(apiError.details?.violations?.[0].limit).toBe(4000);
  });
});
