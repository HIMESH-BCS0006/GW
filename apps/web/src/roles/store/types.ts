/**
 * Types for the Store Manager order domain.
 * Derived directly from docs/api/openapi.yaml CreateOrderRequest / CreateOrderResponse schemas.
 */

export type TemperatureRequirement = 'ambient' | 'chilled';

/** POST /orders request body (Spec 03, D4, D9, D10, D18) */
export interface CreateOrderRequest {
  outlet_id: string;
  /** Omit to let server pick earliest operating day before cutoff (D18) */
  delivery_date?: string;
  temp_requirement: TemperatureRequirement;
  order_units: number;
  /** Fallback override only when unit_constants are unconfigured (D10) */
  order_weight_kg?: number;
  /** Fallback override only when unit_constants are unconfigured (D10) */
  order_volume_m3?: number;
  note?: string;
  /** UUID per submission; reuse on retry for idempotency (Spec 03 conventions) */
  client_op_id: string;
}

/** Order record returned from server (partial – only fields relevant to SM2/SM4) */
export interface Order {
  id: string;
  outlet_id: string;
  delivery_date: string;          // YYYY-MM-DD
  placed_at: string;              // ISO datetime
  status: string;
  temp_requirement: TemperatureRequirement;
  order_units: number;
  order_weight_kg: number;        // Always non-null in responses (D18)
  order_volume_m3: number;        // Always non-null in responses (D18)
  rolled_over: boolean;
  deferral_count: number;
  note?: string;
  cancel_reason?: string;
  trip_id?: string;
  stop_id?: string;
  eta?: string;
  client_op_id?: string;
}

/** POST /orders 201 response (D18) */
export interface CreateOrderResponse {
  order: Order;
  confirmation_code: string;
  rolled_over: boolean;
  /** Populated only when rolled_over=true (D18) */
  requested_delivery_date?: string;
}

/** Outlet reference row from GET /ref/outlets */
export interface OutletRef {
  outlet_id: string;
  brand: string;        // 'Fresh' | 'Style' | 'Tech'
  district: string;
  depot: string;
  dock_type: string;
  parking_constraint: string;
  window_open_time: string;
  window_close_time: string;
  mall_window?: string;
}
