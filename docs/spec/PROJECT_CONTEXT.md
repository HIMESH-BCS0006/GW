# PROJECT_CONTEXT: Waypoint Delivery Planning System

Tech-Triathlon 2026 (a competition by rootcode) · Hackathon phase
Prepared: Saturday 3 October 2026 (Asia/Colombo) · Version 1.0

> **Confidentiality.** This file contains derivatives of competition datasets (sections 10 and 11). The competition terms forbid publishing or sharing the datasets or derivatives. Keep this file and the repository **private**. Do not paste it into public tools, forums or public repos.

---

## 0. Instructions for any AI agent reading this file

1. This file is the single source of context for the project. Read all of it before writing code or specs.
2. **Source precedence:** (1) Challenge Booklet facts, (2) the provided datasets, (3) the Figma design. The Figma design shows intended layout and flows only. Every data value in Figma (IDs, counts, dates, times, vehicle names, cutoffs, trip compositions) is a placeholder and is **not** a requirement. Where Figma conflicts with the booklet or data, follow the booklet or data and record the change as a "departure from the Designathon design" in the README.
3. **Never invent data or rules.** If something is marked `[OPEN]` or is not in this file, ask the team. Do not fill gaps with plausible guesses. Do not hard-code values that exist in the CSVs; read them from the database seeded from the CSVs.
4. Tags used below: `[BOOKLET]` stated in the challenge booklet; `[DATA]` observed in the supplied CSVs; `[FIGMA]` seen in the Figma export; `[DECISION]` agreed by the team or adopted in review; `[ASSUMPTION]` our choice where the booklet is silent (must be listed in the README); `[DERIVED]` computed by us from the data; `[OPEN]` unresolved.
5. The team does the prompting, design and engineering decisions. The coding agent implements. Keep changes small, tested and traceable to a section of this file or of the spec pack.
6. All times are Asia/Colombo (UTC+05:30). Store timestamps in UTC, display in Asia/Colombo. Clock times are `HH:MM`; durations are minutes.

---

## 1. TL;DR

- **What:** a web system that connects ordering, planning, loading, delivery and receipt for **Waypoint Group**, a fictional Sri Lankan retail group, across **four roles**: dispatcher, loader, driver, store manager.
- **Core difficulty:** the fleet cannot serve every order every day. The system must allocate orders to vehicles and trips under hard constraints, defer the rest with recorded, explainable reasons, and keep field work usable offline.
- **Deadline:** Hackathon submission is **Sunday 4 October 2026, 11:59 PM** Sri Lanka time. Today is Saturday 3 October, so the team has **less than two days**. Scope must be cut hard (section 16.3).
- **Deliverables:** deployed system (public URL plus four seeded accounts), private-or-agreed GitHub monorepo with README, Docker Compose, `docs/`, and a 5 to 8 minute unlisted YouTube demo.
- **Where the points are:** engineering quality and architecture 25%, functional completeness across four roles 20%, planning and allocation engine 20%, offline and degradation 10%, fidelity to Day 5 design 10%, demo video 10%, creativity 5%.
- **Out of scope:** the Datathon (separate phase, due 9 October). The team decided to ignore it for now.

---

## 2. Competition facts `[BOOKLET]`

### 2.1 Structure and timeline
One business challenge, three phases, 15 days. Brief and all datasets released on Day 1.

| Milestone | Day | Deadline (Sri Lanka time) |
|---|---|---|
| Brief and datasets released | 1 | Fri 25 Sep 2026, 12:01 AM |
| Designathon | 5 | Tue 29 Sep 2026, 11:59 PM (**submitted on time** `[DECISION: team statement]`) |
| **Hackathon** | **10** | **Sun 4 Oct 2026, 11:59 PM** |
| Datathon | 15 | Fri 9 Oct 2026, 11:59 PM (out of scope for now) |

- The Hackathon build must follow the Designathon submission; judges assess continuity. A missed phase scores zero for that phase. All three phases count equally to the overall score.
- Hackathon submission form: https://forms.gle/WurHAKjbq2XEZQhbA. Organizer contact: tech-triathlon@rootcode.io.
- Code pushed after the deadline is not considered. The deployment must stay live through review and, if the team advances, through the semifinal and Grand Finale.

### 2.2 Terms that affect engineering
- Datasets may be used **solely** for the competition. They must not be shared, distributed, transmitted or published (including derivatives) unless the organizers authorize it. Data confidentiality applies.
- The Hackathon nevertheless requires seeding the system with the shared datasets in a GitHub repo and a public deployed URL. **Resolution adopted:** keep the repo private, invite the judges, and email the organizers to confirm. `[OPEN: confirm by email]`
- Rules and Regulations listed in the booklet (model restrictions, no proprietary-API modelling, no low-code AI tools) appear in the Datathon section. The Hackathon requires an **AI tool disclosure** in `docs/` (which work was AI-assisted, which was not, and how tools were used). Keep a running log of AI use from now on.

---

## 3. Team and working setup `[DECISION: team statements]`

- Team of four. **Himesh is the backend developer.** The others take front-end and infrastructure work.
- The team uses **Antigravity** (agentic coding support) to implement. Humans write specs, prompts and designs; the agent codes.
- A Figma design exists for all four roles (exported as a PDF, summarized in section 12). The team generated it, so some of its content is irrelevant or wrong. **Booklet over Figma.**
- Team name and solution name (for the repo `TeamName_SolutionName`): `[OPEN]`.
- No stack preference; the team accepts a recommended stack (section 15).
- Hours are not a constraint; the deadline is.

---

## 4. The business: Waypoint Group `[BOOKLET]`

Waypoint Group (Pvt) Ltd is fictional. Three brands share one distribution network.

| Brand | Outlets | Goods | Delivery schedule |
|---|---|---|---|
| Fresh | 80 | Groceries, chilled and frozen goods | Daily, before stores open at 8 AM |
| Style | 25 | Hanging garments and cartons | Weekly, with seasonal peaks |
| Tech | 15 | Appliances and consumer electronics (heavy, fragile, valuable) | As needed |

- 120 outlets served from a distribution center in **Peliyagoda** and a regional hub in **Kandy**.
- 60 vehicles: 12 refrigerated trucks, 40 dry-box (ambient) trucks, 8 small vans (4 refrigerated), so **16 chilled-capable**. Each vehicle operates from its assigned depot.
- Brands compete for the same capacity. Fresh must reach 80 supermarkets before 8 AM. Chilled orders need refrigerated vehicles; some outlets are reachable only by van. Style garments fill volume before weight, and about half of Style stores are in malls with fixed delivery windows. Tech demand varies day to day.
- On most days the fleet cannot meet every brand's needs. Dispatchers allocate capacity under outlet access, delivery windows and weekly fuel quotas. When demand exceeds capacity they defer orders and must explain the consequences.

### 4.1 How orders reach the dispatcher
- Fresh outlets order dry groceries for every operating day and place **separate chilled orders** on several days a week. A Fresh outlet can therefore have **two orders for the same delivery day**. Style orders weekly for a scheduled day (larger before seasonal peaks). Tech orders as needed, often one large item.
- **Orders for the next day close at 4 PM.** After the cutoff the dispatcher plans against confirmed orders, available vehicles and constraints. Orders received after the cutoff wait for the following run.

### 4.2 How it works today (what the system replaces)
Spreadsheets and the dispatcher's own knowledge. Instructions by phone, dock conversation and printed run sheets. No shared view of progress once vehicles leave. Drivers report problems by phone. Handwritten notes are the only record.

### 4.3 Problems the solution must address
1. Planning is fragmented (orders re-keyed from phone or message; plan depends on one person).
2. Delivery progress is hard to track (problems found only when the driver reaches the outlet).
3. Deferrals lack a clear record (the same outlet can be skipped on consecutive runs).
4. Communication gives no feedback (no proof of delivery, no way to flag a loading shortfall before departure).
5. Demand is hard to anticipate (Datathon topic; not in scope).
6. Service time and lateness are not predicted (Datathon topic; not in scope).
7. Field connectivity is unreliable: work must continue offline and reconcile when the connection returns.

