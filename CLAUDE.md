# ServeConnect Monorepo — Claude Development Rules

> Read and follow every rule before starting **any** task (feature, fix, refactor, chore, hot-fix, spike) in **any** project of this repo. "It's only a small change" never excuses skipping a rule.
> A task ends only when its **plan file** (§1) is updated and the matching `docs/*.md` files are updated (§12). Code that compiles and passes its tests is not "done".
> Scope: the whole **ServeConnect** monorepo — a church service & community platform that connects **servants** with the **served** (members, children, youth, families), offline-first. This file holds the **repo-wide** rules. Each project adds its own `CLAUDE.md` with stack-specific rules.
> Product context lives in `docs/00-brd.md` (the BRD). Read the relevant module of it before designing anything.

**Rule precedence:** this root file applies everywhere. A project's `CLAUDE.md` adds detail for its own code and wins on stack-specific conventions. When the two differ on **security, safeguarding, PII, audit, or data-loss** rules, the **stricter** rule wins.

**Agent orchestration (binding on every prompt):** start feature work with `/orchestrate <request>` — the **orchestrator** runs the mandatory pipeline: business-development discussion loop (until the user says they are satisfied) → business-analyst-planner → developer agents (parallel waves) → QA agents (parallel) → security-auditor → user confirmation → git-expert. The **business-analyst-planner's plan is the plan file in `plans/` (§1)**: it is written there from `plans/_TEMPLATE.md`, every agent reads it, and each step is ticked and logged there as the pipeline advances. The full rule is imported below and is binding.

@.claude/rules/feature-workflow.md

---

## Repository Layout

```
Serv-Connect/                     # monorepo root (single git repo)
├── CLAUDE.md                     # this file — repo-wide rules
├── docs/                         # shared docs for every project (§4)
│   ├── 00-brd.md                 # Business Requirements Document — business source of truth
│   └── walkthroughs/             # shared walkthrough history (§3)
├── plans/                        # one living plan file per feature / long-running task (§1)
│   ├── README.md                 # plan index + status board
│   └── _TEMPLATE.md              # copy this to start a plan
├── designs/                      # SVG / HTML design references (§13)
│   ├── mobile/{en,ar}/           # Flutter app screens — English (LTR) / Arabic (RTL)
│   └── dashboard/{en,ar}/        # web/admin dashboard screens
├── sev_connect_backend/          # Spring Boot 4 + Kotlin + Gradle API — rules: sev_connect_backend/CLAUDE.md
├── serv_connect_mobile/          # Flutter mobile client — rules: serv_connect_mobile/CLAUDE.md
└── serv_connect_dashboard/       # React + TypeScript + Vite web/admin dashboard — rules: serv_connect_dashboard/CLAUDE.md
```

| Project | Stack | Owns |
| --- | --- | --- |
| `sev_connect_backend/` | Kotlin 2.3, Java 25, Spring Boot 4.1, Gradle, PostgreSQL, Redis | Server source of truth, REST + sync API, permissions, audit |
| `serv_connect_mobile/` | Flutter / Dart | Role-based mobile app, on-device store, outbox, local notifications |
| `serv_connect_dashboard/` | React 19, TypeScript, Vite, npm | Web/admin console for leaders and administrators (online-only, own UI — §13) |

> **Tech-stack note.** BRD §10 describes the client as Kotlin Multiplatform. The repo's real stack (Flutter) is what we build with; the BRD is authoritative for **business** requirements, not for the technology choice.

---

## 0. Pre-Task Checklist

1. Read this file, the target project's `CLAUDE.md`, and the relevant BRD module (`docs/00-brd.md §8.x`) in full.
2. Identify the `FR-x.y` IDs and phase tag (`[MVP]`, `[P2]`, `[P3]`). Build only what was asked; a `[P2]`/`[P3]` item needs an explicit request (§9).
3. Check `plans/README.md` — if a plan for this work already exists, **resume it** (§1.4) instead of starting a new one.
4. **Write the plan into `plans/` (§1) and wait for explicit approval** before writing code. No code before approval.
5. Check `docs/03-api-reference.md` and `docs/06-sync.md` before adding or consuming an endpoint or sync entity. Never define or call two endpoints that do the same thing.
6. Grep both projects for existing code that already covers the need; extend rather than duplicate.
7. State the plan and wait for approval on any destructive action (dropping/altering a table, editing a committed migration, purging data, changing auth/token logic, changing the sync protocol, editing the audit trail, force-push).

---

## 1. Plans Folder — Long-Running Work

