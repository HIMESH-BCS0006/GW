# Spec 02: Business Rules and Allocation Engine

Conforms to PROJECT_CONTEXT.md sections 8, 10, 11, 13.2, 14.4, 14.5. Private: contains dataset derivatives.
Sources: booklet pp.4-5 (constraints), p.12 (Hackathon), pp.18-21 (Task 2B rules), pp.28-29 (columns). Assumptions A1-A10 are in Spec 01.

## 1. Hard constraints (the validator rejects any plan that breaks one)

| ID | Rule |
|----|------|
| H1 | One trip = one vehicle + one trip number. All orders on it share the **same brand and district**. |
| H2 | `temp_requirement = chilled` needs vehicle `temp = reefer`. Reefers may carry ambient. |
| H3 | Outlet `parking_constraint = van_only` needs vehicle `type = van`. |
| H4 | A vehicle serves only outlets of its own `depot`. |
| H5 | Whole orders: never split an order across trips or vehicles. |
| H6 | Per trip: sum `order_volume_m3` <= `volume_cap_m3` AND sum `order_weight_kg` <= `weight_cap_kg`. |
| H7 | At most 2 trips per vehicle per day. |
| H8 | Daily time budgets (section 2) are respected. |
| H9 | Only vehicles with status `available` are used (not `in_workshop`). |
| H10 | Deliver only on dates with `calendar.is_operating = 1` (Mon-Sat, not the 10 listed holidays). |
| H11 | Arrival within the outlet window (`window_open_time`..`window_close_time`); early arrival waits for the window to open. Mall outlets: the mall window (identical to the outlet window in the data, so no intersection logic is needed). |
| H12 | Litres used by a vehicle in an ISO week <= `weekly_fuel_quota_l`. |

H1-H8 are the Task 2B rules; H9 comes from the Task 2B scenario; H10-H12 from the general constraints. The Hackathon text does not spell out trip rules, so adopting 2B is a recorded decision (D1).
**Override (A10):** a planned arrival after the window closes is a hard failure in the automatic planner. A dispatcher may override for non-mall outlets with a mandatory reason. Mall windows are never overridable.
**Business rule (D9):** only Fresh outlets may place chilled orders; one order has one temperature.

## 2. Trip time (exact booklet formula)

```
trip_minutes = depot_to_district_freeflow_min                 (once per trip)
             + inter_stop_freeflow_min * (n_orders - 1)
             + sum over orders of service_allowance_min[brand_of_trip, outlet.dock_type]
```
- The return journey is NOT added; the budgets already allow for it.
- One stop per order, even when two orders go to the same outlet (A9).

**Budgets per vehicle per day:** Fresh trips total <= **270 min** (window 03:30-08:00). Style and Tech trips **combined** <= **480 min** (trading day 09:00-17:00). Separate budgets: one vehicle may run 1 Fresh + 1 Style trip, never more than 2 trips in total.

**Worked examples (verified against the CSVs):** Gampaha Fresh, 2 rear_dock + 1 street: 37 + 9x2 + 15 + 15 + 16 = **101**. Colombo Fresh, 4 street: 24 + 8x3 + 16x4 = **112**. Together 213 of 270; a third trip is not allowed.

## 3. Timeline, ETAs and fuel (assumptions A1-A5)

- **Two clocks (A4):** H8 uses the formula above (no waiting). H11 uses the waiting-aware ETA timeline below. A plan must pass both.
- **ETA (A1, A3):** Fresh trip 1 departs 03:30; trip 2 departs when trip 1 ends + `RELOAD_BUFFER_MIN` (config, default 0). No return leg. Arrival at stop 1 = depart + `depot_to_district_freeflow_min`; arrival at stop k>1 = previous service end + `inter_stop_freeflow_min`; service start = max(arrival, `window_open_time`); service end = start + allowance. Style/Tech trips depart so the first arrival >= its window open.
- **Stop order (A5):** earliest `window_close_time`, then earliest `window_open_time`, then `outlet_id`. (Inter-stop time is constant per district, so this only makes plans deterministic.)
- **Loading order:** reverse of the delivery sequence (last stop loaded first).
- **Fuel (A2):** litres = (2 x `depot_to_district_km` + `inter_stop_km` x (n-1)) / `km_per_l`, charged to the ISO week; counts planned, confirmed and completed trips. Fuel binds only for repeated long trips; local trips never bind (weekly km allowance = quota x km_per_l, roughly 1,600-4,300 km for trucks and 3,900-6,700 for vans). Seed pre-used litres on a few vehicles so `FUEL_QUOTA` can be demonstrated.

