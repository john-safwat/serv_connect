# Plans

Every feature in ServeConnect is a long run, so each one gets a **living plan file** here. The plan is the source of truth for scope, decisions, progress, and what comes next — read it first when resuming work. Rules: root `CLAUDE.md §1`.

## How to start a plan

1. Copy `_TEMPLATE.md` to `YYYY-MM-DD_<area>_<slug>.md` (`<area>` = `backend`, `mobile`, `dashboard`, or `cross`).
2. Fill in every section (write "N/A" rather than deleting one). Status: `Draft`.
3. Add a row to the index below.
4. Get the user's approval in chat, then set the status to `Approved` and record it in the header.

## How to work a plan

- Tick each work-breakdown step when it's done, add a dated line to the **Progress log** (with the commit hash), and commit the plan update together with the code.
- When resuming, continue from the first unticked step.
- Scope, contract, schema, or security changes → update the plan and get re-approval.
- Never delete a plan. Finished → `Done`; dropped → `Abandoned` with the reason.

## Index

| Plan | Area | BRD | Phase | Status | Last updated |
| --- | --- | --- | --- | --- | --- |
| _none yet_ | | | | | |
