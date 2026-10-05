# Spec 06: Seed Data

Conforms to PROJECT_CONTEXT.md sections 10, 13 (D10-D12, D16, A8), 14.1. Private. Booklet p.12: seed the system with the shared datasets and at least one realistic delivery day so the walkthrough works on a fresh install; `docker compose up` loads everything (idempotent seed).

## 1. Reference data (loaded verbatim from the CSVs)

| File | Rows | Seed assertion |
|------|-----:|----------------|
| outlets.csv | 120 | Peliyagoda 75 (49/16/10), Kandy 45 (31/9/5); 13 van_only; 12 mall_dock |
| vehicles.csv | 60 | 38 Peliyagoda, 22 Kandy; 16 reefers; 8 vans |
| district_travel.csv | 12 | 7 Peliyagoda districts, 5 Kandy |
| service_allowance.csv | 9 | 3 brands x 3 dock types |
| calendar.csv | 910 | 2024-01-01 to 2026-06-28; Sundays and 10 holidays non-operating |
| traffic_speed.csv, road_conditions.csv | 576, 10,920 | optional, display only |

The seed job fails loudly if an assertion fails. Reference CSVs are loaded; the organizers' Datathon scenario file is **not** used or committed.

## 2. Seeded delivery day and clock (D11)

- The calendar ends 2026-06-28, so the seeded delivery day must be an **operating, non-holiday Monday-Saturday inside the calendar range**. Do not look up the real current date in `calendar.csv`, and do not extend the calendar.
- With `DEMO_MODE=true`, `business_now()` returns a fixed time on the day before the seeded delivery day (for example 14:00), so orders can be placed at any real time. Otherwise it uses the real Asia/Colombo clock.
- **Seeded day (confirmed by the team): Friday 2025-08-01.** Computed from the calendar: operating, not a holiday, not a payday, monsoon 0, and the festival (esala, 2025-08-08) is one week away (`festival_ramp` 0.3). That mirrors the booklet's S1 conditions (festival a week away, not payday, no monsoon, Fresh demand rising). The business clock sits on Thursday 2025-07-31, 14:00. Because it is a Friday, the Sunday cutoff (A6) is not exercised.
- The seeded day is configured with `SEED_DELIVERY_DATE` in `.env`.

## 3. Accounts (A8)

60 drivers (one per vehicle) and 120 store managers (one per outlet) with a shared dev password from `.env.example`, plus dispatcher and loader accounts. Four headline accounts (suggested names): `dispatcher@waypoint.test` (Peliyagoda), `loader@waypoint.test` (Peliyagoda), `driver@waypoint.test`, `store@waypoint.test`. They appear in the README with their passwords.

## 4. Generated delivery day (own generator; deterministic)

Built from `outlets.csv` only. A Fresh dry order for most Fresh outlets, chilled orders for some Fresh outlets (a Fresh outlet may have two orders on the same day), Style weekly, Tech occasional. Only Fresh outlets get chilled orders (D9). Both depots are seeded; Peliyagoda is the walkthrough depot and Kandy is smaller `[OPEN: confirm, D16]`.

**Order sizes (D10, adopted).** Orders carry units and temperature; kg and m3 come from per-brand, per-temperature unit constants calibrated once from `deliveries_train.csv`. Run `calibrate_unit_constants.py` locally (`python calibrate_unit_constants.py deliveries_train.csv db/seed/unit_constants.json`); commit only the resulting constants file (private repo) and use it in the API and the seed generator. `[OPEN: run it and share the output so the seed test can be tuned]` Do not invent the constants. Fallback if it slips: the manager enters kg and m3.

**Demand must exceed capacity** on the seeded Peliyagoda day. If the generated day does not, change the number and mix of orders (for example more Fresh chilled orders), not the unit constants. Target outcomes, checked by a seed test: some `NO_REEFER` or `TOO_LARGE` (unavoidable) and some `CAPACITY_FULL`, `TIME_BUDGET` or `TRIP_LIMIT` (choice) deferrals; at least one far-district order failing on time budget; every deferral has a reason code.

## 5. Fleet and history state
- `vehicle_availability`: several vehicles `in_workshop` on the seeded day (include some reefers, so reefer scarcity is visible).
- `fuel_ledger`: **pre-used litres on a few vehicles** (near their weekly quota) so a `FUEL_QUOTA` deferral can be demonstrated.
- `outlet_service_state`: some outlets with `deferred_yesterday = 1` (consecutive deferrals 1; one at 2 to show the alert), and a spread of `days_since_last_served`.

## 6. Walkthrough coupling (D12) and fallback
- On the seeded day the **real engine output** must put the seeded store manager's outlet on a trip carried by the seeded driver's vehicle at the seeded loader's depot. Candidate headline outlet: **OUT004** (Fresh, Colombo, Peliyagoda, street dock, normal parking, window 05:30-08:00; verified in `outlets.csv`). The seeded orders and fleet are tuned (by choosing which orders and vehicles exist) until the golden test passes; do not hard-code the plan.
- A CI **golden test** enforces this on every build.
- A **pre-planned fallback day** is also seeded, so the walkthrough still works if the live plan is changed.
- Deferral notice for the walkthrough: either an engine deferral for the headline outlet's second order, or the dispatcher defers one of its orders manually (`MANUAL`); decide when the golden test is written.
- Reset: a seed command (`db/seed`, re-runnable) restores this state. `[ASSUMPTION]` implemented as a CLI/compose command, not an API endpoint.

## 7. Open items
D10 constants file, D16 Kandy day, final credentials and account order in the walkthrough. Also seed one trip whose stops give the degradation scenario room to play out (a Fresh trip with at least 3 stops, one being a non-mall outlet and the walkthrough driver's vehicle); the exact trip is fixed by the golden test.
