# 07: Ready-to-paste prompts by slice

Private. Conforms to PROJECT_CONTEXT.md section 16. One prompt per person, own branch and folder. Every prompt starts with the same two lines; paste them as is. Replace only `{braces}`. Review each diff yourself and check the agent's "booklet rule behind each constraint" list.

Common header (put at the top of every prompt):
```
Read AGENTS.md, docs/PROJECT_CONTEXT.md and docs/spec/01 to 07. Source precedence: booklet > datasets > Figma.
Never invent data or rules; if something is [OPEN] or missing, stop and ask. Do ONLY the slice described below.
```

Order: Slice 0 and Slice 1 start together (Slice 1 is pure Python and needs no running stack). Then the contract checkpoint, then Slices 2 to 7.

---
## Slice 0: foundation

**0-A Backend (you)**
```
Slice 0 backend. In apps/api: FastAPI + SQLAlchemy + Alembic + PostgreSQL. Create migrations for the tables in
docs/spec/01 section 3. Seed job in db/seed (idempotent): load the reference CSVs with the assertions in
docs/spec/06 section 1; create 60 drivers, 120 store managers, dispatcher and loader accounts, and the four
headline accounts (bindings to be finalised in Slice 7). Do NOT generate orders or extend the calendar yet.
JWT login (POST /auth/login, GET /me) with role and scope enforced server-side. Stub EVERY endpoint in
docs/spec/03 with Pydantic request/response models and example responses telling one consistent story; include
client_op_id, client_seq, client_ts, plan_version and the error format. Add business_now() (D11, DEMO_MODE) and
GET /ref/config. GET /openapi.json must work; add a script exporting docs/openapi.yaml.
Final message: files changed, assumptions, how to run, ambiguities in docs/spec/03.
```
**0-B Dispatcher frontend shell (Dev 2)**
```
Slice 0 dispatcher shell. In apps/web (Vite + React + TypeScript + Tailwind; create it if missing and say so):
login, role-based route guard from GET /me, API client generated from docs/openapi.yaml, TanStack Query, dispatcher
layout (sidebar Dashboard, Orders, Planning, Deferred, Loading, Live Monitoring; header with depot, delivery date,
connection status), design tokens from the Figma palette. Pages are empty states with titles only.
```
**0-C Driver/loader shell and offline core (Dev 3)**
```
Slice 0 field shell. In apps/web: mobile layouts at 390 px with the Figma bottom navigation (driver: Home, Accept,
Tracking, History; loader: Home, Assign, Report), role-guarded routes, empty pages for D1-D5 and L1-L3. Offline core
(Dexie): a queue module with the op shape in docs/spec/05 section 2 (client_op_id, client_seq, client_ts, device_id),
ordering by (device_id, client_seq), a connection-status hook (Online, Offline N pending, Syncing, Needs attention),
and unit tests for enqueue, ordering and replay idempotency.
```
**0-D Infra (Dev 4)**
```
Slice 0 infra. docker-compose.yml at the root with db, api, web, a reverse proxy serving API and web from one origin
(/api), and a migrate-and-seed step that runs after the api is healthy; health checks. .env.example with every
variable (DB, JWT secret, DEMO_MODE, SEED_DELIVERY_DATE, account passwords). Dockerfiles for apps/api and apps/web.
Deploy a hello world to {single VM / target} behind HTTPS and document it. docs/architecture.md (Mermaid) and the
heading structure of docs/ai-disclosure.md. Do not edit application source.
```

## Contract checkpoint (30 min, all four)
Open `/docs` on the stub, compare with `docs/spec/03`, fix mismatches, re-export `docs/openapi.yaml`, regenerate client types, start a mock server from the OpenAPI (for example Prism) for the front-end devs, commit.

---
## Slice 1: engine and validator (pure Python, no HTTP or DB)

**1-i Validator**
```
Slice 1 validator. In apps/api/engine: rules.py (H1-H12, reason codes and classes, budgets 270 and 480, config) and
validator.py: validate_plan(plan, ref_data, fuel_state) returning violations {rule, message, actual, limit, trip_id,
order_id}. Implement the trip-time formula in docs/spec/02 section 2 exactly, the two-clocks rule (H8 formula, H11
waiting-aware ETA, A1 A3 A4 A5), A9 stop parity and the A10 override rules. Tests per docs/spec/02 section 8 items 1, 2,
5, 6 using the real reference CSVs. List the booklet page behind each rule.
```
**1-ii Allocator**
```
Slice 1 allocator. In apps/api/engine/allocator.py: allocate(orders, vehicles, ref_data, fuel_state, date) -> plan with
DRAFT trips, stops, ETAs, est_fuel_l, and deferrals (reason_code, computed reason_class via the solo-feasibility test,
plain-language text with exact numbers, consequence_text). Follow docs/spec/02 sections 4-6 exactly, including
pre-screening, ranking config (stored with the run), best fit, keeping reefers free, locked trips on re-run, and a final
validate_plan check. Tests: docs/spec/02 section 8 items 3, 4, 7, 8.
```

---
## Slice 2: orders, planning API and dispatcher planning UI
**2-A Backend (you):** replace stubs with real logic for POST/GET /orders, /orders/{id}, cancel, /dispatch/queue, /plans/*, /trips/{id}/orders, /orders/{id}/defer, requeue, /trips/{id}/confirm, close-run, /fuel, /fleet, /dashboard, using engine/ and business_now(); 422 CONSTRAINT_VIOLATION on invalid confirm; D9 and cutoff rules; events written. API tests.
**2-B Dispatcher UI (Dev 2):** P2 Orders (no "Confirm Orders") and P3 Planning per docs/spec/04 section 2.3 (bars for weight and volume, trip minutes vs budget, ETAs, fuel remaining, edit panel with violations, deferred list with reason and class, close run). Work against the mock until real endpoints land.

## Slices 3 to 7 (prompts to be written the same way once Slices 0-2 land)
- **3 Loading and shortfall:** load-start, load-list (plan_version, reverse order), load-checks, resolve, load-confirm (STALE_PLAN_VERSION, OPEN_SHORTFALL); L1-L3 and P4.
- **4 Driver, offline and the degradation scenario:** start, arrive, outcome, exception, complete, /sync with `applied_with_conflict` rules; D1-D4, sync states, "Simulate offline". Prompt addition: "Implement the scenario in docs/spec/04 section 5 and docs/spec/03 section 7: a vehicle_issue exception covers all stops not yet DELIVERED; compute projected_arrival and at_risk in GET /monitoring/live; exception decision retry|skip with the A10 rules; skipped stops defer their orders with EXCEPTION_SKIPPED, notify store managers and update outlet_service_state; write the tests for it."
- **5 Store manager:** SM1-SM5 (online-only); D10 order form; notifications.
- **6 Monitoring, dashboard, deferred:** P1, P5 (at-risk badges, Record decision), P6, SSE with stream token, alerts.
- **7 Seed day, walkthrough, docs, README, video:** generator per docs/spec/06, golden test and fallback day, README with accounts, numbered walkthrough, departures and assumptions, architecture and data-model docs, AI disclosure, fresh-install test.
