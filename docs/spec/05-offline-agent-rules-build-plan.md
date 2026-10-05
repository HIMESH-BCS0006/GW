# Spec 05: Offline and Recovery, Build Plan

Conforms to PROJECT_CONTEXT.md sections 14.7, 15, 16. Private. Agent rules now live in `AGENTS.md` (repo root).

## 1. Clock check
Today is Saturday 3 October 2026; the Hackathon closes Sunday 4 October, 11:59 PM (Sri Lanka). Treat Saturday (build) plus Sunday morning (integrate and finish) as working time. Reserve the last hours for feature freeze, fresh-install test, README, docs, recording and submission, and submit with at least two hours of buffer.

## 2. Offline and recovery (booklet p.5: usable offline, reconcile on reconnect)

**Who:** driver (required); loader (secondary, same queue); store manager is **online-only** (draft saving optional); dispatcher has stable connectivity.

**Mechanism**
- Installable PWA: service worker caches the app shell and the last good `GET` of trips; the driver app caches the day's trips (stops, windows, order details, ETAs) while online.
- Actions go to an IndexedDB queue (Dexie). Each op: `client_op_id` (UUID), `client_seq` (monotonic per device), `client_ts`, `device_id`, type, payload, `plan_version` seen.
- Sync triggers: `online` event, app focus, retry with backoff, and a manual "Sync now". Do not rely on background sync.
- Replay via `POST /sync` into the same handlers. **Order of application is (`device_id`, `client_seq`), not the device clock.** Keep `client_ts`; flag skew above 10 minutes against server receipt time.

**Op results:** `applied`, `replayed` (duplicate `client_op_id`, original result returned), `applied_with_conflict`, `rejected`.

**Conflict policy (D14)**
- Field facts that physically happened (arrive, outcome, exception, receipt, load check) are **never rejected**. If the plan changed meanwhile (trip cancelled, stop removed), record them as `applied_with_conflict` and alert the dispatcher (`sync.conflict`).
- Server-authority commands (start trip) are `rejected` if the trip is cancelled, blocked, or the `plan_version` is stale.
- Stop outcomes keep device time (`completed_at`) and server time (`received_at`), so the dispatcher sees "recorded offline at 08:12, synced at 09:05".

**UI states (field screens):** Online; Offline (N pending); Syncing; Needs attention (conflicts or rejects, with the reason and next step). Pending actions show a clock icon.

**Demo aid (`[ASSUMPTION]`):** a "Simulate offline" switch in the field apps so the video does not depend on browser dev tools.

**Headline degradation scenario (D18):** the driver cannot deliver on time on the date because of a sudden failure (Spec 04 section 5). It combines this offline machinery (report queued offline, replay, conflict flag) with the exception and decision flow. Secondary scenarios that come with the core build: loader shortfall blocking departure, offline driver sync.

## 3. Team split (proposal)
- Backend (Himesh): schema, seed, engine, validator, API.
- Dispatcher web: dashboard, orders, planning with add/remove panel, deferred, loading coordination, live monitoring.
- Driver and loader phone UI, including the offline queue.
- Store manager UI and infrastructure: Docker, deploy, docs, README walkthrough, demo script.

## 4. Build slices (vertical, each with tests; PROJECT_CONTEXT 16.4)
| Slice | Content |
|-------|---------|
| 0 | Foundation: repo, compose, migrations, reference seed, auth, deploy of a hello world |
| 1 | Engine and validator (pure Python; starts immediately, in parallel with Slice 0) |
| 2 | Orders, planning API and dispatcher planning UI |
| 3 | Loading and shortfall |
| 4 | Driver trip and offline |
| 5 | Store manager |
| 6 | Monitoring, dashboard, deferred |
| 7 | Seed day, walkthrough, docs, README, video |

Tiers: see Spec 04 section 4. Cut from Tier 2 first, then Tier 1.

## 5. Judge walkthrough (draft outline for the README)
1. Store manager places an order before the cutoff and receives a confirmation.
2. Dispatcher sees the queue, generates the plan, reviews deferrals with reasons, edits one trip, confirms.
3. Loader opens the list in reverse load order, reports a shortfall; dispatcher resolves it; loader confirms the load.
4. Driver accepts handover, starts, arrives and records outcomes; goes offline, records a stop, reconnects and sees the sync. **Then the sudden failure:** the driver reports a vehicle issue (offline is fine), the dispatcher sees the at-risk stops on Live Monitoring and records a decision (skip or retry).
5. Store manager sees the ETA, confirms receipt and reports a discrepancy.
6. Dispatcher monitors live progress; the deferral (or ETA-change) notice from the failure reaches the store manager.
(Finalize with the seeded accounts and the golden-test outlet.)

## 6. AI disclosure
Keep a running log in `docs/ai-disclosure.md` from now on (who, tool, what was generated, what was reviewed or rewritten by hand).
