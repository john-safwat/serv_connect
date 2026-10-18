# Documentation Discipline

**A task is not done when the code compiles — it's done when `docs/` matches reality.** Any change
that alters behavior and doesn't touch the matching docs is incomplete.

## The `docs/` skeleton

```
docs/
├── README.md                 # index linking every doc under its section
├── 01-project-overview.md    # architecture baseline, package layout, cross-cutting infra, config profiles
├── 02-database-schema.md     # tables, columns, key patterns (e.g. @MapsId shared PK), migration notes
├── 03-api-reference.md       # every endpoint: method, path, request/response shape, status codes, required role
├── 04-security.md            # auth, authorization rules, @PreAuthorize, PHI handling, logging/audit policy
├── 05-localization.md        # supported locales, resolution, message/validation localization, domain-data translation
└── walkthroughs/
    ├── README.md             # chronological index, one line per walkthrough
    └── YYYY-MM-DD_<slug>.md   # one file per completed feature/fix/refactor
```

Create these on first use; add new `docs/*.md` files to `docs/README.md`.

## What to update, always

- **New/changed/removed endpoint** → `03-api-reference.md` (method, path, request/response, status,
  role). Check this file *before* adding an endpoint so you don't create a duplicate.
- **New Flyway migration** → `02-database-schema.md` (table/column, migration filename, backward-compat).
- **New role / permission / `@PreAuthorize` rule / PHI-adjacent field** → `04-security.md`.
- **New feature package / external integration / config profile** → `01-project-overview.md`.
- **New user-facing message, validation text, locale, or email** → `05-localization.md`.
- **New config key / env var / secret** → `01-project-overview.md` config section + `.env.example`.

## Walkthroughs (per non-trivial task)

Create `docs/walkthroughs/YYYY-MM-DD_<short-slug>.md` and add a one-line entry to
`docs/walkthroughs/README.md`. Each walkthrough contains:

- **Date** and a one-paragraph **Summary** (what changed and why).
- **Files changed** — every class created/modified, grouped by package.
- **API changes** — endpoints added/removed/altered, and whether `03-api-reference.md` was updated.
- **Schema changes** — new migration file(s), what they do, backward-compatibility.
- **Security impact** — new roles/permissions, new PHI-adjacent fields, changed authorization.
- **Configuration** — new `application*.properties` keys / env vars.
- **Known limitations / follow-ups** — anything deferred.

## Cross-cutting reminders

- If a change makes a documented rule newly true/false or gains an exception, update the rule where
  it's documented rather than letting it drift.
- If a change closes a previously-documented gap/limitation, remove that note.
- Drive-by doc fixes are encouraged: fix any code/doc inconsistency you notice as part of the current
  change.

## Verification before commit

```bash
git status docs/   # expect changes matching the task
git diff docs/     # quick review of the doc edits
```

If `git status docs/` shows nothing for a task that changed code or the API surface, stop and ask
whether the task really didn't need a docs update — the default assumption is that it did.

## Commit conventions

`<type>(<scope>): <short description>` where type ∈ `feat|fix|refactor|docs|chore|build|perf|security`
and scope is the feature/infra area (`auth`, `patient`, `db`, `security`, `config`, `ci`, …). Commit
after every completed, working unit once `./mvnw clean verify` passes. Never commit secrets, `target/`,
commented-out code, an edit to an already-applied migration, or a failing build.