---

## 5. Operating constraints `[BOOKLET]`

**Vehicles**
- Every vehicle has a weight limit **and** a volume limit; a load must satisfy both.
- Only refrigerated vehicles carry chilled or frozen goods. Refrigerated vehicles may also carry ambient goods. Ambient vehicles cannot carry chilled goods.
- Each vehicle has a **weekly fuel quota**; route distance consumes it.
- A vehicle runs **up to two routes per day**. Waypoint operates **Monday to Saturday**.
- Each vehicle has a driver. Driver availability is not a separate constraint.

**Outlets**
- Every outlet has a delivery window. Fresh deliveries must arrive before 8 AM (individual windows may differ).
- Mall outlets accept deliveries only within the mall's fixed access window.
- Outlets marked `van_only` cannot be served by trucks.
- Unloading differs by outlet: rear dock, curb (street), or shared mall bay.

**Demand and operating days**
- Paydays, festivals, weekends and monsoon affect demand or travel time. Use `calendar.csv` to identify operating dates.
- When demand exceeds capacity the dispatcher decides which orders move to the next run and records the reason.

**Connectivity**
- Coverage can drop across hill country, the Kandy corridor and rural districts. Work away from the depot must stay usable offline and reconcile on reconnect.

---

## 6. The four roles `[BOOKLET]`

| Role | Works | Needs |
|---|---|---|
| **Dispatcher** | Large screen, Peliyagoda planning office, stable connectivity. Builds the daily plan today with a spreadsheet plus knowledge of outlet restrictions and vehicle capabilities. | Visibility of progress and problems after vehicles leave. Explain deferral decisions and identify outlets already skipped. |
| **Loader** | Peliyagoda or Kandy warehouse dock, shared tablet or terminal. Printed loading lists go stale when plans change. | The stop sequence so goods load in an order that supports unloading. Flag missing or damaged items before the vehicle leaves. |
| **Driver** | On the road, personal phone. Uses a paper run sheet and phone calls today. Design for use **when safely stopped**. | Record delivery outcomes and proof of delivery so disputes do not depend on memory. Record work offline and sync on reconnect. |
| **Store manager** | Outlet counter, desktop or phone. Orders by phone or message with no confirmation today. | An expected arrival time to schedule staff. Clear notice when an order is deferred. A way to confirm receipt and report issues. |

### 6.1 Workflow `[BOOKLET]`
| Stage | Role | System requirement |
|---|---|---|
| Place order | Store manager | Capture and confirm the order before the cutoff |
| Close orders | Dispatcher | Bring confirmed orders into one queue |
| Plan and allocate | Dispatcher | Assign served orders to vehicles and trips; identify deferred orders |
| Load | Loader | Load for the planned stop sequence; flag shortfalls |
| Deliver | Driver | Follow the route, record each stop, including offline |
| Confirm receipt | Store manager | Confirm what arrived; report issues |
| Plan future capacity | Dispatcher | Use demand forecasts (Datathon; out of scope) |

---

## 7. Hackathon requirements `[BOOKLET]`

The Designathon design is the implementation specification. Judges assess how faithfully it is delivered.

**Must have**
- A **responsive web application** where a judge completes the delivery workflow across all four roles: planning, loading, delivery, receipt. **Driver and loader are judged on phone-sized screens.** Native apps are optional extras.
- The system **respects operating constraints**: plans account for capacity, temperature requirements, outlet access, delivery windows and fuel quotas.
- **Planning and allocation:** assign orders to vehicles and trips and handle a day when demand exceeds capacity. Automatic, assisted, or manual-with-validation are all allowed, but the result must respect constraints and identify deferred orders.
- **Judge walkthrough:** a numbered walkthrough in the README across all four roles, from planning to completed delivery. Seed the system with the shared datasets and at least one realistic delivery day so it works on a fresh install.

**Deliverables**
1. **Deployed system:** public URL plus credentials for four seeded accounts, one per role.
2. **Source repository:** GitHub monorepo named `TeamName_SolutionName` containing
   - README: setup and configuration, seeded accounts, judge walkthrough, significant departures from the Designathon submission;
   - Docker Compose file and `.env.example` at the root; `docker compose up` must start the **complete stack including database and seed data**;
   - `docs/` at the root: architecture diagram, data model, **AI tool disclosure**.
3. **Demo video:** unlisted YouTube, **5 to 8 minutes**; all four roles completing the walkthrough, then a brief explanation of code and architecture.

**Judging**
| Criterion | Weight |
|---|---|
| Functional completeness across all four roles | 20% |
| Planning and allocation engine | 20% |
| Degradation, offline operation and recovery | 10% |
| Fidelity to the Day 5 design | 10% |
| Engineering quality and architecture | 25% |
| Creativity | 5% |
| Demo video | 10% |

(Designathon weights, for reference: problem framing 25, user context 20, degradation screen quality 15, domain accuracy 10, scope and prioritization 15, visual and interaction design 15. The Designathon asked for personas, screen flows, at least one fully designed degradation screen, a prototype and a demo video; it is already submitted.)

---

## 8. Allocation rules: booklet Task 2B `[BOOKLET]`, adopted as the engine's feasibility rules `[DECISION]`

The Hackathon text lists capacity, temperature, access, windows and fuel but does not spell out trip rules. The booklet's **Task 2B feasibility rules** are the only precise definition of a feasible trip, so the engine adopts them and the README records the choice.

### 8.1 Hard constraints (the validator rejects a plan that breaks any)
| ID | Rule |
|---|---|
| H1 | One trip = one vehicle + one trip number. All orders on it share the **same brand and district**. |
| H2 | `temp_requirement = chilled` needs a vehicle with `temp = reefer`. Reefers may carry ambient. |
| H3 | Outlet `parking_constraint = van_only` needs a vehicle with `type = van`. |
| H4 | A vehicle serves only outlets of its own `depot`. |
| H5 | Whole orders: never split an order across trips or vehicles. |
| H6 | Per trip: sum `order_volume_m3` <= `volume_cap_m3` **and** sum `order_weight_kg` <= `weight_cap_kg`. |
| H7 | At most **2 trips per vehicle per day**. |
| H8 | Daily time budgets (below) are respected. |
| H9 | Only vehicles with status `available` are used (not `in_workshop`). |
| H10 | Deliver only on dates with `calendar.is_operating = 1`. |
| H11 | Arrival within the outlet window (`window_open_time` to `window_close_time`). Early arrival waits until the window opens. Mall outlets: the mall window. |
| H12 | Litres used by a vehicle in an ISO week <= `weekly_fuel_quota_l`. |

H1 to H8 are the Task 2B rules; H9 comes from the Task 2B scenario; H10 to H12 come from the general constraints.

### 8.2 Trip time (exact booklet formula)
```
trip_minutes = depot_to_district_freeflow_min                 (once per trip)
             + inter_stop_freeflow_min * (n_orders - 1)
             + sum over orders of service_allowance_min[brand_of_trip, outlet.dock_type]
```
- The return journey is **not** added; the budgets already allow for it.
- **One stop per order**, even when two orders go to the same outlet (for example a Fresh dry order and a Fresh chilled order): inter-stop time and handling are charged per order.

**Budgets per vehicle per day:** Fresh trips total <= **270 min** (operating window 03:30 to 08:00). Style and Tech trips **combined** <= **480 min** (trading day). The budgets are separate: a vehicle may run 1 Fresh and 1 Style trip, never more than 2 trips in total.

**Worked examples (verified against the CSVs):**
- Gampaha Fresh trip, 3 orders (2 rear dock, 1 street): 37 + 9x2 + 15 + 15 + 16 = **101**.
- Colombo Fresh trip, 4 street stops: 24 + 8x3 + 16x4 = **112**. Together with the Gampaha trip: 213 of 270 minutes. A third trip is not allowed.