Every feature here is a long run that spans many sessions and commits, so **the plan lives in a file, not in the chat.** The plan file is the single source of truth for what is being built, what is done, and what is next.

### 1.1 When a plan file is required
- Every feature, every BRD module or sub-module, every cross-project change (API contract, sync protocol), every refactor touching more than one package, and every task that will take more than one session.
- Not required for: a pure question, or a trivial fix the user explicitly scopes as such (it still needs a commit + walkthrough entry).

### 1.2 Naming & location
- `plans/YYYY-MM-DD_<area>_<slug>.md`, where `<area>` is `backend`, `mobile`, `dashboard`, or `cross` (touches more than one project). Example: `plans/2026-10-18_backend_foundation.md`, `plans/2026-10-20_cross_attendance-follow-up.md`.
- Start from `plans/_TEMPLATE.md` and keep all of its sections; write "N/A" rather than deleting one.
- Add a row to the index in `plans/README.md` in the same change that creates the plan.

### 1.3 Lifecycle
| Status | Meaning |
| --- | --- |
| `Draft` | Written, waiting for the user's review. No code yet. |
| `Approved` | The user approved it in chat. Record the date and the approver's words in the plan header. |
| `In progress` | Work started. The work breakdown is being ticked off. |
| `Blocked` | Waiting on a decision or another plan — reason written in the header. |
| `Done` | Every step ticked, docs updated, walkthrough linked. |
| `Abandoned` | Dropped — reason written in the header. Never delete a plan file. |

### 1.4 Working a plan
- The **work breakdown** is a numbered checklist of commit-sized steps (`- [ ] 1. …`). Each step names its files and how it is verified.
- After finishing each step: tick its box, append a dated line to the **Progress log** (what was done, commit hash, anything surprising), and commit the plan update **together with** the code.
- **Resuming** (new session, after a break, after context was summarised): read the plan file first, then continue from the first unticked step. Don't rely on chat memory.
- **Changing course:** edit the plan, explain why in the progress log, and get re-approval if scope, API contract, schema, or security design changed. Small implementation details don't need re-approval — log them.
- Open questions go in **Open decisions** and are asked to the user; never silently decide a business question.
- When done: set `Done`, link the walkthrough(s), update the index row.

---

## 2. Git Commits

- One git repo at the monorepo root. Commit after every completed, working unit (normally one plan step). Format:

  ```
  <type>(<scope>): <short description>

  <body — what & why; cite FR-x.y and the plan file>
  ```

- **No `Co-Authored-By` trailer:** never add `Co-Authored-By: Claude ...` (or any AI co-author trailer) to commit messages.
- Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `build`, `perf`, `security`.
- Scope: the project then the area — `backend/attendance`, `backend/security`, `mobile/attendance`, `mobile/sync`, `dashboard/members`, `dashboard/auth`, `docs`, `plans`, `repo` (root config). A cross-project change uses one commit per project when possible, in contract order (§5).
- **Never commit:** secrets (`.env`, `application-local.*`, FCM/Firebase service-account JSON, `google-services.json`/`GoogleService-Info.plist` with real keys, keystores, `*.jks`, `*.p12`, `*.pem`); build output (`build/`, `.gradle/`, `.dart_tool/`, `.kotlin/`); IDE files (`.idea/`, `*.iml`); failing builds or tests; commented-out code; real member data (names, photos, phone numbers) in seeds, fixtures, or tests; an already-applied migration that was edited.
- Never `--no-verify`, never `git push --force` on `main`/`develop`/`release/*`, never `git reset --hard` without explicit user instruction.

---

## 3. Walkthrough History

- After every completed feature, fix, or significant refactor: create/update `docs/walkthroughs/YYYY-MM-DD_<area>_<slug>.md` (`<area>` = `backend`, `mobile`, `dashboard`, `cross`) and add a one-line entry to `docs/walkthroughs/README.md`.
- Contents: **Date**; **Plan** (link to the `plans/` file); **Summary**; **BRD coverage** (`FR-x.y`, fully/partially); **Files changed** (per project); **API / sync contract changes**; **DB / on-device schema changes**; **Security & safeguarding impact**; **Localization** (new keys in both `en` and `ar`); **Testing**; **Config** (new env vars / settings); **Known limitations / follow-ups**. Each project's `CLAUDE.md` may add fields.

---

## 4. Shared Docs

All documentation lives in the root `docs/` — **never** create a `docs/` folder inside a project.

