import { useQuery } from '@tanstack/react-query';
import { apiClient } from '../api/client';
import { formatInTimeZone } from 'date-fns-tz';

const COLOMBO_TZ = 'Asia/Colombo';

function toDate(dateInput: string | Date): Date {
  if (dateInput instanceof Date) return dateInput;

  const value = dateInput.trim();
  if (!value) return new Date('Invalid Date');

  const hasExplicitTimezone = /(?:Z|[+-]\d{2}:?\d{2})$/.test(value);
  if (!hasExplicitTimezone && /^\d{4}-\d{2}-\d{2}T/.test(value)) {
    return new Date(`${value}Z`);
  }

  return new Date(value);
}

export interface BusinessClockInfo {
  cutoffTime: string; // "16:00"
  businessClock: string; // ISO string e.g. "2025-07-31T14:00:00+05:30"
  demoMode: boolean;
  budgetFreshMin: number;
  budgetStyleTechMin: number;
  unitConstants: Record<string, any>;
  formattedClockTime: string; // "14:00"
  formattedClockDate: string; // "2025-07-31"
  isCutoffPassed: boolean;
  minutesUntilCutoff: number;
  isLoading: boolean;
  isError: boolean;
}

export function useBusinessClock(): BusinessClockInfo {
  const { data, isLoading, isError } = useQuery({
    queryKey: ['ref', 'config'],
    queryFn: () => apiClient.getRefConfig(),
    staleTime: 60000,
  });

  const businessClockStr = data?.business_clock || '2025-07-31T14:00:00+05:30';
  const cutoffTime = data?.cutoff_time || '16:00';
  const demoMode = data?.demo_mode ?? true;

  // Convert business clock to Asia/Colombo time
  const businessDate = toDate(businessClockStr);
  const formattedClockTime = formatInTimeZone(businessDate, COLOMBO_TZ, 'HH:mm');
  const formattedClockDate = formatInTimeZone(businessDate, COLOMBO_TZ, 'yyyy-MM-dd');

  // Calculate cutoff logic against business clock (NEVER browser clock)
  const [cutoffHour, cutoffMinute] = cutoffTime.split(':').map(Number);
  const [currentHour, currentMinute] = formattedClockTime.split(':').map(Number);

  const currentTotalMin = currentHour * 60 + currentMinute;
  const cutoffTotalMin = cutoffHour * 60 + cutoffMinute;

  const minutesUntilCutoff = cutoffTotalMin - currentTotalMin;
  const isCutoffPassed = minutesUntilCutoff <= 0;

  return {
    cutoffTime,
    businessClock: businessClockStr,
    demoMode,
    budgetFreshMin: data?.budget_fresh_min || 270,
    budgetStyleTechMin: data?.budget_style_tech_min || 480,
    unitConstants: data?.unit_constants || {},
    formattedClockTime,
    formattedClockDate,
    isCutoffPassed,
    minutesUntilCutoff,
    isLoading,
    isError,
  };
}

export function formatColomboTime(dateInput: string | Date): string {
  if (!dateInput) return '';
  const date = toDate(dateInput);
  return formatInTimeZone(date, COLOMBO_TZ, 'HH:mm');
}

export function formatColomboDate(dateInput: string | Date): string {
  if (!dateInput) return '';
  const date = toDate(dateInput);
  return formatInTimeZone(date, COLOMBO_TZ, 'yyyy-MM-dd');
}