### 8.3 Task 2B inputs and outputs (for understanding and engine testing only)
- Scenario S1: one dispatch day at Peliyagoda; orders closed; festival one week away; Fresh demand rising (dairy, meat, produce); not a payday; no monsoon; several vehicles `in_workshop`.
- `task2b_peak_day_scenarios.csv` columns: `scenario, order_ref, outlet_id, brand, district, depot, dock_type, parking_constraint, mall_window, window_open_time, window_close_time, temp_requirement, order_units, order_weight_kg, order_volume_m3, deferred_yesterday (0/1), days_since_last_served`.
- `task2b_peak_day_fleet.csv`: `scenario, vehicle_id, status` (`available` or `in_workshop`).
- Output `submission_task2b.csv`: `scenario, order_ref, outlet_id, decision (served/deferred), vehicle_id, trip_id (1 or 2)`; deferred rows leave vehicle and trip blank.
- The organizers provide `check_allocation.py` to validate feasibility (not optimality). **We have not seen these files.** If available, use them locally as a test oracle for the engine. Do not commit them (Datathon files, confidentiality).

---

## 9. Datathon summary (context only; NOT part of this build) `[BOOKLET]`

Included so the agent understands the shared data and the vocabulary. The team decided to keep the Datathon separate.
- **Task 1:** predict `pred_service_min` and `pred_late_prob` per planned `delivery_id` (labels must be constructed from route legs; lateness = arrival after the window closes; early arrival waits for the window to open).
- **Task 2A:** forecast weekly total and chilled volume (m3) per depot, brand and week over 10 future weeks (only Fresh has chilled; chilled = 0 for Style and Tech). Orders counted once, by the week requested, using calendar `iso_year` and `iso_week`.
- **Task 2B:** peak-day allocation (section 8.3), plus a written prioritization policy that explains which deferrals were unavoidable and which were a choice, and what they cost.
- Historical files: `deliveries_train.csv` and `task1_test_inputs.csv` (one row per order: `delivery_id, order_date, dispatch_date, dispatch_status (attempted/deferred/not_run), outlet_id, brand, district, depot, temp_requirement, order_units, order_weight_kg, order_volume_m3, route_id, seq_in_route, vehicle_id, vehicle_type, vehicle_temp, planned_arrival_time, window_open_time, window_close_time`); `route_legs_train.csv` and `route_legs_test.csv` (one row per leg: `leg_id, date, route_id, seq, depot, vehicle_id, vehicle_type, vehicle_temp, brand, district, from_point, to_outlet, distance_km, planned_depart_time, planned_travel_duration_min, planned_arrival_time, actual_* (training only), arrival_time, leave_outlet_time, monsoon, dow`). **We have not seen the contents of these files.**

---

## 10. Datasets supplied (reference data used by the Hackathon) `[DATA]`

All competition data is synthetic. Files: `outlets.csv`, `vehicles.csv`, `calendar.csv`, `district_travel.csv`, `service_allowance.csv`, `traffic_speed.csv`, `road_conditions.csv`. All were inspected in full or profiled by the team's assistant; every booklet cross-check passed.

### 10.1 district_travel.csv (12 rows, full)
Columns: `district, depot, road_class, free_flow_kmh, depot_to_district_km, depot_to_district_freeflow_min, inter_stop_km, inter_stop_freeflow_min`. Minutes = km / speed x 60, rounded (consistent in every row).

| District | Depot | Class | km/h | Depot to district km | min | Inter-stop km | min |
|---|---|---|---|---|---|---|---|
| Colombo | Peliyagoda | urban | 30 | 12 | 24 | 4 | 8 |
| Gampaha | Peliyagoda | suburban | 45 | 28 | 37 | 7 | 9 |
| Kalutara | Peliyagoda | suburban | 45 | 48 | 64 | 9 | 12 |
| Galle | Peliyagoda | highway | 70 | 120 | 103 | 10 | 9 |
| Matara | Peliyagoda | highway | 70 | 160 | 137 | 12 | 10 |
| Kurunegala | Peliyagoda | suburban | 45 | 95 | 127 | 14 | 19 |
| Puttalam | Peliyagoda | suburban | 45 | 130 | 173 | 18 | 24 |
| Kandy | Kandy | urban | 30 | 8 | 16 | 3 | 6 |
| Matale | Kandy | suburban | 45 | 26 | 35 | 8 | 11 |
| Nuwara Eliya | Kandy | hill | 42 | 78 | 111 | 14 | 20 |
| Badulla | Kandy | hill | 42 | 130 | 186 | 16 | 23 |
| Kegalle | Kandy | suburban | 45 | 40 | 53 | 10 | 13 |

Peliyagoda serves 7 districts; Kandy serves 5.

### 10.2 service_allowance.csv (9 rows, full)
Planning allowance per stop, minutes (not an observed duration).

| Brand | rear_dock | street | mall_bay |
|---|---|---|---|
| Fresh | 15 | 16 | 18 |
| Style | 38 | 46 | 59 |
| Tech | 43 | 55 | 55 |

### 10.3 outlets.csv (120 rows, OUT001 to OUT120, contiguous)
Columns: `outlet_id, brand, district, depot, dock_type, parking_constraint, mall_window, window_open_time, window_close_time`. Every outlet's depot matches its district's depot.

- **By depot and brand:** Peliyagoda Fresh 49, Style 16, Tech 10 (75). Kandy Fresh 31, Style 9, Tech 5 (45). Totals 80 / 25 / 15 (matches the booklet).
- **Per district (Fresh/Style/Tech):** Colombo 14/6/4; Gampaha 10/3/2; Kalutara 7/2/1; Galle 6/2/1; Kurunegala 5/2/1; Matara 4/1/1; Puttalam 3/0/0; Kandy 12/5/3; Matale 6/1/1; Nuwara Eliya 5/1/0; Badulla 4/1/1; Kegalle 4/1/0.
- **dock_type by brand:** Fresh rear_dock 55, street 25 (no mall_bay). Style mall_bay 9, rear_dock 6, street 10. Tech mall_bay 3, rear_dock 7, street 5.
- **parking_constraint:** `mall_dock` is exactly the 12 `mall_bay` outlets. `van_only` is 13 outlets, all with street dock: Fresh OUT001 to OUT003 (Colombo, Peliyagoda), Fresh OUT076 to OUT083 (Kandy district), Style OUT088 and Tech OUT093 (Kandy district). All others are `normal`.
- **Mall outlets (12) and `mall_window`:**
  - OUT015, OUT016: Style, Colombo, 09:00-11:00
  - OUT017, OUT018: Style, Colombo, 10:30-12:30
  - OUT021: Tech, Colombo, 10:30-12:30
  - OUT022: Tech, Colombo, 10:00-12:00
  - OUT035, OUT036: Style, Gampaha, 10:30-12:30
  - OUT056: Style, Galle, 10:00-12:00
  - OUT089, OUT090: Style, Kandy, 10:30-12:30
  - OUT094: Tech, Kandy, 09:00-11:00
  - For all 12, `window_open_time` and `window_close_time` **equal** the mall window. `mall_window` is blank for the other 108 outlets. (So no window intersection logic is needed.)
- **Fresh windows:** open 03:00 (30 outlets), 04:00 (11), 05:00 (21), 05:30 (18); close 07:30 (21), 07:45 (11), 08:00 (48). None close after 08:00.
- **Style and Tech windows:** all non-mall Style (16) and Tech (12) outlets are 09:00 to 17:00 (this is the 480-minute trading day). Mall outlets use their mall window.

### 10.4 vehicles.csv (60 rows, VEH001 to VEH060, contiguous, all diesel)
Columns: `vehicle_id, type, temp, weight_cap_kg, volume_cap_m3, fuel_type, km_per_l, weekly_fuel_quota_l, depot`. **There is no driver column** (drivers must be synthesized in the seed, one per vehicle).