| File | Content | Owner |
| --- | --- | --- |
| `00-brd.md` | Business requirements (changed only when the user changes requirements) | Product |
| `01-project-overview.md` | System architecture, both projects, config, BRD coverage per module | Both |
| `02-database-schema.md` | Server schema + Flyway migration list | Backend |
| `03-api-reference.md` | REST contract — method, path, request/response, permission + scope, feature flag, `FR` | Backend (consumed by mobile + dashboard) |
| `04-security.md` | Permission catalog, roles, scopes, PII/Sensitive classes, audit rules, on-device security | Both |
| `05-localization.md` | Locales, key conventions, RTL rules | Both |
| `06-sync.md` | Offline-first sync protocol, syncable entities, conflict strategy per type | Both |
| `07-mobile-architecture.md` | Flutter app structure, on-device store, outbox | Mobile |
| `08-dashboard-architecture.md` | Dashboard structure, routing, auth flow, state, UI primitives | Dashboard |
| `README.md` | Index of all docs | Both |
| `walkthroughs/` | History (§3) | Both |

Create each file the first time a task needs it, and add it to `docs/README.md`.

---

## 5. API Contract Between Projects

- The **backend owns the contract**; `docs/03-api-reference.md` is the contract's source of truth. Neither client (mobile app, dashboard) relies on an endpoint, field, or behaviour that isn't documented there.
- Contract-change order: (1) update `docs/03` (and `docs/06` for sync) in the plan, (2) backend implements + tests, (3) mobile and/or dashboard consume. Never ship a client change against an endpoint that doesn't exist yet.
- **Old app versions stay offline for weeks.** Changes to `/api/v1` are additive only (new optional fields, new endpoints). Removing, renaming, or changing the meaning of a field is a new API version, and the old one stays supported until the plan says otherwise.
- Every response uses the backend's `BaseResponseBody` envelope; the clients parse errors from the envelope's localized message and code, never from raw text.
- Identifiers in URLs are opaque UUIDs. No name, phone, or email in a path or query string — in either project.

---

## 6. Offline-First & Sync (cross-project)

- Offline-first is mandatory (BRD §11, NFR-1/NFR-3). The app reads from its local store; the network only refreshes it. Every mutation goes into a durable **outbox** and is retried until the server confirms it.
- IDs are **UUIDs created on the device**; every mutation carries a `mutationId` so retries are idempotent.
- Conflict strategy is **per data type** (BRD §11.3) and must be identical on both sides: config/schedules/groups = server-authoritative LWW with conflict warning; **attendance = merge per (occurrence, member)**; **follow-ups & pastoral notes = append-only**; tasks = field-level merge; personal state = per-user LWW.
- Pull uses the server's monotonic change token, never device clocks. Deletes arrive as tombstones; lost access arrives as revocations and the device must drop that data.
- Any new syncable entity is documented in `docs/06-sync.md` (fields, strategy, scope) in the same change, before either side implements it.

---

## 7. Security, Safeguarding & PII (both projects)

The platform holds data about **minors**. These rules apply to the backend, mobile app, and dashboard alike:

- [ ] Authorization is enforced **server-side** by permission + scope (backend §11). Client-side hiding is UX only, never security.
- [ ] Never branch on a role name — use permissions (backend) or the permission set returned for the session (mobile, dashboard).
- [ ] No PII (name, phone, email, birthdate, photo URL) and no Sensitive data (medical, pastoral notes, consent) in logs, crash reports, analytics events, URLs, push-notification text, or JWT claims.
- [ ] Sensitive data is stored separately, fetched through its own endpoint, audited on every read, and **encrypted at rest on the device** (encrypted local DB / secure storage). Tokens live only in platform secure storage (Keystore/Keychain).
- [ ] Every Sensitive read and every write is attributable to a user (server audit trail).
- [ ] TLS only; never disable certificate validation, even for local debugging.
- [ ] Photos respect photo-consent flags; a minor can't be cleared to travel without a valid consent record.
- [ ] Secrets only through environment/config, never in source (§10).

---

## 8. Localization (AR / EN)

- Both projects support **English** and **Arabic** (RTL), and every user-facing string comes from localization resources — never hard-coded.
- Adding a string means adding it in **both** `en` and `ar` in the same change.
- The backend returns machine values (ISO-8601 UTC instants, `LocalDate`s, numbers); the app formats dates, numbers, and calendars for the user's locale.
- Religious/liturgical content is **data** (content packs, BRD §8.9), never a localization string and never hard-coded.

---

## 9. BRD & Phase Discipline

