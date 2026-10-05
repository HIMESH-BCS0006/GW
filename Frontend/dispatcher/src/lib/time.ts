/**
 * Time helpers for Asia/Colombo (UTC+05:30) timezone.
 */

export const COLOMBO_TIMEZONE = 'Asia/Colombo';

export function formatColomboDateTime(input?: string | Date | null): string {
  if (!input) return '-';
  try {
    const date = typeof input === 'string' ? new Date(input) : input;
    if (isNaN(date.getTime())) return String(input);
    return date.toLocaleString('en-GB', {
      timeZone: COLOMBO_TIMEZONE,
      year: 'numeric',
      month: 'short',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
    });
  } catch (e) {
    return String(input);
  }
}

export function formatClockTime(input?: string | Date | null): string {
  if (!input) return '--:--';
  try {
    // If input is a clock string like "16:00" or "08:30"
    if (typeof input === 'string' && /^\d{2}:\d{2}(:\d{2})?$/.test(input)) {
      return input.substring(0, 5);
    }
    const date = typeof input === 'string' ? new Date(input) : input;
    if (isNaN(date.getTime())) return String(input);
    return date.toLocaleTimeString('en-GB', {
      timeZone: COLOMBO_TIMEZONE,
      hour: '2-digit',
      minute: '2-digit',
      hour12: false,
    });
  } catch (e) {
    return String(input);
  }
}

export function formatDurationMinutes(minutes?: number | null): string {
  if (minutes == null || isNaN(minutes)) return '-';
  if (minutes < 60) {
    return `${minutes} mins`;
  }
  const hrs = Math.floor(minutes / 60);
  const mins = minutes % 60;
  return mins > 0 ? `${hrs} hrs ${mins} mins` : `${hrs} hrs`;
}