## 4. Priority (configurable, lexicographic)

1. `deferred_yesterday = 1`
2. larger `days_since_last_served`
3. Fresh chilled, then Fresh ambient, then Style and Tech
4. earlier `window_close_time`
5. cheaper to serve per trip minute
6. final tie-break: `order_ref` (stable by id)

The ranking is a config object stored with each plan run (`ranking_config_json`) so the policy can be explained and changed without touching the engine. It is our proposal; the booklet supplies the inputs but not a ranking.

## 5. Allocation algorithm (deterministic heuristic + independent validator)

```
INPUT : SUBMITTED orders for the run, available vehicles, delivery date
STEP 0  Reject non-operating days (NOT_OPERATING_DAY).
STEP 1  Pre-screen each order; defer immediately (UNAVOIDABLE) if:
        chilled and no available reefer at the depot (NO_REEFER); van_only and no available van (NO_VAN);
        exceeds every eligible vehicle (TOO_LARGE); window unreachable under the time rules (WINDOW_INFEASIBLE).
STEP 2  Rank remaining orders (section 4).
STEP 3  For each order, in rank order:
        a. add to an existing open trip of the same depot, brand and district that stays valid (best fit);
        b. else open a new trip on the smallest sufficient eligible vehicle slot (prefer ambient trucks for
           ambient orders, keep reefers free), within trip limit, time budgets, fuel quota;
        c. else defer with a diagnosed reason.
STEP 4  Sequence stops; compute ETAs, fuel, utilisation.
STEP 5  Validate the whole plan with the same validator used for manual edits. Any violation is a bug; do not save.
```
**Re-running:** trips already CONFIRMED or later are locked; only DRAFT trips and unassigned orders are re-planned (`regenerate` keeps locked trips).
**Modes:** automatic generate; assisted (move, add, remove, defer; each edit is validated and returns the broken rules with numbers); confirm is blocked while any hard rule fails.
**Close run:** `plans/close-run` is blocked until every order is on a trip or has a deferral; it carries deferred orders to the next operating day (`DEFERRED -> SUBMITTED`, `deferral_count` retained) and updates `outlet_service_state`.

## 6. Deferral reasons

| Code | Default class | Meaning |
|------|---------------|---------|
| NO_REEFER | UNAVOIDABLE | Chilled order, no available reefer at the depot |
| NO_VAN | UNAVOIDABLE | `van_only` outlet, no available van |
| TOO_LARGE | UNAVOIDABLE | Exceeds the largest eligible vehicle |
| WINDOW_INFEASIBLE | UNAVOIDABLE | Cannot arrive inside the window under the time rules |
| CAPACITY_FULL | CHOICE | All eligible trips full by weight or volume |
| TIME_BUDGET | CHOICE | Adding it exceeds 270 or 480 minutes |
| TRIP_LIMIT | CHOICE | All eligible vehicles already run 2 trips |
| FUEL_QUOTA | CHOICE | Would exceed the vehicle's weekly litres |
| SHORTFALL | OPERATIONAL | Loader reported missing stock before departure |
| DELIVERY_FAILED | OPERATIONAL | Driver outcome refused, or outlet closed |
| EXCEPTION_SKIPPED | OPERATIONAL | Dispatcher skipped a stop after a driver exception |
| MANUAL | DISPATCHER | Dispatcher decision with free-text reason |

**The class is computed, not assumed:** after a deferral the engine re-checks the order alone against the full available fleet. Infeasible alone = UNAVOIDABLE; feasible alone = CHOICE (it lost to priority or shared capacity). Each deferral stores a plain-language explanation with the exact numbers, the consequence (days since last served, consecutive deferrals), notifies the store manager (reason and new expected date), and a second consecutive deferral raises a dispatcher alert.

## 7. Data profile (from outlets.csv, vehicles.csv, district_travel.csv, service_allowance.csv)

