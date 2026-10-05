# Spec 04: Screen Specs and Departures from the Figma

Conforms to PROJECT_CONTEXT.md sections 12, 13, 16.3. Private. The Figma shows intended layout and flows only; every data value in it is a placeholder. Frame names below are descriptive (the export is low resolution; confirm details visually).

## 1. Departures (copy into the README, numbered)

| # | Figma shows | We build | Basis |
|---|-------------|----------|-------|
| 1 | Trips mixing Fresh, Style, Tech; a Peliyagoda trip to Kandy | One brand and one district per trip; own depot only | booklet 2B rules (H1, H4) |
| 2 | Batch cutoff 07:00 AM on the dashboard | Orders close 16:00 the day before | booklet p.4 |
| 3 | No fuel-quota UI | Engine enforces quotas; Planning shows "fuel remaining" | booklet p.5, p.12 |
| 4 | SKU catalogue, line items, stock levels, barcode search | No SKUs and no line items: an order is units, kg, m3, one temperature (+ optional note) | D4, booklet order record |
| 5 | Deferral reasons like "tailgate lift", "helper crew", "compressor calibration" | Reasons from checked constraints, operational reasons and free text | D5 |
| 6 | QR handshake as proof of delivery | POD = driver outcome + store receipt; QR or short code is a stretch, never a guard | D6 |
| 7 | Driver "accept" or "decline" per order or trip | Accept handover only; no decline | booklet (drivers follow the plan) |
| 8 | Store manager header shows a driver ID (DRV-8492) | Shows the logged-in store manager and outlet | copy error |
| 9 | Dashboard shows 342 orders, 40 vehicles, 14 refrigerated, dates in Oct 2024 | Everything computed from the database (120 outlets, 60 vehicles, 16 reefers) | D8 |
| 10 | "Confirm Orders" bulk action on the Orders list | Removed: orders are confirmed when placed before the cutoff. Plan and cancel actions instead | booklet p.7 |
| 11 | Vehicle names (WP-CAB-3912, "Isuzu 4.2T"), driver names | Real ids VEH001-VEH060 and capacities from `vehicles.csv`; seeded drivers | datasets |
| 12 | "Request urgent partial delivery", intake-readiness checklist, escalate, audit-log UI | Not built (Tier 2) | restraint |

## 2. Screen specs (frame -> behaviour -> endpoints -> states)

Every screen needs loading, empty and error states. Driver and loader also need offline states.

### 2.1 Driver (phone)
| Screen | Behaviour | Endpoints | States |
|--------|-----------|-----------|--------|
| **D1 Home** (frame 1) | Today's trips (at most 2, for example 1 Fresh + 1 Style): brand, district, stops, first ETA, status. Banner: Online / Offline (N pending) / Syncing / Needs attention. | `GET /driver/trips` | no trip; not yet loaded; offline cached |
| **D2 Handover** (frame 3) | When the trip is LOADED at the current `plan_version`: "Accept handover and start route". "Report loading discrepancy" opens an exception. Scan/manual code is Tier 2. | `POST /trips/{id}/start` | not loaded; stale or cancelled (rejected); queued offline |
| **D3 Stop sequence** (frame 4) | Ordered stops with ETA, window, order size, status. | cache + `GET /driver/trips` | plan changed notice |
| **D4 Active stop** (frames 2, 5) | Outlet, window, units/kg/m3, temperature. Arrive; record outcome (delivered / partial / refused / closed) with quantity, `received_by`, note; report exception. | `POST /stops/{id}/arrive`, `/outcome`, `/exception` | queued, synced, applied with conflict |
| **D5 History** (frame 6) | Completed stops and exceptions. | cache | none |