| Depot | Group | Vehicle IDs | Count |
|---|---|---|---|
| Peliyagoda | reefer trucks | VEH001 to VEH007 | 7 |
| Peliyagoda | ambient trucks | VEH008 to VEH034 | 27 |
| Peliyagoda | reefer vans | VEH035, VEH036 | 2 |
| Peliyagoda | ambient vans | VEH037, VEH038 | 2 |
| Kandy | reefer trucks | VEH039 to VEH043 | 5 |
| Kandy | ambient trucks | VEH044 to VEH056 | 13 |
| Kandy | reefer vans | VEH057, VEH058 | 2 |
| Kandy | ambient vans | VEH059, VEH060 | 2 |

Network: 12 reefer trucks, 40 ambient trucks, 8 vans (4 reefer); 16 chilled-capable (Peliyagoda 9, Kandy 7).

**Capacity models (kg / m3):**
- Ambient trucks: 3800/22, 4200/24, 5800/30, 6500/34, 7200/38.
- Reefer trucks: 3610/19.4, 3990/21.1, 5510/26.4, 6180/29.9, 6840/33.4.
- Ambient vans: 1100/8 or 1200/9. Reefer vans: 1040/7.0.
- `km_per_l`: trucks 4.4 to 7.1; vans 10.3 to 11.5. `weekly_fuel_quota_l` 340 to 620 (varies per vehicle; read from the file).
- Peliyagoda model counts: ambient 3800/22 x8, 4200/24 x5, 5800/30 x3, 6500/34 x4, 7200/38 x7; reefer 3610 x1 (VEH007), 3990 x1 (VEH002), 5510 x2, 6840 x3; vans 1100/8 x1, 1200/9 x1, reefer 1040/7 x2.
- Kandy model counts: ambient 3800/22 x2, 4200/24 x6, 5800/30 x1, 6500/34 x2, 7200/38 x2; reefer 3610 x1 (VEH041), 5510 x2, 6180 x2; vans 1200/9 x2, reefer 1040/7 x2.
- Summed single-trip reefer capacity: Peliyagoda 41,220 kg / 207.5 m3; Kandy 29,070 kg / 146.0 m3.

### 10.5 calendar.csv (910 rows)
Columns: `date, dow (0=Mon), dow_name, is_weekend, iso_year, iso_week, is_payday, festival, festival_ramp, is_holiday, monsoon, is_operating`.
- **Range 2024-01-01 to 2026-06-28** (130 ISO weeks; last is 2026-W26). `iso_year` and `iso_week` match the ISO calendar. **Dates after 2026-06-28 are not in the file** (see section 14.1).
- `is_operating` is 0 on every Sunday **and** on 10 non-Sunday holidays: 2024-04-13, 2024-05-01, 2024-12-25, 2025-04-14, 2025-04-15, 2025-05-01, 2025-12-25, 2026-04-13, 2026-04-14, 2026-05-01. Every other Monday to Saturday is operating. 23 holidays total; 12 of them are operating days.
- **Festivals (18 dates):** thai_pongal 2024-01-15, 2025-01-14, 2026-01-15; new_year 2024-04-13, 2025-04-14, 2026-04-13; vesak 2024-05-23, 2025-05-12, 2026-05-01; poson 2024-06-21, 2025-06-10, 2026-05-30; esala 2024-08-19, 2025-08-08; deepavali 2024-10-31, 2025-10-20; christmas 2024-12-25, 2025-12-25. `festival_ramp` rises 0.1 per day over the 9 days before a festival, is 1.0 on the day, 0.0 the day after.
- **Paydays:** 59 (26 on the 25th; 24 on the 30th or 31st; 4 on the 24th; 3 on the 29th; 2 on the 28th); 2 fall on non-operating days.
- **monsoon** is 1 in months 3 to 6 and 10 to 11, else 0 (a monthly flag).

### 10.6 road_conditions.csv and traffic_speed.csv
- `road_conditions.csv`: 10,920 rows (12 districts x 910 dates, same range as the calendar); `disruption_index` 40 to 100 (100 = clear), mean 92.3, median 99; 56.8% of rows below 100; 10.1% below 70.
- `traffic_speed.csv`: 576 rows (12 districts x 24 hours x monsoon 0/1); `speed_index` 32 to 100 (100 = free-flowing). Colombo non-monsoon is lowest at 07h and 08h (47, 46) and 16h and 17h (51, 50), 92 to 94 overnight; monsoon values are lower (33 at 08h). Lowest overall: Kandy 08h monsoon (32).
- **Use:** the plan uses free-flow times (booklet). These two files are display or stretch material only (for example a traffic-aware ETA note). They are not needed for feasibility.

---

## 11. Derived facts `[DERIVED]` (computed by us; the engine must compute them itself, never hard-code)

### 11.1 Maximum stops on one trip, by time budget alone
Largest n with `outbound + inter*(n-1) + allowance*n <= budget`, ignoring weight and volume and assuming every stop has the same dock type. Fresh budget 270, Style and Tech budget 480.

| District | Fresh rear/street/mall | Style rear/street/mall | Tech rear/street/mall |
|---|---|---|---|
| Colombo | 11 / 10 / 9 | 10 / 8 / 6 | 9 / 7 / 7 |
| Gampaha | 10 / 9 / 8 | 9 / 8 / 6 | 8 / 7 / 7 |
| Kalutara | 8 / 7 / 7 | 8 / 7 / 6 | 7 / 6 / 6 |
| Galle | 7 / 7 / 6 | 8 / 7 / 5 | 7 / 6 / 6 |
| Matara | 5 / 5 / 5 | 7 / 6 / 5 | 6 / 5 / 5 |
| Kurunegala | 4 / 4 / 4 | 6 / 5 / 4 | 6 / 5 / 5 |
| Puttalam | 3 / 3 / 2 | 5 / 4 / 3 | 4 / 4 / 4 |
| Kandy | 12 / 11 / 10 | 10 / 9 / 7 | 9 / 7 / 7 |
| Matale | 9 / 9 / 8 | 9 / 8 / 6 | 8 / 6 / 6 |
| Nuwara Eliya | 5 / 4 / 4 | 6 / 5 / 4 | 6 / 5 / 5 |
| Badulla | 2 / 2 / 2 | 5 / 4 / 3 | 4 / 4 / 4 |
| Kegalle | 8 / 7 / 7 | 8 / 7 / 6 | 7 / 6 / 6 |

Consequence: far districts (Puttalam, Badulla, Matara, Kurunegala, Nuwara Eliya) are **time-limited, not capacity-limited**; Style and Tech stops are expensive (38 to 59 min each).

### 11.2 Fuel
- Weekly km allowance (`quota x km_per_l`): trucks about 1,600 to 4,300 km; vans about 3,900 to 6,700 km.
- Round-trip km for one stop: Colombo 24, Gampaha 56, Kalutara 96, Galle 240, Matara 320, Kurunegala 190, Puttalam 260, Kandy 16, Matale 52, Nuwara Eliya 156, Badulla 260, Kegalle 80. Fuel binds only for repeated long trips; local trips never bind.

### 11.3 Capacity pressure points
- 13 `van_only` outlets: 3 Fresh (Colombo) rely on Peliyagoda's 4 vans (2 reefer); 10 (Kandy district: 8 Fresh, 1 Style, 1 Tech) rely on Kandy's 4 vans (2 reefer, 7 m3 and 1040 kg each). Chilled orders for Kandy van-only Fresh outlets are a natural bottleneck.
- Reefer capacity is scarce: 9 chilled-capable vehicles at Peliyagoda, 7 at Kandy. Ambient Fresh orders should use ambient trucks where possible to keep reefers free.

---

## 12. The Figma design `[FIGMA]` (read from a low-resolution PDF export; confirm details visually)

Visual identity: dark-green and mint palette, "Waypoint" logo, consistent cards and tabs across roles. The team generated it; **its data is placeholder**.