- Code names follow the BRD glossary (`Servant`, `ServedMember`, `Stage`, `Group`, `EventOccurrence`, `AttendanceRecord`, `FollowUp`, `ContentPack`, …) in both projects. UI labels are configurable per church; code names are not.
- Phases ship in order: **MVP → P2 → P3** (BRD §13). MVP is the daily loop: **schedule → attend → follow up → assign tasks**, plus essential content, all offline-first.
- BRD §4.2 out-of-scope items are not built: public website, accounting/payment processing, live streaming, servant web client.
- If a request contradicts the BRD, flag it before planning.

---

## 10. Secrets & Environments

- Secrets and per-environment values come from environment variables / untracked config files only. Each project keeps an example file (`.env.example`, etc.) listing every key with no real values.
- Apps refuse to start on a missing required secret — never fall back to empty strings or hard-coded defaults.
- Environments: **dev / staging / prod**, each with its own database, Firebase project, and credentials. Nothing that protects staging/prod data appears in a dev file.

---

## 11. Project Boundaries

- A project never imports or reads source files from another project. They talk only through the documented API (§5).
- A task scoped to one project doesn't edit the other project's files. If it needs a change there, it becomes a `cross` plan or a follow-up written in the plan.
- Repo-root files (`CLAUDE.md`, `.gitignore`, `docs/`, `plans/`) are shared — keep changes to them minimal and explain them in the commit.

---

## 12. Post-Task Documentation Updates

**Every task ends with a docs + plan update** — "code works" / "tests pass" ≠ "done".

1. **Plan (`plans/…`):** step ticked, progress log updated, status current, index row current.
2. **API / sync (`docs/03`, `docs/06`):** any endpoint, DTO, or sync payload added/changed.
3. **Schema (`docs/02`):** any migration.
4. **Security (`docs/04`):** any permission, scope, PII/Sensitive field, audit rule, or on-device storage change.
5. **Localization (`docs/05`):** new conventions or locales.
6. **Overview (`docs/01`):** new module, integration, config, or BRD coverage change.
7. **Walkthrough (`docs/walkthroughs/`)** + its README (§3).
8. **Index (`docs/README.md`):** new/renamed doc.

Verify before commit (from the repo root):

```bash
git status -- docs/ plans/   # expect changes matching the task
git diff -- docs/ plans/
```

If `git status -- docs/ plans/` shows no changes after a code change, stop and ask whether a docs update was really not needed (default: it was).

---

## 13. Designs

- All designs live in the root `designs/` folder as **SVG or HTML**: `designs/mobile/` for the Flutter app, `designs/dashboard/` for the web/admin dashboard, each split into `en/` (LTR) and `ar/` (RTL). Shared tokens/components go in `designs/design-system.html` when provided. Naming rules: `designs/README.md`.
- Any UI task reads the matching design in **both** `en/` and `ar/` before planning, and the plan's Design section names the design files it implements.
- The built UI must match the design in layout, flow, and states (loading, empty, error, offline) in both languages; differences are logged in the plan as deliberate decisions or as gaps to fix.
- If a screen the task needs has no design, say so in the plan's Open decisions — don't invent one silently.
- Designs are reference input only: code never imports from `designs/`; needed assets are copied into the app project. No real member data in designs.
- The dashboard is a **web/admin console**, which the BRD places in Phase 2/3 (BRD §4.2, FR-16.6). Build dashboard screens only when a plan for them is approved.

---

## Quick Reference — Mandatory Actions Per Task

All task types need: **Plan file & approval**, **Commit**, **Walkthrough**, **Docs + plan update**. The table covers the conditional extras.

| Task | FR IDs | API contract (`docs/03`) | Sync (`docs/06`) | Security review (§7) | i18n (en + ar) | Tests | Both projects? |
| --- | --- | --- | --- | --- | --- | --- | --- |
| New feature / module | ✅ | if endpoints | if cached offline | ✅ | if strings | ✅ | usually `cross` plan |
| New endpoint / DTO | ✅ | ✅ | if synced | if PII-adjacent | if messages | ✅ | backend first, then mobile / dashboard |
| New syncable entity | ✅ | ✅ | ✅ | ✅ | — | ✅ conflict tests | ✅ |
| Permission / scope change | ✅ | ✅ | ✅ feed filtering | ✅ | — | ✅ 403 tests | if UI gating changes |
| Bug fix | if related | if API | if sync | if security | if strings | regression | if contract |
| Refactor | — | if API surface | if affected | if security | — | still green | rarely |
| New config / secret | — | — | — | ✅ | — | — | per project |