### 2.2 Loader (phone or tablet at the dock)
| Screen | Behaviour | Endpoints | States |
|--------|-----------|-----------|--------|
| **L1 Trips** (frame 11) | Confirmed trips for the depot with vehicle, stops, weight % and volume % of caps; brand filter; View load, Start loading. | `GET /loading/trips`, `POST /trips/{id}/load-start` | none; plan changed (refresh banner) |
| **L2 Load list** (frame 12) | Delivery sequence + reverse load order, quantities, `plan_version`. "Confirm load" disabled while a shortfall is open; rejected if stale. After confirm the trip is LOADED and the driver can accept handover. (Handoff QR pass is Tier 2.) | `GET /trips/{id}/load-list`, `POST /trips/{id}/load-confirm` | shortfall open; stale version |
| **L3 Report issue** (frames 13-14) | Pick order; issue `missing` (missing pallet, short quantity) or `damaged` (damaged or leaking) with expected vs loaded quantity and note. Sends to dispatcher; trip BLOCKED. | `POST /trips/{id}/load-checks` | queued offline; sent |

### 2.3 Dispatcher (large screen)
| Screen | Behaviour | Endpoints | States |
|--------|-----------|-----------|--------|
| **P1 Dashboard** | Order counts (total, unallocated, planned, deferred), vehicle states, planning progress, alerts, active deliveries, cutoff countdown (16:00). | `GET /dashboard`, `/alerts` | before / after cutoff |
| **P2 Orders** | Filterable table (brand, depot, date, status, temperature), detail panel, priority flags (`deferred_yesterday`, `days_since_last_served`), cancel with reason, requeue. **No "Confirm Orders".** | `GET /dispatch/queue`, `POST /orders/{id}/cancel`, `/requeue` | filtered empty |
| **P3 Planning** | Generate / re-run (keeps locked trips). Draft trips with weight and volume bars, trip minutes vs 270/480, ETA and window per stop, fuel remaining. Edit panel (add/remove orders) with validator feedback (rule, actual, limit). Confirm trip / Confirm all. Deferred list with reason and class. Close run. | `POST /plans/generate`, `GET /plans/{plan_run_id}/trips`, `GET /dispatch/queue`, `GET /deferrals`, `/plans/validate`, `/trips/{id}/orders`, `/trips/{id}/confirm`, `/plans/close-run`, `GET /plans/summary`, `/fuel` | 422 violations |
| **P4 Loading coordination** | Trips by bay with sequence. Shortfall banner: departure blocked; resolve with Adjust plan (`replan_order`), Defer affected order (`defer_order`) or `proceed_partial`. | `GET /alerts`, `GET /load-checks`, `POST /load-checks/{id}/resolve` | open / resolved |
| **P5 Live monitoring** | Active vehicles with progress and delay; stop timeline with proof-of-delivery status; exceptions panel: Record decision (`retry` or `skip`); Contact driver (tel link). | `GET /monitoring/live`, `POST /exceptions/{id}/decision`, SSE | stale; driver offline; sync conflict shown |
| **P6 Deferred** | Queue with reason, class (UNAVOIDABLE / CHOICE / OPERATIONAL / DISPATCHER), history (2x, 3x), next window, notes, requeue. | `GET /deferrals`, `/outlets/{id}/skip-history` | none |

### 2.4 Store manager (phone or desktop; online-only)
| Screen | Behaviour | Endpoints | States |
|--------|-----------|-----------|--------|
| **SM1 Home** | Notices, next delivery with ETA window, cutoff countdown, consignment list. | `GET /orders`, `/notifications`, `/outlets/{id}/expected-deliveries` | none; offline notice |
| **SM2 Place order** | One order = one temperature (Chilled only for Fresh outlets). Enter units and temperature; kg and m3 derived (D10), or entered as fallback. Optional note. Confirmation code; "rolled to next run" message after 16:00. No line items. Offline: show "connect to place an order" (draft saving optional). | `POST /orders` | past cutoff; validation (chilled not allowed) |
| **SM3 Deferred notice** | Plain-language reason, new expected date, call dispatcher; mark read. | `GET /notifications`, `POST /notifications/{id}/read` | none |
| **SM4 Tracking** | Progress rail: Received, Scheduled, Loaded, On the way, Delivered; ETA. | `GET /orders/{id}`, SSE | no ETA yet |
| **SM5 Confirm receipt** | Confirm full receipt, or report discrepancy (short, damaged, wrong item, temperature) with note. | `POST /stops/{id}/receipt` | already confirmed |

