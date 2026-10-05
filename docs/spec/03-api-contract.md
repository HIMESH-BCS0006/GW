# Spec 03: Roles, API Contract, Events

Conforms to PROJECT_CONTEXT.md sections 13, 14.6, 14.7. Private. FastAPI generates `/openapi.json`; the Pydantic models are the machine-readable contract and must match this file. Export `docs/openapi.yaml`, generate the typed client from it, and run a mock server from it so front-end work is not blocked.
Any Figma-only feature is Tier 2 (stretch). Contract changes require editing this file, the stubs and Spec 04 together.

## 1. Conventions

- Base `/api/v1`, JSON. API and web are served from one origin (reverse proxy `/api`).
- Auth: JWT bearer; claims include `user_id`, `role`, `depot_ids[]` (dispatcher/loader), `outlet_id` (store manager), `vehicle_id` (driver) (D24). Depot-scoped endpoints accept query parameter `depot_id`: defaults if user has 1 depot, returns 422 if missing when user has multiple depots, returns 403 `FORBIDDEN_SCOPE` if depot is outside user's access.
- Time: timestamps stored in UTC, displayed in Asia/Colombo. Clock times `HH:MM`; durations in minutes; dates `YYYY-MM-DD`.
- **Idempotency:** field roles send `client_op_id` (UUID), `client_seq` (monotonic per device), `client_ts` on mutating calls. The server stores them in `sync_ops`; a replay returns the original result.
- Errors: `{error:{code,message,details}}`. Rule violations: `422 CONSTRAINT_VIOLATION` with `details.violations[{rule,message,actual,limit}]` using H-ids. Other codes: `PLAN_CHANGED`, `NOT_OPERATING_DAY`, `INVALID_TRANSITION`, `FORBIDDEN_SCOPE`, `OPEN_SHORTFALL`, `STALE_PLAN_VERSION`.
- Cutoff: 16:00 the day before delivery, evaluated with `business_now()` (D11, D18). Cutoff for date D is 16:00 on D-1. If `delivery_date` is omitted, server picks earliest operating day whose cutoff has not passed. If a date's cutoff has passed, server rolls over to next open operating day (`rolled_over = true`, returns `requested_delivery_date`). Non-operating/invalid/past dates return 422 `NOT_OPERATING_DAY`.
- SSE: `EventSource` cannot set headers, so use a short-lived stream token in the query string (or a fetch-based stream). Clients refetch on events and fall back to 15 s polling.

## 2. Roles and accounts

| Role | Suggested account | Scope |
|------|-------------------|-------|
| dispatcher | `dispatcher@waypoint.test` | `depot_ids[]` (multi-depot via `user_depot_access`) |
| loader | `loader@waypoint.test` | `depot_ids[]` (multi-depot via `user_depot_access`) |
| driver | `driver@waypoint.test` | one vehicle (`vehicle_id`) |
| store_manager | `store@waypoint.test` | one outlet (`outlet_id`) |

Plus 60 drivers (one per vehicle) and 120 store managers (one per outlet) with a shared dev password (A8). The four headline accounts are coupled to the seeded day (D12, Spec 06).

## 3. Endpoints

**Auth and reference (any role):** `POST /auth/login`, `GET /me`, `GET /ref/outlets`, `GET /ref/vehicles`, `GET /ref/calendar`, `GET /ref/config` (cutoff, budgets 270 and 480, unit constants, business clock, demo flag).

**Store manager**
| Method | Path | Purpose |
|--------|------|---------|
| POST | `/orders` | `{outlet_id, delivery_date?, temp_requirement, order_units, [order_weight_kg, order_volume_m3], note?, client_op_id}`. Units + temperature by default; server derives kg and m3 (D10, D18), or manager enters them. Chilled only for Fresh outlets (D9). Responses return non-null `order_weight_kg` and `order_volume_m3`. Returns `order` (`SUBMITTED`), `confirmation_code`, `rolled_over`, `requested_delivery_date`. |
| GET | `/orders` | Own orders with status, `trip_id`, `stop_id`, `eta` (D19) |
| GET | `/orders/{id}` | Order with timeline, status, `trip_id`, `stop_id`, `eta` and deferral history (D19) |
| POST | `/orders/{id}/cancel` | Body: `{ reason: string, note?: string }` (D22). From SUBMITTED, PLANNED or SCHEDULED; returns 409 `INVALID_TRANSITION` if state disallows action. |
| GET | `/outlets/{id}/expected-deliveries` | Expected arrival (ETA) per planned order |
| POST | `/stops/{id}/receipt` | `{outcome: full|discrepancy, note, client_op_id}` |
| GET | `/notifications` | Deferral notices, ETA changes |
| POST | `/notifications/{id}/read` | Mark read |

**Dispatcher: planning**
`GET /dashboard` (D21), `GET /dispatch/queue`, `POST /plans/generate` (`regenerate` keeps locked trips), `GET /plans`, `GET /plans/{plan_run_id}/trips` (returns `TripDetail[]` with `TripCard` enriched with `est_minutes`, `est_fuel_l`, `time_budget_min`, and `StopDetail` sorted by `seq` with `service_start_est`), `POST /plans/validate`, `POST /trips/{id}/orders` (add; makes order SCHEDULED if trip is CONFIRMED, D19), `DELETE /trips/{id}/orders/{order_id}` (returns order to SUBMITTED, D19), `POST /orders/{id}/defer` (body: `{ reason_text: string, note?: string }`, sets `reason_code = MANUAL`, `reason_class = DISPATCHER`, `decided_by = dispatcher`, D22), `POST /orders/{id}/requeue`, `POST /trips/{id}/confirm` (moves trip to CONFIRMED and all orders to SCHEDULED, D19; 422 while any hard rule fails), `POST /trips/{id}/cancel`, `POST /plans/close-run` (blocked until every order is on a trip or has a deferral; carries deferred orders to next operating day), `GET /plans/summary` (D21), `GET /fuel`, `GET /fleet` (availability by date). Depot-scoped endpoints accept optional `depot_id` query param (D24).

