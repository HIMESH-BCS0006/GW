import { useGetRefConfig } from '../api/generated/reference/reference';

export interface BusinessNowResult {
  businessNow: Date;
  businessClockStr: string;
  cutoffTime: string;
  demoMode: boolean;
  budgetFreshMin: number;
  budgetStyleTechMin: number;
  isLoading: boolean;
  isError: boolean;
  isBeforeCutoff: boolean;
}

export function useBusinessNow(): BusinessNowResult {
  const { data: config, isLoading, isError } = useGetRefConfig();

  const businessClockStr = config?.business_clock || '2025-07-31T15:30:00+05:30';
  const cutoffTime = config?.cutoff_time || '16:00';
  const demoMode = !!config?.demo_mode;
  const budgetFreshMin = config?.budget_fresh_min ?? 270;
  const budgetStyleTechMin = config?.budget_style_tech_min ?? 480;

  const businessNow = new Date(businessClockStr);

  // Compare businessNow clock time against cutoff_time (e.g., "16:00")
  let isBeforeCutoff = true;
  if (!isNaN(businessNow.getTime()) && cutoffTime) {
    const [cutoffHours, cutoffMinutes] = cutoffTime.split(':').map(Number);
    const colomboHours = Number(
      businessNow.toLocaleTimeString('en-GB', {
        timeZone: 'Asia/Colombo',
        hour: '2-digit',
        hour12: false,
      })
    );
    const colomboMinutes = Number(
      businessNow.toLocaleTimeString('en-GB', {
        timeZone: 'Asia/Colombo',
        minute: '2-digit',
      })
    );

    if (
      colomboHours > cutoffHours ||
      (colomboHours === cutoffHours && colomboMinutes >= cutoffMinutes)
    ) {
      isBeforeCutoff = false;
    }
  }

  return {
    businessNow,
    businessClockStr,
    cutoffTime,
    demoMode,
    budgetFreshMin,
    budgetStyleTechMin,
    isLoading,
    isError,
    isBeforeCutoff,
  };
}
