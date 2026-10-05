# AGENTS.md: rules for every AI coding session in this repo

> Private repository. Specs contain dataset derivatives (competition terms forbid publishing them). Do not paste them into public tools, forums or public repos.

## Read first
1. `docs/PROJECT_CONTEXT.md` (the single source of context; read all of it before writing code or specs).
2. `docs/spec/01` to `07` (they conform to the context file; if they ever disagree, the context file wins and you flag the difference).

## Source precedence
Challenge Booklet facts > supplied datasets > Figma. Every data value in the Figma (IDs, counts, dates, times, vehicle names, cutoffs, trip compositions) is a placeholder, not a requirement. Record each change from the Figma as a "departure" for the README.

## Never invent
If something is tagged `[OPEN]` or is not in the context file or specs, stop and ask. Do not fill gaps with plausible guesses. Do not hard-code values that exist in the CSVs; read them from the database seeded from the CSVs.

## Scope per session
Do ONLY the slice named in the prompt, in your assigned folder. Do not change an endpoint's path or shape, a state machine, or a rule (H1-H12) without updating the spec files in the same change and saying so.

## Stack (PROJECT_CONTEXT section 15)
- Backend: Python, FastAPI, SQLAlchemy, **Alembic** migrations, Pydantic (auto OpenAPI = machine-readable contract), PostgreSQL.
- Frontend: React + TypeScript + Vite + Tailwind, one installable PWA with role-based layouts (mobile-first for driver, loader, store manager; desktop for dispatcher); TanStack Query; IndexedDB via Dexie; service worker; typed API client generated from OpenAPI; a mock server from the OpenAPI so front-end work is not blocked.
- Live updates: Server-Sent Events (stream token in the query string or a fetch-based stream; EventSource cannot set headers) with a 15 s polling fallback.
- Run: Docker Compose with `db`, `api`, `web` (plus a reverse proxy serving API and web from one origin, `/api`) and a migrate-and-seed step. `.env.example` at the root. Deploy to a single VM behind HTTPS.

## Repo layout
```
TeamName_SolutionName/
  apps/api   apps/web   db/seed (generator + reference CSV loader)
  docs/ (PROJECT_CONTEXT.md, architecture diagram, data model, ai-disclosure.md, spec/)
  docker-compose.yml  .env.example  README.md  AGENTS.md
```
Do NOT commit Datathon files (training, test, scenario CSVs, check_allocation.py).

## Engineering rules
- The engine and validator are **pure, deterministic functions** with no HTTP or DB inside. One validator serves the engine and manual edits. Same input gives the same output; stable tie-breaks by id.
- Rule IDs H1-H12, reason codes, budgets and config live in one constants module.
- Idempotent seed; health checks; every endpoint scope-checked server-side (role and scope from the token).
- Time: store timestamps in UTC, display in Asia/Colombo (UTC+05:30). Clock times `HH:MM`; durations in minutes. All cutoff logic uses `business_now()`.
- Field roles send `client_op_id`, `client_seq`, `client_ts` on mutating calls.
- Field roles work at 390 px width. Every screen has loading, empty and error states; driver and loader also have offline states.

## Definition of done (every slice)
1. Works from a clean clone with `docker compose up`.
2. Tests pass. Required tests across the project: each H-rule; booklet examples (101 and 112 minutes, 213 of 270); determinism; fairness rule; formula parity for same-outlet orders; two-clocks rule; deferral reasons present and notified; golden walkthrough test; sync idempotency and conflict cases.
3. Endpoints match Spec 03; screens match Spec 04.
4. Final agent message lists: files changed, the booklet rule behind each constraint implemented, assumptions made, how to run.
5. A line is appended to `docs/ai-disclosure.md` (who, tool, what was generated, what was reviewed or rewritten by hand).