**Dispatcher: monitoring and deferrals**
`GET /monitoring/live` (D21; nests trips, stops with `projected_arrival`, `at_risk`, `window_close_time`, `parking_constraint`, and `open_exceptions[]`; delay rule-based with `DELAY_ALERT_MIN`), `GET /alerts` (D21), `GET /load-checks` (returns open/resolved `LoadCheck[]` enriched with `trip_id`, `vehicle_id`, `outlet_id`, `outlet_name`, `bay`), `POST /exceptions/{id}/decision` (`retry | skip`), `POST /load-checks/{id}/resolve` (`defer_order | replan_order | proceed_partial`), `GET /deferrals`, `GET /outlets/{id}/skip-history`.

**Loader**
`GET /loading/trips` (returns `TripCard[]`, D23), `GET /trips/{id}/load-list` (returns `LoadListResponse` with `plan_version`, `TripCard`, `delivery_sequence`, `reverse_load_order`, D23), `POST /trips/{id}/load-start`, `POST /trips/{id}/load-checks` (`{order_id, plan_version, expected_qty, loaded_qty, issue: missing|damaged, note, client_op_id}`; opens a shortfall, trip BLOCKED), `POST /trips/{id}/load-confirm` (requires current `plan_version` and no open shortfall; else `STALE_PLAN_VERSION` or `OPEN_SHORTFALL`).

**Driver**
`GET /driver/trips` (returns `TripCard[]`, D23), `POST /trips/{id}/start` (trip LOADED at current `plan_version`; rejected if cancelled, blocked or stale), `POST /stops/{id}/arrive`, `POST /stops/{id}/outcome` (D20 mapping: `delivered | partial | refused | closed`, `quantity_delivered`, `received_by`, `outcome_note`, `completed_at`), `POST /stops/{id}/exception` (`dock_blocked | outlet_closed | vehicle_issue | access_problem | other`), `POST /trips/{id}/complete`, `POST /sync` (batch replay into same handlers).

**Live updates:** `GET /events/stream`, filtered by caller scope.

## 4. Events

`order.submitted`, `order.deferred`, `order.cancelled`, `plan.generated`, `trip.confirmed`, `trip.updated`, `loading.shortfall`, `shortfall.resolved`, `trip.loaded`, `trip.started`, `stop.arrived`, `stop.outcome`, `stop.exception`, `exception.decided`, `receipt.confirmed`, `receipt.discrepancy`, `sync.reconciled`, `sync.conflict`, `run.closed`.
Each event: `{id, type, occurred_at, scope{depot,outlet,vehicle}, entity{type,id}, data}`.

## 5. Offline and sync (summary; detail in Spec 05)

- The driver app caches the day's trips and queues actions in IndexedDB; ops are applied in (`device_id`, `client_seq`) order, not by device clock. `client_ts` is kept; skew above 10 minutes against server receipt time is flagged.
- Results: `applied`, `replayed`, `applied_with_conflict`, `rejected`. **Field facts that physically happened are never rejected** (arrive, outcome, exception, receipt, load check): if the plan changed meanwhile they are recorded as `applied_with_conflict` and the dispatcher is alerted. Server-authority commands (start trip) are `rejected` when the trip is cancelled, blocked or the `plan_version` is stale.
- Store manager is online-only (optional draft saving). The loader uses the same queue as secondary scope.

## 6. Not in the contract (Tier 2 / stretch)

QR or short-code handover and receiving codes (`receipts.qr_token` is optional and never a guard), SKU catalogue and order lines, intake-readiness checklist, fleet availability editing, maps, traffic-aware ETA, native apps.

## 7. Exception semantics (degradation scenario, D18)

- `POST /stops/{id}/exception` body: `{type, note, client_op_id, client_seq, client_ts, plan_version}`. Offline-safe: it is a field fact and is never rejected (`applied_with_conflict` if the plan changed).
- A `vehicle_issue` exception applies to the whole trip: all stops not yet DELIVERED are at risk (Spec 01). Other types (`dock_blocked`, `outlet_closed`, `access_problem`, `other`) apply to that stop only.
- `POST /exceptions/{id}/decision` body: `{decision: retry|skip, note, override_reason?}`. `skip` -> affected stops SKIPPED, orders DEFERRED with reason `EXCEPTION_SKIPPED` (class OPERATIONAL), store managers notified, `outlet_service_state` updated, second consecutive deferral raises an alert. `retry` -> stops PENDING, ETAs recomputed; if a retried non-mall stop would arrive after its window closes, `override_reason` is mandatory (A10); mall stops cannot be retried past the window (422 `CONSTRAINT_VIOLATION`, rule H11). `[ASSUMPTION]`
- `GET /monitoring/live` returns, per stop, `eta`, `projected_arrival` and `at_risk` (projected arrival later than `window_close_time`; rule-based, no ML).
- Events: `stop.exception`, `exception.decided`, `order.deferred`, `sync.conflict`; notifications for the store manager: deferral notice, and an ETA-change notice after `retry` `[ASSUMPTION]`.
