# <Feature name> — Plan

| Field | Value |
| --- | --- |
| Status | Draft · Approved · In progress · Blocked · Done · Abandoned |
| Area | backend · mobile · dashboard · cross |
| BRD | §8.x — `FR-x.y`, `FR-x.y` |
| Phase | MVP · P2 · P3 |
| Created | YYYY-MM-DD |
| Approved | YYYY-MM-DD — "<the user's approval words>" |
| Depends on | <other plan files, or none> |
| Walkthrough(s) | <links when done> |
| Blocked / abandoned reason | <only when applicable> |

---

## 1. Goal

<One paragraph: what this delivers and why, in business terms from the BRD.>

## 2. Scope & Decisions

| # | Decision | Choice |
| --- | --- | --- |
| 1 | | |

### 2.1 Non-goals

- <What this plan deliberately doesn't do (e.g. P2 parts of the module).>

## 3. Current State

<What already exists that this builds on — files, endpoints, tables. What's missing.>

## 4. Design

### 4.1 Backend

- Packages / classes: <`features/<x>/…` — created or modified>
- Entities & migrations: <tables, columns, indexes, `V<n>__…sql`>
- Endpoints: <method + path + permission + scope + feature flag>
- Business rules: <validation, invariants, idempotency>

### 4.2 Mobile

- Screens / state / widgets: <files>
- On-device storage: <tables, encryption>
- Outbox / offline behaviour: <what works offline, what queues>

### 4.3 Dashboard

- Routes / pages / components / hooks: <`src/features/<x>/…` files>
- Design files implemented: <`designs/dashboard/{en,ar}/…`>
- Permission gating: <permissions that show/enable each action>
- States: <loading, empty, error, 403, offline>

### 4.4 API contract changes (`docs/03-api-reference.md`)

<Request/response shapes. Additive only for `/api/v1`.>

### 4.5 Sync (`docs/06-sync.md`)

| Entity | Syncable? | Conflict strategy | Scope filter |
| --- | --- | --- | --- |
| | | | |

## 5. Security & Safeguarding

- Permissions added/used and their default roles:
- Data classification of new fields (PII / Sensitive / Operational):
- Audited reads/writes:
- On-device storage of sensitive data:

## 6. Localization

- New keys (en + ar):
- RTL considerations:

## 7. Testing

- Backend: <unit, `@WebMvcTest`, integration — incl. 403 out-of-scope + 400 invalid input>
- Mobile: <unit, widget, offline/sync tests>
- Dashboard: <Vitest unit, component/hook tests with MSW, Playwright e2e in en + ar>
- Conflict / idempotency tests:

## 8. Docs to Update

- [ ] `docs/01-project-overview.md`
- [ ] `docs/02-database-schema.md`
- [ ] `docs/03-api-reference.md`
- [ ] `docs/04-security.md`
- [ ] `docs/05-localization.md`
- [ ] `docs/06-sync.md`
- [ ] `docs/07-mobile-architecture.md` / `docs/08-dashboard-architecture.md`
- [ ] Walkthrough + `docs/walkthroughs/README.md`

## 9. Work Breakdown

Commit-sized steps, in order. Each step lists its files and how it's verified.

- [ ] 1. <step> — files: <…> — verify: <…>
- [ ] 2.
- [ ] 3.

## 10. Acceptance Criteria

- [ ] <From the BRD's AC for these FRs, plus any agreed additions.>

## 11. Open Decisions

| # | Question | Options | Answer (date) |
| --- | --- | --- | --- |
| 1 | | | |

## 12. Risks & Mitigations

| Risk | Mitigation |
| --- | --- |
| | |

## 13. Progress Log

- YYYY-MM-DD — Plan drafted.
