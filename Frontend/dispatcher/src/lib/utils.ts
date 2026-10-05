/**
 * Utility functions for date, time, and formatting in Asia/Colombo timezone.
 */

export function formatDateTime(utcString?: string): string {
  if (!utcString) return '-';
  try {
    const date = new Date(utcString);
    return date.toLocaleString('en-GB', {
      timeZone: 'Asia/Colombo',
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  } catch (e) {
    return utcString;
  }
}

export function formatTime(utcString?: string): string {
  if (!utcString) return '-';
  try {
    const date = new Date(utcString);
    return date.toLocaleTimeString('en-GB', {
      timeZone: 'Asia/Colombo',
      hour: '2-digit',
      minute: '2-digit',
    });
  } catch (e) {
    return utcString;
  }
}

export function getStatusColor(status: string): string {
  switch (status.toUpperCase()) {
    case 'CONFIRMED':
    case 'DELIVERED':
    case 'LOADED':
      return 'bg-green-100 text-green-800';
    case 'IN_PROGRESS':
    case 'SCHEDULED':
    case 'PLANNED':
      return 'bg-blue-100 text-blue-800';
    case 'SUBMITTED':
    case 'PENDING':
      return 'bg-yellow-100 text-yellow-800';
    case 'DEFERRED':
    case 'CANCELLED':
    case 'BLOCKED':
      return 'bg-red-100 text-red-800';
    default:
      return 'bg-gray-100 text-gray-800';
  }
}