**Driver (mobile, 6 frames).** Home: shift header and assigned corridor, offline-cache and sync banner, load composition by brand, list of stops with brand tags and window times, View order and Accept order buttons. Active stop: weight, volume, units, window, distance. Hub handover: scan-style handover, manifest code, "Accept handover and start route", "Report loading discrepancy / recount". Tracking: sequenced stop preview with ETAs, "Update status". Stop progress cards with window and buffer; start trip 2 with accept or decline. History: completed orders and exceptions. Bottom navigation: Home, Accept, Tracking, History.

**Loader (mobile or tablet, 4 frames).** Home: trip cards (vehicle, stops, weight and volume utilization) with Confirm Load and View Load. Trip detail: stop sequence, Confirm Load, Report Load, driver handoff pass (QR). Order list per trip with Report Load. Report form: category (missing pallet, damaged or leaking, short quantity), affected quantity, "Send to dispatcher and adjust load", hold pallet.

**Dispatcher (desktop).** Sidebar: Dashboard, Orders, Planning, Deferred, Loading, Live Monitoring; header with depot selector, delivery date, fleet-online count.
- *Dashboard:* total, unallocated, planned and deferred order counts; vehicle states; planning progress; alerts; active deliveries; cutoff note.
- *Orders:* filterable table, order detail panel (consignee, window, vehicle, items, operational notes and history), Cancel Order modal with mandatory reason and note.
- *Planning:* auto-planned trips awaiting review (payload and volume bars, stops with windows and ETAs), Edit Plan and Confirm Trip per trip, an Add/Remove Orders panel showing recalculated payload and compatible orders, bottom bar with intake count, fleet use, total weight, constraint health, "Re-run Optimizer" and "Confirm All Planned Trips".
- *Deferred:* staged exception queue with reason, history (such as "2x deferred"), next window, dispatcher notes, inspection panel, "Re-allocate" action.
- *Loading Coordination:* trips by bay with stop sequence; "Warehouse Shortfall Detected" with Adjust Plan and Defer Affected Order; departure blocked.
- *Live Monitoring:* active vehicles with progress and delay badges; stop timeline with proof-of-delivery recorded or missing; a dock-blockage alert with Contact Driver, Escalate, Record Decision; a "confirmed trips, locked for dispatch" panel.

**Store manager (mobile and desktop).** Home: chilled-allocation alert, next delivery manifest and expected bay window, 4 PM cutoff countdown, Place New Order, consignment list, call dispatch. Order form (item name, id, temperature, quantity, weight, volume) and a SKU catalogue-style Place Order screen with quantity steppers. Order-deferred notice (what happened, items affected, new date, Accept New Date, Request Urgent Partial Delivery, Call Dispatcher; shows "cached, will sync"). Order confirmation and tracking (progress rail: received, scheduled, loaded, on the way, delivered; ETA). QR "driver ingress" pass. Intake-readiness checklist. Confirm Receipt and discrepancy report (ordered vs received per line; categories short, damaged, wrong item, temperature issue; signed receipt). A desktop variant of confirm and tracking.

**Cross-role threads the design implies (the demo spine):**
1. Dispatcher confirms trip, loader sees it.
2. Loader reports shortfall, dispatcher alert, departure blocked.
3. Loader confirms load, driver accepts handover and starts the route.
4. Driver exception (for example blocked dock), dispatcher live monitoring, decision recorded.
5. Dispatcher defers an order, store manager is notified.
6. Driver delivers, store manager confirms receipt or reports a discrepancy.
7. Store manager orders before the cutoff, the order appears in the dispatcher queue.

### 12.1 Figma versus booklet: conflicts and resolutions `[DECISION]`
| Figma shows | Booklet or data says | Resolution |
|---|---|---|
| Trips mixing Fresh, Style and Tech; a Peliyagoda trip to Kandy | One brand and one district per trip; own depot only | Follow booklet; README departure |
| Batch cutoff 07:00 AM on the dashboard | Orders for the next day close 4 PM | 4 PM |
| No fuel-quota UI | Plans must respect fuel quotas | Engine enforces; add a "fuel remaining" indicator |
| SKU catalogue and line items | Order record is units, kg, m3, one temperature | No SKUs or line items; simplified order form |
| Deferral reasons like "tailgate lift", "helper crew" | Not in the data | Reasons come from checked constraints plus operational reasons plus free text |
| QR handshake as proof of delivery | Booklet requires proof of delivery, not QR | POD = driver outcome plus store receipt; QR or short code is a stretch |
| Driver "accept" or "decline" per order or trip | Drivers follow the dispatch plan | Accept handover only; no decline |
| Store manager header shows a driver ID | Copy-paste error | Fix in implementation |
| Dashboard shows 342 orders, 40 vehicles, dates in Oct 2024 | 120 outlets, 60 vehicles; seed data defines counts | Compute everything from the database |
| "Confirm Orders" bulk action on the orders list | Orders are confirmed when placed before the cutoff | Replace with plan or cancel actions |

A **degradation screen** is a Designathon requirement; the booklet's judging line is "Degradation, offline operation and recovery". Candidate failure scenarios in the Figma: loader shortfall (dispatcher "Warehouse Shortfall Detected"), dock blockage on Live Monitoring, receipt discrepancy, offline driver. Which one the team formally named in the Designathon submission: `[OPEN]`.

---

## 13. Decisions and assumptions (target design after review)

### 13.1 Decisions
| ID | Decision |
|---|---|
| D1 | Engine follows Task 2B feasibility rules and formulas (section 8). Figma's mixed trips are a README departure. |
| D2 | Order cutoff is 16:00 on the day before the delivery date. Later orders roll to the next operating day and carry a `rolled_over` flag. |
| D3 | Weekly fuel quota is enforced; Planning shows fuel remaining. |
| D4 | No SKU catalogue and no order line items. An order is units, kg, m3 and one temperature, plus an optional free-text note. |
| D5 | Deferral reasons come from checked constraints plus operational reasons plus free text for manual deferrals (section 14.5). |
| D6 | Proof of delivery is the driver's recorded outcome (who received, quantity, time) plus the store manager's receipt confirmation, both offline-safe and idempotent. QR or short code is a stretch add-on, never a hard guard. |
| D7 | Repository private, judges invited; email the organizers to confirm dataset terms. |
| D8 | Dashboards and counts are computed from the database. |
| D9 | One order has one temperature. A Fresh outlet's dry and chilled needs become two orders. Only Fresh outlets may place chilled orders (booklet: only Fresh has chilled demand). |
| D10 | Order size entry: store manager enters units and temperature; the server derives kg and m3 from per-brand and per-temperature unit constants calibrated once from historical orders (median kg per unit and m3 per unit). Fallback: manager enters kg and m3. `[OPEN: needs deliveries_train statistics]` |
| D11 | Business clock: all cutoff logic uses `business_now()`. With `DEMO_MODE=true` it returns a fixed time on the day before the seeded delivery day so judges can walk through at any real time. Otherwise it uses the real Asia/Colombo clock. |
| D12 | The engine is deterministic (same input, same output; stable tie-breaks by id). The walkthrough is **coupled to the seed**: on the seeded day, the engine output puts the seeded store manager's outlet on a trip carried by the seeded driver's vehicle at the seeded loader's depot. A CI test enforces this. A pre-planned fallback day is also seeded. |
| D13 | Trips can be edited until LOADED. Each edit increments `plan_version`; the loader confirms only the current version (stale printed lists are a stated booklet pain). |
| D14 | Offline conflict policy: field facts (arrive, outcome, exception, receipt, load check) are always recorded and flagged for the dispatcher if the plan changed; server-authority commands (start trip) are rejected when stale. |
| D15 | The Datathon is excluded from this build. |
| D16 | Seed scope: a full Peliyagoda day for the primary walkthrough; a smaller Kandy day. `[OPEN: confirm]` |
| D17 | Stack as in section 15. |