## 3. Threads checked against screens
1. P3 confirm -> L1 and SM4 "Scheduled". 2. L3 report -> P4 banner, trip BLOCKED. 3. L2 confirm load -> D2 accept handover -> P5. 4. D4 exception -> P5 decision -> driver notice. 5. P3/P4/P2 defer -> SM3 notice -> P6. 6. D4 outcome -> SM5 confirm -> P5. 7. SM2 order before cutoff -> P2 queue.

## 4. Scope tiers (PROJECT_CONTEXT 16.3)
- **Tier 0 (must demo):** four-role login; seeded data; place order with confirmation (SM2); plan generation with the engine (H1-H9, H11, H12) with deferrals, reasons and notices; trip confirm; loader list, shortfall report and load confirm (L1-L3); driver start, arrive, outcome with offline queue and sync (D1-D4); store manager ETA, receipt and deferral notice (SM1, SM3-SM5); minimal dispatcher dashboard and live monitoring (P1, P5); **the degradation scenario in section 5 (driver exception, dispatcher decision, deferral and ETA notices)**.
- **Tier 1:** assisted editing panel with validator feedback; sync-conflict display; fuel remaining indicator; deferred queue page with history (P6); notifications and SSE. `[ASSUMPTION]` Order cancel with reason sits here (the context lists it in the API but not in a tier). The driver exception with dispatcher decision is now Tier 0 because it is the degradation scenario.
- **Tier 2:** QR or short-code handover, intake-readiness checklist, SKU catalogue, native apps, maps, traffic-aware ETA, fleet availability editing, D5 History polish, desktop store-manager variants.

## 5. Degradation scenario (headline, D18)

**Scenario:** the driver cannot deliver on time on the delivery date because of a sudden failure (for example a vehicle breakdown on the road). `[OPEN: use the exact scenario name from the Designathon submission]`

**Why it matters to Waypoint (draft for the README and video, grounded in the booklet):** Fresh orders must reach 80 supermarkets before 8 AM. Today dispatchers learn about a problem by phone, often only after the driver has reached the outlet; deferral decisions are recorded in handwritten notes, so the same outlet can be skipped on consecutive runs; and the store manager gets no notice. This scenario gives the dispatcher an early, shared view, a recorded decision, and an immediate notice to every affected outlet.

**Flow**
1. **Driver (D4):** "Report exception", type Vehicle issue, note. Works offline: the report is queued (clock icon) and replays on reconnect; if the plan changed meanwhile it is recorded as `applied_with_conflict` and flagged.
2. **System:** exception OPEN, trip stays IN_PROGRESS. Every stop not yet DELIVERED is marked **at risk** when its projected arrival is later than `window_close_time` (rule-based). Events `stop.exception` reach P5 and the P1 alert list.
3. **Dispatcher (P5):** exceptions panel shows the affected stops (window, ETA, projected arrival, mall or non-mall), Contact driver, and **Record decision**:
   - **Skip** (defer all remaining stops): stops SKIPPED, orders DEFERRED with reason `EXCEPTION_SKIPPED` (class OPERATIONAL, plain text with the numbers and the consequence: days since last served, consecutive deferrals). A second consecutive deferral raises an alert. Entries appear in P6.
   - **Retry** (vehicle recovered): stops return to PENDING with recomputed ETAs. A retried non-mall stop that would arrive after its window needs a mandatory reason (A10); a mall stop cannot be retried past its window and must be skipped.
4. **Store managers (SM1, SM3, SM4):** each affected outlet gets a deferral notice (reason, new expected date) or an ETA-change notice, plus the updated progress rail.
5. **Driver (D1/D3):** sees the decision (after sync if offline) and can complete the trip; already delivered stops stay delivered.

**Screens touched:** D4 (exception sheet, offline states), D1/D3 (decision banner), P5 (alert, at-risk badges, decision), P1 (alert), P6 (deferral entries), SM1/SM3/SM4 (notices).

**Not planned:** reassigning the remaining orders to another vehicle on the same day (not in the contract; Tier 2). Skipped orders go to the next operating day.

**`[ASSUMPTION]` list for the README:** vehicle-level exceptions cover the whole trip; A10 applies to retry; "at risk" is projected arrival after window close; ETA-change notices after retry.

