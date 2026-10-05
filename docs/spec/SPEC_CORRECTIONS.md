# Spec corrections log: specs vs PROJECT_CONTEXT.md v1.0

Authority: PROJECT_CONTEXT.md (from the original project chat). Every row is a place where my earlier spec files differed from it, and what the current files say. "Spec" = file number.

| # | Earlier spec said | PROJECT_CONTEXT says | Fixed in |
|---|-------------------|----------------------|----------|
| 1 | Free-entry order line items (`order_lines`, `lines[]`, SM2 line-item form) | D4: no SKUs and **no line items**; order = units, kg, m3, one temperature + optional note | 01, 03, 04 |
| 2 | D10 = line-item entry | D10: manager enters units + temperature; server derives kg and m3 from calibrated unit constants; fallback manager enters kg and m3; `[OPEN]` | 01, 03, 04, 06 |
| 3 | Handover code and receiving code (QR) built into the P0 flow; trip start required `handover_code`; outcome required `receiving_code_verified` | D6: QR or short code is a stretch and **never a hard guard**; POD = driver outcome (who received, quantity, time) + store receipt | 01, 03, 04 |
| 4 | Calendar extended past 2026-06-28; demo date 2026-10-05 | Seeded day must be inside the calendar range (operating, non-holiday Mon-Sat); never use the real date or extend the calendar | 06, 02 |
| 5 | `DEMO_NOW`, `/ref/clock`, `POST /admin/demo/close-orders`, `/admin/demo/reset` | D11: `business_now()` with `DEMO_MODE=true` fixed on the day before the seeded day; `GET /ref/config` carries clock and flag | 01, 03, 06 |
| 6 | Alembic dropped | Alembic migrations required | AGENTS, 07 |
| 7 | Repo layout `backend/`, `frontend/`, `data/ref/`; `idb` | `apps/api`, `apps/web`, `db/seed`; Dexie; mock server from OpenAPI | AGENTS, 07 |
| 8 | Timestamps in +05:30; times Asia/Colombo | Store UTC, display Asia/Colombo | AGENTS, 03 |
| 9 | Order state `CONFIRMED` (collides with trip confirm), `DISCREPANCY` as an order state | Orders: `SUBMITTED, PLANNED, SCHEDULED, LOADED, IN_TRANSIT, DELIVERED/PARTIALLY_DELIVERED, DEFERRED, CANCELLED`; separate stop `receipt_status` | 01 |
| 10 | Missing `SCHEDULED -> DEFERRED`, `load-start`, `DEFERRED -> SUBMITTED` | Added | 01, 02, 03 |
| 11 | Trip had `version`, `handover_code`, `est_litres`; no `plan_runs`, `vehicle_availability`; orders carried brand/district/depot; `outlet_service_history` | `plan_version`, `est_fuel_l`, `plan_runs`, `vehicle_availability`, `outlet_service_state(last_deferred_date)`, brand/district on trips, depot/brand/district derived from outlet; `notifications(event_id, audience_*)`, `audit_events` | 01 |
| 12 | Load check issue `missing_pallet | damaged | short_quantity` | `issue[missing, damaged]` with expected vs loaded quantity; resolution `defer_order | replan_order | proceed_partial` | 01, 03, 04 |
| 13 | Exception decision `wait | skip_and_defer | other` | `retry | skip`; exception types dock_blocked, outlet_closed, vehicle_issue, access_problem, other | 01, 03 |
| 14 | `POST /orders/{id}/ack-deferral` | Not in contract; use `POST /notifications/{id}/read` | 03, 04 |
| 15 | Missing endpoints | Added dashboard, requeue, close-run, fleet, load-start, load-checks resolve, order detail, notifications read, cancel with reason; `regenerate` keeps locked trips | 03 |
| 16 | Return leg approximated for trip 2 ETA; "nearest-first" stop order | A1: no return leg, `RELOAD_BUFFER_MIN`; A5: window close, window open, outlet id | 02 |
| 17 | No two-clocks rule, no same-outlet parity (A9), no A10 override | A4, A9, A10 added | 01, 02 |
| 18 | Deferral class `CAPACITY_CHOICE`; no `DELIVERY_FAILED`, `EXCEPTION_SKIPPED`; class assumed | Classes UNAVOIDABLE / CHOICE / OPERATIONAL / DISPATCHER; class **computed** by the solo-feasibility test | 02 |
| 19 | Offline: general `PLAN_CHANGED` rejection; ordering by `client_ts` | D14: field facts never rejected (`applied_with_conflict`); start trip rejected when stale; order by (`device_id`, `client_seq`); skew flag 10 min | 03, 05 |
| 20 | Store manager could queue orders offline | Store manager is online-only (draft saving optional) | 03, 04, 05 |
| 21 | Dispatcher "Confirm Orders (close the queue)" | Removed (orders are confirmed when placed); plan or cancel instead | 04 |
| 22 | Shortfall, offline, dashboard in "P1" tier | Tier 0 includes shortfall, offline queue/sync, minimal dashboard and monitoring; Tier 1 has editing panel, sync-conflict display, fuel indicator, deferred page, SSE | 04 |
| 23 | Slices S0-S3 with my own grouping | Slices 0-7 as in 16.4 (engine slice runs in parallel with Slice 0) | 05, 07 |
| 24 | Schedule with Sunday 3 PM freeze, 36-40 h | Saturday build + Sunday morning integrate; last hours for freeze/test/docs/video; >= 2 h buffer | 05 |
| 25 | Walkthrough steps in a different order | Draft outline from section 15 | 05 |
| 26 | Seeded one reefer at 95% quota; `store2@`; dry-run binding at seed time | "A few vehicles" with pre-used litres; four headline accounts; golden CI test + pre-planned fallback day (D12) | 06 |
| 27 | Decision statuses "Proposed" for D2, D3, D5, D8 | Adopted | 01 |
| 28 | Precedence: booklet > spec > Figma | Booklet > datasets > Figma; Figma values are placeholders | AGENTS, 01, 04 |
| 29 | Specs not marked private | Dataset derivatives: keep repo and specs private | all |
| 30 | Only some Spec 02 tests; no golden test | Full required test list incl. golden walkthrough, determinism, fairness, parity, two clocks, sync idempotency/conflict | 02, AGENTS |

