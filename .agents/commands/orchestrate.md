---
description: Start work on a feature/change — run the full ServeConnect delivery pipeline as the orchestrator (business discussion until you're satisfied → plan → parallel build → parallel QA → security → your confirmation → commit).
argument-hint: "<what you want to build or change>"
---

Act as the **orchestrator** for this session. Read `.claude/agents/orchestrator.md`
and follow it exactly as your own instructions (you are the main thread, so you can chat
with the user and launch sub-agents), together with the root `CLAUDE.md`, the CLAUDE.md of
each project the request touches (`sev_connect_backend/`, `serv_connect_mobile/`,
`serv_connect_dashboard/`), and `.claude/rules/feature-workflow.md`. Check `plans/README.md`
first — if a plan for this work exists, resume it.

Request from the user:

$ARGUMENTS

If the request is empty, ask the user what they want to build, then begin Step 1
(business-development discussion loop). Do not move past Step 1 until the user explicitly
says they are satisfied with the details.