**Outlets (120):** Peliyagoda 75 (Fresh 49, Style 16, Tech 10); Kandy 45 (31, 9, 5). Peliyagoda districts: Colombo 24, Gampaha 15, Kalutara 10, Galle 9, Kurunegala 8, Matara 6, Puttalam 3. Kandy depot: Kandy 20, Matale 8, Nuwara Eliya 6, Badulla 6, Kegalle 5.
- `van_only` (13, all street dock): Fresh OUT001-OUT003 (Colombo, Peliyagoda); Fresh OUT076-OUT083, Style OUT088, Tech OUT093 (Kandy district). `mall_dock` = exactly the 12 `mall_bay` outlets: OUT015, 016, 017, 018, 021, 022, 035, 036, 056, 089, 090, 094.
- Fresh windows open 03:00 / 04:00 / 05:00 / 05:30 and close 07:30 / 07:45 / 08:00 (none after 08:00). All non-mall Style and Tech outlets: 09:00-17:00. Mall outlets use their mall window (09:00-11:00, 10:00-12:00, 10:30-12:30).

**Vehicles (60, diesel; weekly quota 340-620 L; no driver column):**

| Depot | Group | IDs | Count | kg | m3 |
|-------|-------|-----|------:|----|----|
| Peliyagoda | reefer trucks | VEH001-007 | 7 | 3610-6840 | 19.4-33.4 |
| Peliyagoda | ambient trucks | VEH008-034 | 27 | 3800-7200 | 22-38 |
| Peliyagoda | reefer vans | VEH035-036 | 2 | 1040 | 7 |
| Peliyagoda | ambient vans | VEH037-038 | 2 | 1100-1200 | 8-9 |
| Kandy | reefer trucks | VEH039-043 | 5 | 3610-6180 | 19.4-29.9 |
| Kandy | ambient trucks | VEH044-056 | 13 | 3800-7200 | 22-38 |
| Kandy | reefer vans | VEH057-058 | 2 | 1040 | 7 |
| Kandy | ambient vans | VEH059-060 | 2 | 1200 | 9 |

**Pressure points:** (1) reefer vans: 3 Peliyagoda van_only outlets rely on 4 vans (2 reefer); 10 Kandy van_only outlets rely on 4 vans (2 reefer), so chilled orders for Kandy van-only Fresh outlets are the natural bottleneck; (2) reefers overall (9 at Peliyagoda, 7 at Kandy); (3) far districts are time-limited (Puttalam 173 min outbound, Badulla 186, Matara 137, Kurunegala 127); (4) Style and Tech stops cost 38-59 min each.

**Maximum stops on one trip by time budget alone** (derived; the engine computes this itself and tests may compare; same dock type assumed, rear/street/mall):

| District | Fresh | Style | Tech |
|----------|-------|-------|------|
| Colombo | 11/10/9 | 10/8/6 | 9/7/7 |
| Gampaha | 10/9/8 | 9/8/6 | 8/7/7 |
| Kalutara | 8/7/7 | 8/7/6 | 7/6/6 |
| Galle | 7/7/6 | 8/7/5 | 7/6/6 |
| Matara | 5/5/5 | 7/6/5 | 6/5/5 |
| Kurunegala | 4/4/4 | 6/5/4 | 6/5/5 |
| Puttalam | 3/3/2 | 5/4/3 | 4/4/4 |
| Kandy | 12/11/10 | 10/9/7 | 9/7/7 |
| Matale | 9/9/8 | 9/8/6 | 8/6/6 |
| Nuwara Eliya | 5/4/4 | 6/5/4 | 6/5/5 |
| Badulla | 2/2/2 | 5/4/3 | 4/4/4 |
| Kegalle | 8/7/7 | 8/7/6 | 7/6/6 |

## 8. Tests (required)

1. One failing plan per rule H1-H12 (and the A10 override rules).
2. Booklet examples: 101 and 112 minutes; 213 of 270; third trip rejected.
3. Determinism: same input, same plan.
4. Fairness: an order with `deferred_yesterday = 1` beats an equivalent order without it.
5. Formula parity: two orders to the same outlet are charged as two stops (A9).
6. Two-clocks rule: a plan that passes H8 but fails H11 is rejected.
7. Every deferral has a reason code, a computed class, and a notification to the store manager; a second consecutive deferral raises an alert.
8. Re-run keeps locked (CONFIRMED or later) trips.
9. **Golden walkthrough test (D12):** on the seeded day, "Generate plan" puts the seeded store manager's outlet on a trip carried by the seeded driver's vehicle at the seeded loader's depot; the fallback pre-planned day also passes.
10. If the organizers' `check_allocation.py` is available locally, run the engine on the S1 scenario with it as an oracle (do not commit the files).