**Items I kept because the context file does not contradict them** (flagged `[ASSUMPTION]` where relevant): the priority ranking is the context's own (14.4); the OUT004 headline-outlet candidate (verified in outlets.csv, still to be confirmed by the golden test); the "Simulate offline" demo switch; driver exception and cancel-with-reason placed in Tier 1; the proposed seeded day 2025-08-01 (computed from calendar.csv, `[OPEN]`).

**Still open (from the context file, section 18):** D10 medians, Designathon degradation scenario, organizer email, team and solution names, hosting target, Kandy day, Monday cutoff (A6) and A1-A3 confirmation, samples of task2b files and `deliveries_train.csv`, exact credentials and walkthrough order.


---
## Round 2: team confirmations (Saturday 3 October)

| # | Confirmation | Applied in |
|---|--------------|------------|
| 31 | Seeded delivery day confirmed: **Friday 2025-08-01** (business clock Thursday 2025-07-31, 14:00); A6 not exercised | 01, 06 |
| 32 | D10 stays calibrated from `deliveries_train.csv`: added `calibrate_unit_constants.py` (run locally; commit only the constants JSON) | 01, 06 |
| 33 | Degradation scenario (D18): driver cannot deliver on time on the date because of a sudden failure. Specified end to end; driver exception with dispatcher decision promoted to Tier 0; walkthrough and Slice 4 updated | 01, 03, 04, 05, 07 |

Assumptions introduced by 33 (listed in Spec 04 section 5 for the README): vehicle-level exceptions cover the whole trip; A10 applies to retry; "at risk" = projected arrival after window close; ETA-change notices after retry.
