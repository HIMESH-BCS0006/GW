/**
 * Simple notification helper used during mock development.
 * In production this would call a real messaging service.
 */
export function sendNotification(recipients: string[], message: string) {
  // For now just log to console – the UI can show a toast if desired.
  console.log('🔔 Notification sent', { recipients, message });
  // Optionally integrate a toast library (e.g., react-hot-toast) here.
}
