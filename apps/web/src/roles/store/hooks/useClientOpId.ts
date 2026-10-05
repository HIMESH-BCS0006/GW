import { useRef, useCallback } from 'react';

/**
 * Returns a stable UUID v4 generator that keeps the same id across re-renders.
 * The id is reset (new UUID) only when resetClientOpId() is called – which
 * should happen after a *successful* submission so the next order gets a fresh id.
 *
 * Rule: field roles send client_op_id (UUID) on every mutating call; a replay
 * returns the original result (Spec 03 idempotency convention).
 */
export function useClientOpId(): [() => string, () => void] {
  const idRef = useRef<string>(generateUUID());

  const get = useCallback(() => idRef.current, []);

  const reset = useCallback(() => {
    idRef.current = generateUUID();
  }, []);

  return [get, reset];
}

function generateUUID(): string {
  if (typeof crypto !== 'undefined' && crypto.randomUUID) {
    return crypto.randomUUID();
  }
  // Fallback for older environments
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}
