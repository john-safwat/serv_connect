# MANDATORY — Feature Development Workflow (Agent Orchestration)

> This rule is binding on EVERY prompt. It governs how any new feature, change
> request, enhancement, or "can we add / build / support X" is handled. Every agent
> and every step below must also obey the root `CLAUDE.md` and the CLAUDE.md of each
> project it touches (`sev_connect_backend/CLAUDE.md`, `serv_connect_mobile/CLAUDE.md`,
> `serv_connect_dashboard/CLAUDE.md`) in full. This workflow never overrides CLAUDE.md —
> it sits on top of it.

## When this applies
Any request to add or change a feature/flow in ServeConnect (API `sev_connect_backend`,
mobile `serv_connect_mobile`, web dashboard `serv_connect_dashboard`, or infra). It does NOT
apply to a pure question, a one-line explanation, or a trivial typo fix the user explicitly
scopes as such — but when in doubt, follow the pipeline.

## Entry point — the orchestrator
Work starts with **`/orchestrate <request>`** (or a session started with
`claude --agent orchestrator`). The **orchestrator** (`.claude/agents/orchestrator.md`)
runs as the main thread, talks with the user, and launches every other agent. Sub-agents
can't talk to the user or spawn agents, so all coordination and user dialogue goes
through the orchestrator. If a feature request arrives without `/orchestrate`, the main
thread acts as the orchestrator anyway. If a plan for the work already exists in `plans/`,
the orchestrator resumes it (root `CLAUDE.md §1.4`) instead of starting over.

## The pipeline (do the steps in order — do NOT skip or reorder)

**1. Business discussion loop → `business-development` agent (discussion mode).**
The orchestrator launches `business-development`, relays each *Discussion Round* to the user,
and sends the user's answers back to the same agent. This **repeats until the user
explicitly says they're satisfied** ("satisfied", "start implementing", "approved",
"موافق", "تمام ابدأ"…). Then the agent issues the **Agreed Feature Brief**. Nothing is
planned or built before that.

**2. Planning → `business-analyst-planner` agent.**
Takes the Agreed Feature Brief and writes the plan file `plans/YYYY-MM-DD_<area>_<slug>.md`
from `plans/_TEMPLATE.md` (`<area>` = `backend`, `mobile`, `dashboard`, or `cross`): FR-x.y
IDs + phase, every endpoint/DTO/entity/Flyway migration/permission/sync rule, every Flutter
screen and every dashboard route/page/component, ar/en keys, tests, docs, commit-sized work
breakdown, acceptance criteria. It self-reviews the plan and adds the index row in
`plans/README.md`. The orchestrator shares it with the user, records the approval in the
plan header, and derives work packages with file ownership.

**3. Build → developer agents, in parallel waves.**
- Wave A: `backend-developer` (API contracts the clients need), plus `devops-engineer` if
  needed and its files don't overlap.
- Wave B: `flutter-developer` (`serv_connect_mobile`) and `web-developer`
  (`serv_connect_dashboard`) **in parallel** against the delivered contract. Client work that
  needs no new endpoint (UI, design system, local storage) may run alongside Wave A.
- Packages run in parallel only when their file sets don't overlap. Otherwise they run
  one after the other. Each developer agent follows CLAUDE.md, writes its own tests + docs,
  and ticks its plan steps.

**4. QA → QA + design-parity agents, in parallel.**
`qa-backend`, `qa-mobile`, `qa-web`, and `design-parity-verifier` (for any UI change) run
together — only the ones whose project changed. Each client is checked against **its own**
design set (mobile → Mobile designs, dashboard → Dashboard designs). Defects and design gaps
loop back to the owning developer (step 3, those items only), then the failing QA re-runs,
until all pass.

**5. Security → `security-auditor` agent.**
Critical/High findings loop back to step 3 → step 4 before continuing. Any change touching
minors' data, Sensitive fields, permissions, or the sync feed must also satisfy backend
CLAUDE.md §22 and root `CLAUDE.md §7`.

**6. User confirmation gate.**
The orchestrator reports the work, QA, and security results and **waits for explicit
approval**. No commit before this.

**7. Commit → `git-expert` agent.**
Only after step 6 approval, using the root `CLAUDE.md §2` format, one commit per plan step or
project where possible, plan file updated in the same commit. No other agent commits.

## Hard rules
- No step is skipped and no order is changed without the user explicitly asking.
- Step 1 ends only on the user's explicit satisfaction, never on the agent's judgement.
- Only `git-expert` commits, and only after step 6's user confirmation.
- Build only the BRD phase the user asked for (`[MVP]` by default); `[P2]`/`[P3]` only on
  explicit request (root `CLAUDE.md §9`).
- A client never ships against an endpoint that isn't in `docs/03-api-reference.md` and
  implemented (root `CLAUDE.md §5`).
- Every agent obeys CLAUDE.md; a conflict between this file and CLAUDE.md is resolved in
  favor of CLAUDE.md's safety/safeguarding/security rules.
- If the user starts mid-pipeline (e.g. "just build this plan"), resume from the matching
  step but still finish with QA → security → confirmation → git-expert.