### 13.2 Assumptions (list in README and docs)
| ID | Assumption |
|---|---|
| A1 | **ETA rule.** Fresh trip 1 departs 03:30. Trip 2 departs when trip 1 ends plus `RELOAD_BUFFER_MIN` (config, default 0). The return journey is **not** added, because the booklet says the budgets already allow for it; adding it would make plans that pass H8 fail H11. Arrival at stop k = previous service end + `inter_stop_freeflow_min`; service start = max(arrival, `window_open_time`); service end = service start + allowance. |
| A2 | **Fuel per trip** = (2 x `depot_to_district_km` + `inter_stop_km` x (n - 1)) / `km_per_l`, charged to the vehicle's ISO week. It counts planned, confirmed and completed trips. The booklet gives no formula; this includes the return leg conservatively. |
| A3 | Style and Tech trips depart so the first arrival is >= its window open; trading day is 09:00 to 17:00 (data). |
| A4 | **Two clocks, one plan.** H8 uses the booklet formula (no waiting) to match the organizers' validator. H11 uses the waiting-aware ETA timeline. A plan must pass both. |
| A5 | Within a trip, stops are ordered by earliest `window_close_time`, then earliest `window_open_time`, then `outlet_id`. Inter-stop time is one constant per district, so order does not change travel time; the tie-break exists only for determinism. |
| A6 | Orders for a Monday delivery close Sunday 16:00 (booklet silent). |
| A7 | Planning uses free-flow times. `traffic_speed` and `road_conditions` are display or stretch only. |
| A8 | One driver per vehicle (60 synthesized drivers); one store manager per outlet (120). The four headline accounts are chosen from this set. |
| A9 | Two orders for the same outlet on one trip are charged as two stops (formula parity). |
| A10 | A planned arrival after the window closes is a hard failure in the automatic planner; a dispatcher may override for non-mall outlets with a mandatory reason. Mall windows are never overridable. |

---

## 14. System design: domain, states, engine, API, offline (target, corrected)

### 14.1 Seed and clock
- The calendar ends 2026-06-28. The seeded delivery day must be an **operating, non-holiday Monday to Saturday inside the calendar range**, with demand above capacity. With `DEMO_MODE=true` the business clock sits on the day before it (for example 14:00). Do not look up the real current date in `calendar.csv`; a real-date fallback would need a documented rule (Sunday off).
- Seed content: reference CSVs (outlets, vehicles, calendar, district_travel, service_allowance; traffic and roads optional), 60 drivers, 120 store managers, four headline accounts (suggested: `dispatcher@waypoint.test`, `loader@waypoint.test`, `driver@waypoint.test`, `store@waypoint.test`), a generated delivery day (Fresh dry order for most Fresh outlets, chilled for some, Style weekly, Tech occasional), some vehicles `in_workshop`, **pre-used fuel litres on a few vehicles** so a `FUEL_QUOTA` deferral can be demonstrated, and history that makes some outlets `deferred_yesterday = 1`.
- Generate our own seed day. Do not commit the organizers' Datathon scenario file.

### 14.2 Domain model (operational tables)
Reference (read-only, from CSV): `depots`, `districts`, `outlets`, `vehicles`, `service_allowance`, `calendar_days`, `road_conditions`, `traffic_speed`.

Operational:
- `users(id, username, password_hash, role, depot_id?, outlet_id?, vehicle_id?, display_name)`; dispatcher and loader scoped to depot(s), driver to a vehicle, store manager to an outlet.
- `vehicle_availability(vehicle_id, date, status[available, in_workshop], note)`.
- `orders(id, outlet_id, delivery_date, placed_at, status, temp_requirement, order_units, order_weight_kg, order_volume_m3, rolled_over, deferral_count, cancel_reason?, note?, client_op_id?)` (brand, district, depot come from the outlet).
- `outlet_service_state(outlet_id, last_served_date, last_deferred_date, consecutive_deferrals)` for `deferred_yesterday` and `days_since_last_served`.
- `plan_runs(id, depot_id, delivery_date, status[OPEN, CLOSED], version, generated_by, generated_at, ranking_config_json, summary_json)`.
- `trips(id, plan_run_id, vehicle_id, depot_id, delivery_date, trip_no[1,2], **brand**, **district**, status, plan_version, depart_time, est_minutes, est_km, est_fuel_l, confirmed_by, confirmed_at)`. Unique (vehicle_id, delivery_date, trip_no).
- `trip_stops(id, trip_id, order_id UNIQUE, seq, eta, service_start_est, service_min, status, receipt_status, arrived_at, completed_at, outcome, quantity_delivered, received_by, outcome_note, device_ts)`.
- `load_checks(id, trip_id, order_id, plan_version, expected_qty, loaded_qty, issue[missing, damaged], note, status[OPEN, RESOLVED], resolution[defer_order, replan_order, proceed_partial], reported_by, resolved_by)`.
- `deferrals(id, order_id, from_delivery_date, reason_code, reason_class, reason_text, consequence_text, details_json, decided_by[engine, dispatcher, system], decided_by_user?, decided_at, notified_at, resolved_at, resolved_to_date)`.
- `receipts(id, stop_id, outcome[full, discrepancy], note, confirmed_by, confirmed_at, qr_token?)`.
- `exceptions(id, trip_id, stop_id, type[dock_blocked, outlet_closed, vehicle_issue, access_problem, other], note, reported_at, status[OPEN, DECIDED], decision[retry, skip], decision_note, decided_by, decided_at)`.
- `fuel_ledger(vehicle_id, iso_year, iso_week, litres_committed)`.
- `events(id, type, payload, created_at)`, `notifications(id, event_id, audience_role, audience_scope, read_at)`, `audit_events` (append-only).
- `sync_ops(client_op_id PK, device_id, client_seq, user_id, op_type, payload, client_ts, received_at, applied_at, result[applied, replayed, applied_with_conflict, rejected], reason)`.

### 14.3 State machines
**Order:** `SUBMITTED` (acknowledged to the store manager at placement with a confirmation code) -> `PLANNED` (in a draft trip) -> `SCHEDULED` (trip confirmed) -> `LOADED` -> `IN_TRANSIT` -> `DELIVERED` or `PARTIALLY_DELIVERED`, or `DEFERRED` (refused, closed, or exception skipped).
`SUBMITTED, PLANNED, SCHEDULED -> DEFERRED` (reason mandatory; store manager notified). `DEFERRED -> SUBMITTED` when carried to the next operating day (run close or requeue; `deferral_count` retained). `SUBMITTED, PLANNED, SCHEDULED -> CANCELLED` (reason required).

**Trip:** `DRAFT -> CONFIRMED -> LOADING -> LOADED -> IN_PROGRESS -> COMPLETED`. `LOADING -> BLOCKED` on a shortfall, back to `LOADING` after the dispatcher resolves it. `CANCELLED` before departure. Edits allowed in DRAFT, CONFIRMED, LOADING, BLOCKED (each bumps `plan_version`); not after LOADED.

**Stop:** `PENDING -> ARRIVED -> DELIVERED, PARTIAL or FAILED`. `PENDING or ARRIVED -> EXCEPTION -> PENDING (retry) or SKIPPED`. Separate `receipt_status`: `NONE, AWAITING, CONFIRMED, DISCREPANCY`.

**Server-enforced guards:** a trip cannot be confirmed with any hard-rule violation; cannot depart while BLOCKED or before the load is confirmed at the current `plan_version`; a stop cannot be DELIVERED without `received_by` and a completion time; fuel quota cannot be exceeded.

### 14.4 Allocation engine (deterministic heuristic plus independent validator)
- **Priority order** (lexicographic, configurable): (1) `deferred_yesterday = 1`; (2) larger `days_since_last_served`; (3) Fresh chilled, then Fresh ambient, then Style and Tech; (4) earlier `window_close_time`; (5) cheaper to serve per trip minute; final tie-break by `order_ref`.
- **Steps:** reject non-operating days; pre-screen each order for unavoidable infeasibility (no reefer, no van, too large, window unreachable); rank; for each order try to add it to an existing open trip of the same depot, brand and district (best fit), else open a new trip on the smallest sufficient eligible vehicle slot (prefer ambient trucks for ambient orders, keep reefers free), else defer with a diagnosed reason; sequence stops; compute ETAs, fuel, utilization; validate the whole plan with the same validator used for manual edits (any violation is a bug).
- **Re-running:** trips already CONFIRMED or later are locked; only DRAFT trips and unassigned orders are re-planned.
- **Modes:** automatic generate; assisted (move, add, remove, defer; every edit is validated and returns the broken rules with numbers); confirm is blocked while any hard rule fails.
- **Loading order** is the reverse of the delivery sequence (last stop loaded first).

### 14.5 Deferral reasons
| Code | Default class | Meaning |
|---|---|---|
| NO_REEFER | UNAVOIDABLE | Chilled order, no available reefer at the depot |
| NO_VAN | UNAVOIDABLE | `van_only` outlet, no available van |
| TOO_LARGE | UNAVOIDABLE | Exceeds the largest eligible vehicle |
| WINDOW_INFEASIBLE | UNAVOIDABLE | Cannot arrive inside the window under the time rules |
| CAPACITY_FULL | CHOICE | All eligible trips are full by weight or volume |
| TIME_BUDGET | CHOICE | Adding it exceeds 270 or 480 minutes |
| TRIP_LIMIT | CHOICE | All eligible vehicles already run 2 trips |
| FUEL_QUOTA | CHOICE | Would exceed the vehicle's weekly litres |
| SHORTFALL | OPERATIONAL | Loader reported missing stock before departure |
| DELIVERY_FAILED | OPERATIONAL | Driver outcome refused or outlet closed |
| EXCEPTION_SKIPPED | OPERATIONAL | Dispatcher skipped a stop after a driver exception |
| MANUAL | DISPATCHER | Dispatcher decision with free-text reason |

The class is **computed, not assumed**: after a deferral the engine re-checks the order alone against the full available fleet. Infeasible alone means UNAVOIDABLE; feasible alone means CHOICE (it lost to priority or shared capacity). Each deferral stores a plain-language explanation with the exact numbers, the consequence (days since last served, consecutive deferrals), notifies the store manager (reason and new expected date), and a second consecutive deferral raises a dispatcher alert.

### 14.6 API contract (base `/api/v1`, JSON, FastAPI generates `/openapi.json`)
- **Conventions:** JWT bearer auth; role and scope from the token, enforced server-side. Field roles send `client_op_id` (UUID), `client_seq` (monotonic per device) and `client_ts` on mutating calls; the server stores them in `sync_ops`; replays return the original result. Errors: `{error:{code,message,details}}`; rule violations use `422 CONSTRAINT_VIOLATION` with `details.violations[{rule,message,actual,limit}]` using H-ids. Other codes: `PLAN_CHANGED`, `NOT_OPERATING_DAY`, `INVALID_TRANSITION`, `FORBIDDEN_SCOPE`, `OPEN_SHORTFALL`, `STALE_PLAN_VERSION`. SSE needs a token mechanism (EventSource cannot set headers): use a short-lived stream token in the query string or a fetch-based stream. Serve the API and the web app from one origin (reverse proxy `/api`).
- **Auth and reference:** `POST /auth/login`, `GET /me`, `GET /ref/outlets`, `/ref/vehicles`, `/ref/calendar`, `GET /ref/config` (cutoff, budgets 270 and 480, unit constants, business clock, demo flag).
- **Store manager:** `POST /orders`; `GET /orders`; `GET /orders/{id}` (with timeline and deferral history); `POST /orders/{id}/cancel`; `GET /outlets/{id}/expected-deliveries`; `POST /stops/{id}/receipt`; `GET /notifications`; `POST /notifications/{id}/read`.
- **Dispatcher planning:** `GET /dashboard`; `GET /dispatch/queue`; `POST /plans/generate` (`regenerate` keeps locked trips); `GET /plans`; `POST /plans/validate`; `POST /trips/{id}/orders` (add); `DELETE /trips/{id}/orders/{order_id}`; `POST /orders/{id}/defer`; `POST /orders/{id}/requeue`; `POST /trips/{id}/confirm`; `POST /trips/{id}/cancel`; `POST /plans/close-run` (blocked until every order is on a trip or has a deferral; carries deferred orders to the next operating day and updates outlet service state); `GET /plans/summary`; `GET /fuel`; `GET /fleet` (availability by date).
- **Dispatcher monitoring and deferrals:** `GET /monitoring/live` (delay = actual or projected arrival minus ETA, rule-based, no ML); `GET /alerts`; `POST /exceptions/{id}/decision` (retry or skip); `POST /load-checks/{id}/resolve` (defer_order, replan_order or proceed_partial); `GET /deferrals`; `GET /outlets/{id}/skip-history`.
- **Loader:** `GET /loading/trips`; `GET /trips/{id}/load-list` (returns `plan_version`, delivery sequence, reverse load order, quantities); `POST /trips/{id}/load-start`; `POST /trips/{id}/load-checks`; `POST /trips/{id}/load-confirm` (requires current `plan_version`, no open shortfall).
- **Driver:** `GET /driver/trips`; `POST /trips/{id}/start`; `POST /stops/{id}/arrive`; `POST /stops/{id}/outcome` (`delivered, partial, refused, closed`; quantity; `received_by`; note; completed_at); `POST /stops/{id}/exception`; `POST /trips/{id}/complete`; `POST /sync` (batch replay into the same handlers).
- **Live updates:** `GET /events/stream` filtered by caller scope; clients refetch on events and fall back to 15 second polling. Events: `order.submitted`, `order.deferred`, `order.cancelled`, `plan.generated`, `trip.confirmed`, `trip.updated`, `loading.shortfall`, `shortfall.resolved`, `trip.loaded`, `trip.started`, `stop.arrived`, `stop.outcome`, `stop.exception`, `exception.decided`, `receipt.confirmed`, `receipt.discrepancy`, `sync.reconciled`, `sync.conflict`, `run.closed`.

### 14.7 Offline and sync policy
- The driver app caches the day's trips (stops, windows, order details, ETAs) while online, writes actions to a local IndexedDB queue, and replays when connectivity returns. Order of application is by (`device_id`, `client_seq`), not by device clock; keep `client_ts` and flag skew above 10 minutes against server receipt time.
- Each op result is `applied`, `replayed`, `applied_with_conflict` or `rejected`. **Field facts that physically happened are never rejected**: if the plan changed meanwhile (trip cancelled, stop removed), record them as `applied_with_conflict` and alert the dispatcher. Commands that need server authority (start trip) are `rejected` if the trip is cancelled, blocked or the plan version is stale.
- UI states: Online, Offline (N pending), Syncing, Needs attention. Manual "Sync now"; retry with backoff. The loader supports the same queue as secondary scope (Peliyagoda connectivity is stable). Store manager is online-only; draft saving is optional.

---

## 15. Recommended stack, repo and delivery

**Stack (recommended; no team preference):** PostgreSQL; FastAPI (Python) with SQLAlchemy, Alembic and Pydantic (auto OpenAPI is the machine-readable contract; Python suits the engine); React + TypeScript + Vite + Tailwind as **one installable PWA** with role-based layouts (mobile-first for driver, loader and store manager; desktop for dispatcher) and a shared design system from the Figma palette; TanStack Query; IndexedDB (for example Dexie) and a service worker for offline; Server-Sent Events for live updates; typed client generated from OpenAPI; a mock server from the OpenAPI so front-end work is not blocked; Docker Compose with `db`, `api`, `web` (and a reverse proxy) plus a migrate-and-seed step; deploy to a **single VM behind HTTPS**. Avoid Kubernetes at this deadline.

**Repo layout:** `TeamName_SolutionName/` with `apps/api`, `apps/web`, `db/seed` (generator and reference CSV loader), `docs/` (architecture diagram, data model, AI tool disclosure, spec pack), `docker-compose.yml`, `.env.example`, `README.md` (setup, seeded accounts, numbered judge walkthrough, departures from the Designathon design, assumptions list), `AGENTS.md` (agent rules).

**Engineering rules for the agent:** the engine and validator are **pure, deterministic functions** with no HTTP or DB inside; one validator serves the engine and manual edits; migrations through Alembic; idempotent seed; health checks; no hard-coded reference data; every endpoint scope-checked server-side; unit tests for each H-rule, the booklet worked examples (101 and 112 minutes, 213 of 270), determinism, the fairness rule, formula parity for same-outlet orders, the two-clocks rule, deferral reasons present and notified, the golden walkthrough test (D12), and sync idempotency and conflict cases.

**Judge walkthrough (draft outline, to be finalized in the README):** (1) store manager places an order before the cutoff and receives a confirmation; (2) dispatcher sees the queue, generates the plan, reviews deferrals with reasons, edits one trip, confirms; (3) loader opens the list in reverse load order, reports a shortfall, dispatcher resolves it, loader confirms the load; (4) driver accepts handover, starts, arrives and records outcomes, goes offline, records a stop, reconnects and sees sync; (5) store manager sees the ETA, confirms receipt and reports a discrepancy; (6) dispatcher monitors live progress and the deferral notice reaches the store manager.

---

## 16. Plan and time-critical scope

### 16.1 Reality check
The Hackathon closes **Sunday 4 Oct, 11:59 PM**. Treat roughly **Saturday (build) plus Sunday morning (integrate and finish)** as working time, with the last hours reserved for freeze, fresh-install test, README, docs, recording and submission. Aim to submit with at least two hours of buffer.

### 16.2 Team split (proposal)
- **Backend (Himesh):** schema, seed, allocation engine, validator, API.
- **Dispatcher web:** the largest UI (dashboard, orders, planning with add/remove panel, deferred, loading coordination, live monitoring).
- **Driver and loader phone UI,** including the offline queue.
- **Store manager UI and infrastructure:** Docker, deploy, docs, README walkthrough, demo script.

### 16.3 Scope tiers
- **Tier 0 (must demo):** login for four roles; seeded data; place order with confirmation; plan generate with the engine (H1 to H9, H11, H12) and deferrals with reasons and notices; trip confirm; loader list, shortfall report and load confirm; driver start, arrive and outcome with an offline queue and sync; store manager ETA, receipt and deferral notice; minimal dispatcher dashboard and live monitoring; Docker Compose and deployment; README walkthrough; docs; video.
- **Tier 1:** assisted editing panel with validator feedback; sync-conflict display; fuel remaining indicator; deferred queue page with history; notifications and SSE.
- **Tier 2 (stretch):** QR or short-code handover, intake-readiness checklist, SKU catalogue, native apps, maps, traffic-aware ETA, fleet availability editing.

### 16.4 Build slices (vertical, each with tests)
S0 foundation (repo, compose, migrations, reference seed, auth, deploy of a hello world); S1 engine and validator (pure Python, starts immediately in parallel); S2 orders, planning API and dispatcher planning UI; S3 loading and shortfall; S4 driver trip and offline; S5 store manager; S6 monitoring, dashboard, deferred; S7 seed day, walkthrough, docs, README, video.

### 16.5 Prompting the agent
One slice per prompt; point to this file and the spec files; require tests and a statement of which rules are enforced; review diffs; never let the agent change the contract (section 14.6) or the rules (section 8) without updating this file. Log which work was AI-assisted for the AI tool disclosure.

---

## 17. Known defects in the earlier spec drafts (v1.0 of Specs 01 to 03) and the intended fixes

The three drafts (01 decisions, domain and states; 02 business rules and allocation; 03 API contract) are mostly sound. Fix these when correcting them:

1. Spec 03 cites **D10** (order size entry) but Spec 01 never defines it. Define it (section 13.1).
2. **D6 contradicts itself** (text says QR handshake, status says follow booklet), and Spec 01's guard "a stop cannot be DELIVERED without a valid QR token" conflicts with Spec 03 marking QR as stretch. Use D6 above; make `qr_token` optional.
3. **Order status name collision:** Spec 01's `CONFIRMED` (trip confirmed) clashes with the booklet's "confirmed orders" (accepted before cutoff). Use `SUBMITTED, PLANNED, SCHEDULED`.
4. **Stop outcomes do not match stop states** (driver outcomes delivered, partial, refused, closed versus states DELIVERED, DISCREPANCY, EXCEPTION). Use the stop states and the separate `receipt_status` above.
5. **Missing transitions:** `SCHEDULED -> DEFERRED` (shortfall flow), and who moves a trip from CONFIRMED to LOADING (add `load-start`).
6. **Missing tables or fields:** `trips.brand` and `trips.district` (needed for H1), `plan_runs`, `vehicle_availability`, `outlet_service_state`, `notifications`, `plan_version`; vague `priority_inputs` and "further fields [TBC]" on orders (use the booklet order-record names).
7. **Missing endpoints:** load-start, shortfall resolution, `close-run`, requeue, dashboard, fleet availability, order detail, dispatcher cancel with reason; `regenerate` must keep locked trips.
8. **Spec 02 ETA rule** adds a return leg to trip 2, which can fail H11 on plans that pass H8; use A1. It also says "nearest-first" for stop order, which is meaningless because inter-stop time is constant per district; use A5.
9. **Spec 03 cross-reference** "Spec 02, section 8" for the walkthrough coupling test does not exist; add the golden test to Spec 02.
10. **Offline policy** rejecting a completed delivery as `PLAN_CHANGED` loses a physical truth; use `applied_with_conflict`. Order ops by `client_seq`, not `client_ts`.
11. **No business clock or demo mode**, so judges testing after 16:00 would see every new order roll over; add D11.
12. **Deferral codes** lack DELIVERY_FAILED and EXCEPTION_SKIPPED; the unavoidable-versus-choice class should be computed by the solo-feasibility test.
13. **SSE with JWT** needs a stream-token or fetch-based approach (EventSource cannot send headers).
14. Statuses in Spec 01's decision log still say "Proposed" for D2, D3, D5, D8, which the team has now adopted.
15. Mall-window "intersection" in H11 is unnecessary (data shows the windows are identical); the Style and Tech trading-day hours are now known (09:00 to 17:00).

---

## 18. Open items `[OPEN]`

1. D10 calibration: per-brand and per-temperature kg and m3 per unit from `deliveries_train.csv`, or switch to manager-entered kg and m3.
2. Which failure scenario the Designathon submission formally named as its degradation screen.
3. Confirm with the organizers that a private repo with judge access satisfies the repo and dataset-terms requirements.
4. Team name and solution name for the repo.
5. Hosting target for the single-VM deployment.
6. Kandy seeded day: confirm yes (smaller).
7. Monday cutoff (A6) and the engine assumptions A1 to A3.
8. Samples of `task2b_peak_day_scenarios.csv`, `task2b_peak_day_fleet.csv` and `deliveries_train.csv` (for the seed day design and D10), and whether `check_allocation.py` is available locally.
9. Exact seeded credentials and the order of accounts in the walkthrough.

---

## 19. What this file does not know

- The contents of `deliveries_train.csv`, `route_legs_*.csv`, `task1_test_inputs.csv`, `task2a_test_inputs.csv`, `task2b_*` files and `check_allocation.py`.
- The Figma beyond what a low-resolution PDF shows (for example whether a dedicated proof-of-delivery capture screen exists in the driver frames).
- The team's name, hosting choice, and the exact Designathon submission text.
- Anything about the real current time of day; assume the deadline is tight.

---

## 20. Glossary

**Run:** one dispatch cycle for a depot and delivery date. **Trip:** one vehicle load going to one district for one brand (trip number 1 or 2). **Stop:** one order delivered on a trip. **Deferral:** an order moved to the next run with a recorded reason. **Reefer:** refrigerated vehicle. **Ambient:** non-refrigerated. **van_only:** outlet that trucks cannot reach. **Mall window:** fixed access window for mall outlets. **Free-flow:** clear-road travel time used for planning. **Shortfall:** missing or damaged goods found at loading. **POD:** proof of delivery. **PWA:** installable web app that works offline. **Golden test:** CI test that pins the seeded walkthrough outcome.
