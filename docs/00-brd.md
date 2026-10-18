# Business Requirements Document (BRD)
## Church Service & Community Management Platform
### Working title: *ServeConnect* (placeholder)

| Field | Value |
|---|---|
| Document type | Business Requirements Document |
| Version | 0.1 (Draft for review) |
| Date | 2026-07-09 |
| Author | Solution Architecture / Business Analysis |
| Status | Draft — pending stakeholder review |
| Platform | Mobile app (Kotlin Multiplatform) + backend (Spring Boot) |
| Architecture posture | **Offline-first**, single **role-based** application, denomination-neutral / configurable content |

> **Reading note.** This BRD documents the **full product vision** and organizes every feature into delivery phases (**MVP → Phase 2 → Phase 3**). Each functional requirement is tagged with a phase so the team can build incrementally. The content/liturgical layer is intentionally kept **generic and configurable** so the platform can serve any church tradition; tradition-specific packs (readings, prayers, calendar, hymns) are treated as data/configuration, not hard-coded features.

---

## 1. Executive Summary

The platform is a mobile-first system that strengthens the connection between **servants** (volunteers, mentors, teachers, leaders) and the **served** (members, children, youth, and their families), and gives servants the tools to organize their own work. It replaces fragmented, paper- and chat-based coordination (attendance sheets, WhatsApp groups, printed schedules, memory) with a single, structured, offline-capable system.

Three problems drive the product:

1. **Coordination gap between servants** — schedules, task assignments, meeting logistics, and lesson preparation live in scattered chats and paper. There is no single source of truth.
2. **Continuity gap for the served** — when a member moves between groups or a servant changes, history and context are lost. No one remembers who needs follow-up.
3. **Connectivity gap** — poor/intermittent internet means any online-only tool fails exactly when it is needed (during meetings, on trips). The system must work **offline-first**.

The solution is a single role-based application on a Kotlin Multiplatform (KMP) client with a Spring Boot backend, designed so that the most important workflows — attendance, follow-up, schedules, lessons, content, and reminders — function fully without a live connection and sync automatically when connectivity returns.

---

## 2. Background & Problem Statement

Church service teams typically coordinate through informal channels. This works at small scale but breaks down as the number of servants, groups, and served members grows:

- Attendance and follow-up ("who was absent and needs contacting?") are tracked on paper or not at all, so at-risk members slip through the cracks.
- Schedules (group meetings, choir practice, training, Sunday sessions) change often, and updates don't reliably reach everyone.
- Task distribution among servants is verbal and untracked, so accountability is weak.
- Records of the served are held in individual servants' heads; institutional memory evaporates when people rotate.
- Curriculum and lesson preparation are duplicated effort across servants.
- Internet is unreliable, so cloud-only tools are unusable at the critical moment.

The platform addresses these by combining **operational tooling for servants** (tasks, schedules, attendance, lessons) with a **shared, durable record** of the served, wrapped in an **offline-first** architecture.

---

## 3. Goals, Objectives & Success Metrics

### 3.1 Business goals
- **G1** — Improve communication and coordination between servants.
- **G2** — Ensure continuity of care for each served member across group and servant changes.
- **G3** — Reduce the number of members who "fall away" unnoticed via systematic follow-up.
- **G4** — Reduce servant administrative overhead (scheduling, lesson prep, record-keeping).
- **G5** — Make the whole system usable under poor/no connectivity.

### 3.2 Measurable objectives (success metrics)
| Metric | Baseline | Target (12 months) |
|---|---|---|
| % of meetings with attendance recorded in-app | ~0% | ≥ 85% |
| Median time to follow up on an absentee | Unknown/days | ≤ 48 hours |
| % of active servants using the app weekly | 0% | ≥ 70% |
| % of served members with a complete, current record | Low | ≥ 90% |
| Schedule changes reaching all relevant users within 1 hour | Unreliable | ≥ 95% |
| Core workflows usable fully offline | 0% | 100% of MVP core |

*(Baselines to be confirmed during discovery.)*

---

## 4. Scope

### 4.1 In scope
- Single mobile application (Android + iOS via KMP) with a **role-based** experience.
- Spring Boot backend, REST/JSON APIs, push notifications, admin configuration.
- Offline-first local storage and background sync.
- Feature modules listed in Section 8 (Functional Requirements).
- A configurable, denomination-neutral content layer (readings, prayers, calendar, hymns, curriculum).

### 4.2 Out of scope (initially)
- Public-facing website / marketing site.
- Financial accounting / full donation-processing platform (a lightweight tithing/offering log may appear in Phase 3; payment *rails* are out of scope).
- Live streaming / video conferencing (deep-link to third-party tools instead).
- Multi-diocese / multi-tenant SaaS operation (single-church deployment first; multi-tenancy is a Phase 3 architectural option).
- Web client for servants (mobile-first; a read-only web/admin console is a Phase 2/3 candidate).

### 4.3 Assumptions
- Users have smartphones (Android-majority likely) with intermittent connectivity.
- The organization can nominate an administrator and provide the initial roles/groups data.
- Content (curriculum, hymns, readings) can be provided or licensed for inclusion.
- One church/organization per deployment for v1.

### 4.4 Constraints
- Poor/unreliable internet → offline-first is mandatory, not optional.
- Volunteer-run: low budget, small dev/ops team → favor a single codebase and low maintenance surface.
- Sensitive data about **minors** → strict privacy, access control, and safeguarding obligations.

### 4.5 Dependencies
- Push notification service (e.g., Firebase Cloud Messaging).
- App store accounts (Google Play, Apple App Store).
- Content licensing/approval for included religious materials.

---

## 5. Stakeholders & Personas

| Persona | Role in system | Primary needs |
|---|---|---|
| **Service Leader** (ministry lead) | Oversees the whole service | Full visibility, schedules, servant assignment, curriculum approval, reports |
| **Stage/Grade Head** | Leads one stage (e.g., a grade) | Manage their stage's groups, servants, and served; attendance overview |
| **Servant** (volunteer/teacher/mentor) | Works directly with served members | Attendance, follow-up, lesson prep/delivery, tasks, schedule, communication |
| **Clergy / Spiritual overseer** | Pastoral oversight | Sensitive records, high-level engagement view, prayer requests |
| **Parent / Guardian** | Family of a served minor | Their children's schedule, notifications, permission forms |
| **Served member** | Recipient of the service | Their schedule, verses, hymns, content, points/achievements |
| **Administrator / IT** | System operator | User provisioning, roles, configuration, content management, audit |

**Anti-personas / boundary cases:** very young children (their *parent* is the real user); occasional visitors (lightweight guest records without full profiles).

---

## 6. Roles & Permissions (RBAC)

The application is a **single app** whose experience adapts to the signed-in user's role(s). A user may hold **multiple roles** (e.g., a Servant who is also a Parent). Access is enforced at **field level**, not only screen level, because of sensitive minor data.

### 6.1 Role hierarchy (illustrative)
```
Administrator
   └── Service Leader
         └── Stage/Grade Head
               └── Servant
Clergy (cross-cutting oversight)
Parent/Guardian (scoped to own children)
Served member (scoped to self)
```

### 6.2 Permission matrix (representative, not exhaustive)

| Capability | Admin | Service Leader | Stage Head | Servant | Clergy | Parent | Served |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| Manage users & roles | ✅ | ⬤ | — | — | — | — | — |
| Configure content packs | ✅ | ⬤ | — | — | — | — | — |
| Create/edit groups | ✅ | ✅ | ⬤ | — | — | — | — |
| Assign servants to groups | ✅ | ✅ | ✅ | — | — | — | — |
| Publish schedules/events | ✅ | ✅ | ✅ | ⬤ | — | — | — |
| View schedules | ✅ | ✅ | ✅ | ✅ | ✅ | ✅(own) | ✅(own) |
| Record attendance | — | ✅ | ✅ | ✅ | — | — | — |
| View served full record | ✅ | ✅ | ✅(stage) | ✅(own group) | ✅ | — | — |
| View/add private follow-up notes | — | ⬤ | ⬤ | ✅(own group) | ✅ | — | — |
| Create/assign tasks | ✅ | ✅ | ✅ | ✅ | — | — | — |
| Prepare/submit lessons | — | ✅ | ✅ | ✅ | — | — | — |
| Approve lessons | ✅ | ✅ | ⬤ | — | — | — | — |
| Manage trips/events logistics | ✅ | ✅ | ✅ | ⬤ | — | — | — |
| Sign permission forms | — | — | — | — | — | ✅ | — |
| View content (verses/hymns/readings) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| View analytics/reports | ✅ | ✅ | ✅(stage) | ✅(own) | ✅ | — | — |
| Access audit log | ✅ | ⬤ | — | — | — | — | — |

Legend: ✅ = allowed · ⬤ = allowed, configurable/conditional · — = not allowed · "own"/"stage" = scoped.

> **Design principle:** every read of a minor's record is **authorized by scope** (my group / my stage) and **logged** (Section 8.13). Roles and scopes are data-driven so an organization can tune them without a code change.

---

## 7. Feature Module Map

| # | Module | One-line purpose | Earliest phase |
|---|---|---|---|
| 8.1 | Authentication, Onboarding & Identity | Secure sign-in, roles, offline session | MVP |
| 8.2 | Member Directory & Records | Durable, portable records of servants & served | MVP |
| 8.3 | Groups & Assignments | Organize members into groups; assign responsible servants | MVP |
| 8.4 | Scheduling & Events | Recurring meetings/practices/training, one source of truth | MVP |
| 8.5 | Attendance & Follow-up | Record presence; flag & follow up absentees | MVP |
| 8.6 | Task Management | Distribute & track servant tasks (Kanban/Jira-style) | MVP |
| 8.7 | Communication & Collaboration | Contextual messaging, announcements | MVP→P2 |
| 8.8 | Curriculum & Lesson Management | Prepare, review, deliver lessons | P2 |
| 8.9 | Content Library | Bible reading/tracking, daily verse, hymns, prayers, calendar | MVP→P2 |
| 8.10 | Memorization & Points | Track memorization; gamified achievements | P2 |
| 8.11 | Trips, Conferences & Logistics | Registration, consent, payments, rooming | P2 |
| 8.12 | Notifications & Reminders | Timely, offline-capable reminders | MVP |
| 8.13 | Safeguarding, Privacy & Audit | Protect minors' data; access logging | MVP→P2 |
| 8.14 | Analytics & Reporting | Engagement & attendance insight for leaders | P2→P3 |
| 8.15 | Prayer & Praise Board | Shared prayer requests / praise reports | P2 |
| 8.16 | Administration & Configuration | Tenant config, content packs, role setup | MVP |

---

## 8. Functional Requirements

> Each requirement carries an ID (`FR-x.y`) and a **phase tag**: **[MVP]**, **[P2]**, **[P3]**. User stories use the form *"As a &lt;role&gt;, I want &lt;capability&gt; so that &lt;value&gt;."* Acceptance criteria (AC) are given for high-value features.

### 8.1 Authentication, Onboarding & Identity

**Purpose:** Let the right people in, with the right role, and keep them signed in through connectivity gaps.

- **FR-1.1 [MVP]** Sign in with phone number or email + password; OTP verification for phone.
- **FR-1.2 [MVP]** Role assignment per user; a user may hold multiple roles/scopes.
- **FR-1.3 [MVP]** **Offline session grace window** — an authenticated user retains access to cached data for a configurable period (e.g., 14–30 days) without re-authenticating, so lost signal never locks a servant out mid-meeting.
- **FR-1.4 [MVP]** Admin-driven invitation/provisioning (invite link or code); self-registration is off by default and, where enabled, requires approval.
- **FR-1.5 [P2]** Social/third-party sign-in (optional), account recovery, and multi-device session management.
- **FR-1.6 [P2]** Parent–child account linking (a parent account manages one or more minor profiles).

**AC (FR-1.3):** Given a signed-in user who goes offline, when they reopen the app within the grace window, then they reach their role's home screen and all cached data with no login prompt; when the window expires offline, then the app allows read-only access to already-cached content but blocks new sensitive reads until re-auth.

### 8.2 Member Directory & Records

**Purpose:** A single, durable, portable record for every person — the antidote to "history lives in a servant's head."

- **FR-2.1 [MVP]** Create/edit **served member** profiles: name, photo, birthdate, contact, guardian(s), current group/stage.
- **FR-2.2 [MVP]** Create/edit **servant** profiles: contact, roles, assigned groups, skills/availability.
- **FR-2.3 [MVP]** **Family linking** — connect siblings and parents/guardians; view a family at a glance across stages.
- **FR-2.4 [MVP]** **Record portability** — when a member moves group/stage or a servant changes, the full history (attendance, notes, milestones) travels with the member; nothing is lost.
- **FR-2.5 [P2]** **Private follow-up notes** (spiritual/pastoral) with strict scope + audit; separated from general profile data.
- **FR-2.6 [P2]** Talents/gifts & interests (e.g., sings, memorizes well, leadership) to identify future servants.
- **FR-2.7 [P2]** Important dates & milestones (e.g., sacraments, name day, join date) with reminders.
- **FR-2.8 [P3]** Guest/visitor light records that can be promoted to full members.

**AC (FR-2.4):** Given a member is reassigned from Group A to Group B, when the new servant opens the member's record, then attendance history, notes (subject to scope), milestones, and family links are all present and attributed to the correct prior context; the previous servant loses write access per scope rules but the record itself is unchanged.

### 8.3 Groups & Assignments

**Purpose:** Model the real structure (stages, grades, choirs, teams) and who is responsible for whom.

- **FR-3.1 [MVP]** Create groups with type (stage/grade, choir, ministry team, etc.), stage, and metadata.
- **FR-3.2 [MVP]** Assign one or more **responsible servants** to a group, with a designated lead.
- **FR-3.3 [MVP]** Add/remove served members to/from groups; support bulk actions.
- **FR-3.4 [MVP]** **Annual promotion/graduation flow** — advance a whole group to the next stage at term/year boundaries while preserving history.
- **FR-3.5 [P2]** Sub-groups and cross-groups (e.g., a child in "6th grade" *and* "choir").
- **FR-3.6 [P2]** Capacity, ratios, and safeguarding rules (e.g., minimum servant-to-child ratio warnings).

**AC (FR-3.4):** Given end-of-year promotion is triggered for Stage N, when the admin confirms, then all members advance to Stage N+1 (or graduate out), their records retain the full Stage N history, and newly-formed groups get their assigned servants — all as a single, reversible, audited operation.

### 8.4 Scheduling & Events

**Purpose:** One authoritative, shared schedule. When the right person updates a time, it appears for everyone it concerns.

- **FR-4.1 [MVP]** Create **recurring** events (e.g., 6th-grade meeting every Friday, choir practice every Wednesday, Sunday session) with day/time, location, group, and responsible servants.
- **FR-4.2 [MVP]** Edit a single occurrence or the whole series; changes **propagate** to all relevant users.
- **FR-4.3 [MVP]** Personalized schedule view — each user sees only the events relevant to their role, groups, and children.
- **FR-4.4 [MVP]** Conflict detection (a servant double-booked across two groups) with warnings.
- **FR-4.5 [P2]** RSVP / availability collection for servants (who can attend/cover).
- **FR-4.6 [P2]** Calendar export/subscribe (ICS) and device-calendar integration.
- **FR-4.7 [P2]** Room/resource booking to avoid clashes on shared spaces.

**AC (FR-4.2):** Given the stage head reschedules the Friday meeting to a new time, when the change is saved (online or offline), then it is queued and, upon sync, all assigned servants, affected served members, and their parents see the updated time and receive a change notification; offline recipients see the update on next sync with the reminder recalculated.

### 8.5 Attendance & Follow-up

**Purpose:** The operational heart of the product — know who came, who didn't, and make sure absentees are contacted.

- **FR-5.1 [MVP]** Take attendance per event occurrence (present/absent/excused), fully **offline**.
- **FR-5.2 [MVP]** Auto-generate a **follow-up list** of absentees; assign a servant to contact each.
- **FR-5.3 [MVP]** Log follow-up outcome (called/visited/messaged, reason, next step) against the member's record.
- **FR-5.4 [MVP]** **Absence alerts** — notify the responsible servant when a member is absent (e.g., "X missed the last meeting" / "not seen in 3 sessions").
- **FR-5.5 [P2]** Attendance streaks, trends, and at-risk flags per member and per group.
- **FR-5.6 [P2]** Self/parent check-in (QR or code) as an optional attendance source.
- **FR-5.7 [P2]** Configurable follow-up policies (thresholds, escalation to stage head).

**AC (FR-5.1 / 5.4):** Given a servant records attendance offline during a meeting, when they later regain connectivity, then attendance syncs without data loss, absentees are computed, follow-up tasks are created, and absence notifications fire; two servants marking the same session **merge** rather than overwrite (Section 11 conflict rules).

### 8.6 Task Management

**Purpose:** Distribute and track servant work with the clarity of a lightweight Jira/Kanban.

- **FR-6.1 [MVP]** Create tasks with title, description, assignee(s), due date, priority, and type (follow-up, lesson prep, logistics, general).
- **FR-6.2 [MVP]** Board/list views with statuses (To Do / In Progress / Done) and personal "My Tasks."
- **FR-6.3 [MVP]** Auto-created tasks from other modules (e.g., absentee follow-up → task).
- **FR-6.4 [P2]** Comments, attachments, checklists, and @mentions on tasks.
- **FR-6.5 [P2]** Recurring tasks and task templates (e.g., weekly prep checklist).
- **FR-6.6 [P2]** Boards per group/stage with filters, labels, and due-soon/overdue views.
- **FR-6.7 [P3]** Workload view (tasks per servant) to balance assignment.

**AC (FR-6.1):** Given a servant creates and assigns a task offline, when sync completes, then the assignee sees it in "My Tasks," receives a notification, and status changes made by either party reconcile deterministically.

### 8.7 Communication & Collaboration

**Purpose:** Reduce reliance on scattered external chats by keeping conversation attached to context (a group, event, task, or member).

- **FR-7.1 [MVP]** Broadcast **announcements** to a group/stage/whole service (read receipts optional).
- **FR-7.2 [P2]** **Contextual threads** on events, tasks, and lessons (comment where the work is).
- **FR-7.3 [P2]** Direct and small-group messaging between servants.
- **FR-7.4 [P2]** Deep-link to external tools (video call, maps) rather than rebuilding them.
- **FR-7.5 [P3]** Message translation / multilingual support for mixed-language teams.

### 8.8 Curriculum & Lesson Management

**Purpose:** Help servants prepare and deliver lessons, and reduce duplicated effort with a shared, reusable library.

- **FR-8.1 [P2]** Curriculum structure: terms → units → lessons per stage, with objectives.
- **FR-8.2 [P2]** Lesson content: text, images, attachments, references, activities; downloadable for offline delivery.
- **FR-8.3 [P2]** **Prepare → submit → review/approve → deliver** workflow; a head can review a servant's plan before delivery.
- **FR-8.4 [P2]** Reusable lesson library with search, tags, and versioning.
- **FR-8.5 [P2]** "Deliver mode" — a clean, distraction-free view for teaching, works offline.
- **FR-8.6 [P3]** Post-lesson feedback and per-lesson attendance/engagement capture.

**AC (FR-8.3):** Given a servant submits a lesson plan for approval, when the reviewer approves or requests changes, then the servant is notified, the status is tracked, and only approved lessons are marked "ready to deliver"; the whole cycle works with queued actions if either party is offline.

### 8.9 Content Library (denomination-neutral, configurable)

**Purpose:** Deliver spiritual/reading content. All tradition-specific material is **data/configuration** (content packs), not hard-coded, so the platform serves any church.

- **FR-9.1 [MVP]** **Bible reading & tracking** — read plans, mark progress, streaks, resume where you left off; fully offline once downloaded.
- **FR-9.2 [MVP]** **Daily verse** — a rotating/random verse surfaced daily (widget + notification), works offline from a cached pool.
- **FR-9.3 [MVP→P2]** **Hymns/chants library** — searchable text, optional audio, offline download, favorites, and set-lists for services.
- **FR-9.4 [P2]** **Daily readings / lectionary** — configurable per content pack (a church loads its own reading plan/calendar).
- **FR-9.5 [P2]** **Prayers / devotionals** — a configurable prayer book, offline.
- **FR-9.6 [P2]** **Liturgical/church calendar** — feasts, fasts, seasons, commemorations, all provided by the content pack; drives themed content and reminders.
- **FR-9.7 [P3]** Devotional feed / plans authored by leaders.

**AC (FR-9.1 / 9.3):** Given a user downloads a reading plan or hymn set on Wi-Fi, when they later open it with no connection, then all text (and downloaded audio) is fully available, progress/favorites persist locally, and any changes sync when back online.

> **Content-pack model.** A *content pack* is a versioned bundle (Bible translation availability, hymn set, prayer book, calendar, reading plan) that the administrator selects/loads per deployment. This is how the platform stays denomination-neutral while still feeling native to each church.

### 8.10 Memorization & Points / Achievements

**Purpose:** Digitize the widespread paper "points" practice for children and track what each member has memorized.

- **FR-10.1 [P2]** Track memorization items (verses, passages, hymns) per member with status (assigned/in-progress/mastered).
- **FR-10.2 [P2]** **Points & badges** for attendance, memorization, participation; configurable rules.
- **FR-10.3 [P2]** Leaderboards (group-level, privacy-respecting, opt-in) and personal progress.
- **FR-10.4 [P3]** Rewards catalog / redemption tracking for physical prizes.

### 8.11 Trips, Conferences & Event Logistics

**Purpose:** Run overnight trips and conferences safely and without spreadsheets.

- **FR-11.1 [P2]** Event page: description, dates, cost, capacity, itinerary, packing list.
- **FR-11.2 [P2]** **Registration** with waitlist and capacity limits.
- **FR-11.3 [P2]** **Digital consent / permission forms** with parent e-signature and emergency + medical info capture.
- **FR-11.4 [P2]** Payment/deposit **tracking** (record of who paid; not a payment processor in v1).
- **FR-11.5 [P2]** Rooming, bus/transport, and group assignments.
- **FR-11.6 [P3]** On-trip headcount/roll-call and incident logging.

**AC (FR-11.3):** Given a parent completes a consent form, when submitted, then the trip organizer sees consent status, emergency/medical info is access-restricted to authorized organizers, and no minor can be marked "cleared to travel" without a valid consent record.

### 8.12 Notifications & Reminders

**Purpose:** Timely nudges that work even when the phone is offline.

- **FR-12.1 [MVP]** Push notifications for schedule changes, new assignments, announcements, and absence alerts.
- **FR-12.2 [MVP]** **On-device scheduled local notifications** for upcoming meetings/tasks so reminders fire without connectivity.
- **FR-12.3 [MVP]** Per-user notification preferences (channels, quiet hours, per-category opt-out).
- **FR-12.4 [P2]** Digest notifications (daily/weekly summary) and escalation reminders.
- **FR-12.5 [P2]** Fallback channel (SMS/email) for critical messages when push is unavailable (optional/costed).

**AC (FR-12.2):** Given a user has an upcoming meeting cached locally, when the device is offline at reminder time, then a local notification still fires; when a schedule change syncs later, then the local reminder is recomputed to the new time.

### 8.13 Safeguarding, Privacy & Audit

**Purpose:** A duty-of-care layer, because the system holds data about minors. This is a differentiator, not an afterthought.

- **FR-13.1 [MVP]** **Scope-based access** to minors' records (my group / my stage) enforced server- and client-side.
- **FR-13.2 [MVP]** **Audit log** of who viewed/edited sensitive records and when.
- **FR-13.3 [MVP]** Data minimization: sensitive fields (medical, notes) separated and access-gated.
- **FR-13.4 [P2]** Safeguarding policy acknowledgment for servants; onboarding checklist.
- **FR-13.5 [P2]** Consent management for storing/using minors' data and photos (photo-consent flags respected by galleries).
- **FR-13.6 [P2]** Data subject requests: export and deletion workflows.
- **FR-13.7 [P2]** Encryption of sensitive data at rest on-device (see Section 10/11).

**AC (FR-13.2):** Given any user opens a minor's sensitive record, when the view loads, then an audit entry (who/what/when/scope) is recorded; when an admin reviews the audit log, then all sensitive accesses are attributable and time-ordered.

### 8.14 Analytics & Reporting

**Purpose:** Give leaders insight without exposing raw sensitive data.

- **FR-14.1 [P2]** Attendance trends per group/stage over time.
- **FR-14.2 [P2]** Engagement/at-risk dashboards (members trending toward absence).
- **FR-14.3 [P2]** Servant activity/load summaries.
- **FR-14.4 [P3]** Exportable reports (PDF/CSV) for leadership meetings.
- **FR-14.5 [P3]** Configurable KPI dashboard tied to Section 3 metrics.

### 8.15 Prayer & Praise Board

**Purpose:** A shared, moderated space for prayer requests and praise reports; ties the community together.

- **FR-15.1 [P2]** Submit prayer requests (public to group / private to clergy), with moderation.
- **FR-15.2 [P2]** Mark "praying," post praise reports/answers.
- **FR-15.3 [P3]** Prayer reminders and prayer-partner pairing.

### 8.16 Administration & Configuration

**Purpose:** Let a non-developer administrator run the deployment.

- **FR-16.1 [MVP]** Organization profile, stages/structure setup, and content-pack selection.
- **FR-16.2 [MVP]** User & role management; group setup; scope configuration.
- **FR-16.3 [MVP]** Notification and reminder defaults.
- **FR-16.4 [P2]** Content management (upload hymns, prayers, curriculum, reading plans).
- **FR-16.5 [P2]** Feature flags to enable/disable modules per deployment.
- **FR-16.6 [P3]** Multi-tenant administration (if the platform serves multiple churches).

---

## 9. Non-Functional Requirements (NFR)

| ID | Category | Requirement |
|---|---|---|
| NFR-1 | **Offline-first** | All MVP core workflows (view schedule, take attendance, follow-up, tasks, read content) function with zero connectivity; changes queue and sync automatically. |
| NFR-2 | Performance | App cold start ≤ 3s on mid-range Android; list/screen interactions ≤ 200ms from local cache; sync is background and non-blocking. |
| NFR-3 | Reliability / sync | No data loss on connectivity drop; a mutation, once accepted locally, is durably queued until confirmed by the server. |
| NFR-4 | Security | TLS in transit; sensitive data encrypted at rest on-device; JWT + refresh tokens; least-privilege RBAC enforced server-side (client checks are UX only). |
| NFR-5 | Privacy / safeguarding | Minors' data access is scoped, logged, and minimized; consent + audit per Section 8.13; align to applicable data-protection law. |
| NFR-6 | Localization | Full i18n incl. right-to-left (RTL) support; date/number/calendar localization; content packs per language. |
| NFR-7 | Accessibility | Target WCAG 2.1 AA equivalents: scalable text, sufficient contrast, screen-reader labels, adequate touch targets. |
| NFR-8 | Scalability | Backend scales to the largest single-church load (thousands of members, hundreds of concurrent servants) with headroom for multi-tenant later. |
| NFR-9 | Maintainability | Single KMP codebase, shared domain/data layers; modular features behind flags; automated tests on shared logic. |
| NFR-10 | Portability | Android + iOS from shared KMP; backend containerized and cloud-agnostic. |
| NFR-11 | Observability | Structured logging, sync-failure metrics, crash reporting, and an admin-visible sync/health indicator in-app. |
| NFR-12 | Storage footprint | Configurable on-device cache limits; media (audio/PDF) downloaded on Wi-Fi by default with size caps and eviction. |
| NFR-13 | Battery/data | Sync batched and adaptive to network type; respect metered connections and background limits per OS. |

---

## 10. Technical Architecture Overview

### 10.1 High-level shape
```
┌───────────────────────────── Mobile client (KMP) ─────────────────────────────┐
│  UI (Compose Multiplatform / native)                                           │
│  ── Presentation (shared) ── Domain/use-cases (shared) ──                       │
│  Repositories (shared)                                                          │
│     ├── Local store: SQLDelight (+ SQLCipher for sensitive tables)              │
│     ├── Sync engine: outbox (mutations) + delta pull (reads) + conflict rules   │
│     ├── Media cache: audio/PDF, Wi-Fi-gated, size-capped                        │
│     └── Local scheduler: on-device notifications                                │
└──────────────────────────────── HTTPS / JSON ─────────────────────────────────┘
                                    │
┌───────────────────────────── Spring Boot backend ─────────────────────────────┐
│  API gateway / REST (versioned)  ── Auth (JWT + refresh, RBAC)                  │
│  Domain services: members, groups, schedule, attendance, tasks, content, ...    │
│  Sync service: change-feed / delta endpoints, tombstones, idempotency           │
│  Notification service (push via FCM/APNs)  ── Audit service                     │
│  Persistence: relational DB (PostgreSQL)  ── Object storage (media)             │
└────────────────────────────────────────────────────────────────────────────────┘
```

### 10.2 Client (KMP)
- **Shared modules:** domain models, use-cases, repositories, sync engine, and validation live in `commonMain` for maximum reuse; only platform bindings (notifications, secure storage, file system) are platform-specific.
- **UI:** Compose Multiplatform is the natural fit for one role-based app; native UI per platform remains an option if platform fidelity demands it.
- **Local persistence:** **SQLDelight** (type-safe, KMP-native). Sensitive tables (member notes, medical, contact) encrypted with **SQLCipher**; keys held in platform secure storage (Keystore/Keychain).

### 10.3 Backend (Spring Boot)
- Versioned REST/JSON APIs; stateless services behind a gateway; JWT auth with refresh; server-side RBAC as the source of truth.
- **PostgreSQL** for relational data; **object storage** (S3-compatible) for media (hymn audio, lesson attachments, photos).
- Dedicated **sync endpoints** exposing per-entity change feeds (see Section 11), plus a **notification service** integrating FCM (Android) and APNs (iOS), and an **audit service** for sensitive-access logging.

### 10.4 Integrations
| Integration | Purpose | Phase |
|---|---|---|
| FCM / APNs | Push notifications | MVP |
| Object storage (S3-compatible) | Media hosting | MVP |
| Device calendar (ICS) | Schedule export/subscribe | P2 |
| SMS/email provider | Critical-message fallback | P2 |
| Maps deep-link | Event locations/directions | P2 |
| External video tools | Meeting links (deep-link only) | P2 |
| Payment processor | Trip payments (tracking only in v1) | P3 |

---

## 11. Data & Sync Strategy (Offline-First Deep Dive)

This is the architectural core given the connectivity constraint. The goal: **the app is fully usable offline, and reconciles safely when the network returns.**

### 11.1 Principles
- **Local-first reads:** the UI always reads from the local store; the network only refreshes the cache.
- **Queued writes (outbox):** every mutation is written locally and appended to an **outbox**; a background worker drains it to the server with retries and idempotency keys.
- **Server as source of truth** for shared, authoritative data; the client holds a consistent, eventually-synced replica.

### 11.2 Sync mechanics
- **Delta / incremental sync:** each syncable entity carries `updatedAt` (and a monotonic version). The client pulls "changes since last sync token"; the server returns inserts/updates plus **tombstones** for deletes.
- **Idempotency:** mutations carry a client-generated ID so retries don't duplicate.
- **Batching & adaptivity:** sync is batched, backgrounded, and adapts to network type (full sync on Wi-Fi, lightweight deltas on cellular).
- **Media on demand:** large assets (hymn audio, lesson PDFs) are referenced by metadata and downloaded on Wi-Fi with size caps + LRU eviction.

### 11.3 Conflict resolution — **per data type**, not one-size-fits-all
| Data type | Strategy | Rationale |
|---|---|---|
| Schedules, curriculum, groups, config | **Server-authoritative last-write-wins** (with edit-conflict warning to the editor) | Few editors, authority matters |
| **Attendance** | **Merge / union** at record level (per member-per-session), never blind overwrite | Two servants may mark the same session concurrently |
| **Follow-up & private notes** | **Append-only** log; entries never overwrite each other | Preserves each servant's contribution |
| Tasks | **Field-level merge** where possible; status transitions reconciled deterministically | Assignee and creator may edit offline |
| Personal state (reading progress, favorites, points) | **Per-user, last-write-wins** | Single owner, low conflict |

> For most entities, server-authoritative LWW is sufficient. The **append/merge** treatment is reserved for collaborative, loss-sensitive data (attendance, notes) — a deliberate choice to avoid silently discarding a servant's work.

### 11.4 Data classification (what must be offline)
| Class | Examples | Offline policy |
|---|---|---|
| **Must be offline** | My groups' schedule, my served members' records, today's lesson, taken attendance, my tasks, downloaded hymns/readings | Pre-fetched & always cached |
| **Nice offline** | Wider directory, other stages' schedules | Cached opportunistically |
| **Online-only** | Analytics dashboards, full audit log, admin config | Fetched live; degrade gracefully |

### 11.5 Caching layers
1. **In-memory** (session/UI state).
2. **Encrypted local DB** (SQLDelight/SQLCipher) — the durable offline replica + outbox.
3. **Media cache** (file system, Wi-Fi-gated, size-capped).
4. **Server cache / CDN** for content packs and media delivery.

### 11.6 Sync health & UX
- Visible sync status (last synced, pending changes, errors) and manual "sync now."
- Conflict/edit warnings surfaced to the user rather than hidden.
- Failed mutations retried with backoff; unrecoverable ones flagged for user action.

---

## 12. High-Level Data Model (Conceptual)

Core entities and key relationships (attributes abbreviated):

- **User** (id, credentials, status) — holds **Roles** (role, scope: org/stage/group).
- **Person** (base profile) specialized as **Servant** and **ServedMember**; **Family** links Persons (guardian/sibling).
- **Group** (type, stage) — has many **Assignments** (Servant ↔ Group, with lead flag) and **Memberships** (ServedMember ↔ Group).
- **Event** (recurring rule, time, location) → **EventOccurrence** → **AttendanceRecord** (occurrence ↔ member ↔ status).
- **FollowUp** (member, servant, outcome, timestamps) — append-only.
- **Task** (assignee, status, type, due) — optionally linked to member/event/lesson.
- **Note** (member, author, scope, encrypted) — append-only, audited.
- **Lesson** (curriculum unit, status, content, version) with **Approval**.
- **ContentItem** (verse, hymn, prayer, reading) grouped into a **ContentPack** (versioned).
- **MemorizationItem** and **PointsLedger** (member, source, amount).
- **Trip/Event** with **Registration**, **ConsentForm**, **PaymentRecord**, **Assignment** (room/bus).
- **AuditEntry** (actor, action, target, scope, timestamp).
- **SyncState / Outbox** (client-side: entity, op, clientId, status).

*(A full ERD and field-level dictionary are recommended as a follow-on artifact in Phase 0/1.)*

---

## 13. Phased Roadmap

The single app ships incrementally; each phase is independently valuable.

### 13.1 MVP — "Coordinate & follow up" (prove the core loop)
The goal is the daily operational loop: **schedule → attend → follow up → assign tasks**, plus essential content, all offline-first.

- Auth, roles, offline session (8.1)
- Member directory, family links, record portability (8.2)
- Groups, servant assignment, annual promotion (8.3)
- Recurring schedules with propagation (8.4)
- Attendance + absentee follow-up + absence alerts (8.5)
- Task management basics / Kanban (8.6)
- Announcements (8.7)
- Bible reading & tracking, daily verse, hymns (text) (8.9)
- Push + local notifications (8.12)
- Scope-based access + audit basics (8.13)
- Admin setup, roles, content-pack selection (8.16)
- Offline-first data & sync engine (Section 11)

### 13.2 Phase 2 — "Enrich & safeguard"
- Private follow-up notes, talents, milestones (8.2)
- Sub-groups, ratios/safeguarding rules (8.3)
- RSVP, calendar export, resource booking (8.4)
- Attendance trends, at-risk flags, self check-in (8.5)
- Task comments/attachments, templates, boards (8.6)
- Contextual threads, direct messaging (8.7)
- Curriculum & lesson workflow + library (8.8)
- Readings, prayers, liturgical calendar, hymn audio (8.9)
- Memorization & points/badges (8.10)
- Trips: registration, consent, payment tracking, rooming (8.11)
- Digests, escalation, SMS/email fallback (8.12)
- Safeguarding acknowledgment, consent, DSRs, at-rest encryption hardening (8.13)
- Analytics dashboards (8.14)
- Prayer & praise board (8.15)
- Content management, feature flags (8.16)

### 13.3 Phase 3 — "Scale & optimize"
- Guest records; workload balancing (8.2/8.6)
- Message translation (8.7)
- Post-lesson feedback (8.8)
- Devotional feed/plans (8.9)
- Rewards catalog (8.10)
- On-trip roll-call & incident logging (8.11)
- Exportable reports, KPI dashboard (8.14)
- Prayer reminders / partner pairing (8.15)
- Multi-tenant administration; optional read-only web/admin console (8.16)

### 13.4 Feature-to-phase matrix (condensed)
| Module | MVP | P2 | P3 |
|---|:--:|:--:|:--:|
| Auth & identity | ● | ○ | |
| Member records | ● | ○ | ○ |
| Groups & assignments | ● | ○ | |
| Scheduling | ● | ○ | |
| Attendance & follow-up | ● | ○ | |
| Tasks | ● | ○ | ○ |
| Communication | ● | ○ | ○ |
| Curriculum & lessons | | ● | ○ |
| Content library | ● | ○ | ○ |
| Memorization & points | | ● | ○ |
| Trips & logistics | | ● | ○ |
| Notifications | ● | ○ | |
| Safeguarding & audit | ● | ○ | |
| Analytics | | ● | ○ |
| Prayer & praise | | ● | ○ |
| Admin & config | ● | ○ | ○ |

● = introduced · ○ = extended

---

## 14. Risks & Mitigations

| # | Risk | Impact | Mitigation |
|---|---|---|---|
| R1 | Sync conflicts corrupt or lose data | High | Per-type conflict rules (§11.3); append/merge for loss-sensitive data; idempotent mutations; extensive sync testing |
| R2 | Sensitive minor data exposure | High | Scoped access, audit, encryption at rest, data minimization, consent (§8.13) |
| R3 | Low volunteer adoption | High | Ruthless MVP focus on the daily loop; minimal data entry; import existing lists; in-app onboarding |
| R4 | Content licensing (Bible/hymns) unclear | Medium | Content-pack model; secure rights before bundling; allow admin-provided content |
| R5 | Two-app temptation reappears, doubling cost | Medium | Commit to single role-based app; revisit only with a hard requirement |
| R6 | Media storage/bandwidth costs balloon | Medium | Wi-Fi-gated downloads, size caps, CDN, on-demand fetch |
| R7 | Scope creep across many modules | Medium | Phase gates; feature flags; each phase independently shippable |
| R8 | Offline reminders unreliable across OS versions | Medium | On-device local notifications + server push; test against OS background limits |
| R9 | Small ops team can't maintain infra | Medium | Managed DB/hosting, containerization, minimal service count, observability from day one |

---

## 15. Open Questions / Decisions Log

| # | Question | Owner | Notes |
|---|---|---|---|
| Q1 | Confirm baseline metrics for Section 3 targets | BA / Leadership | Needed to make targets real |
| Q2 | Which platforms first — Android-only MVP then iOS, or both together? | Product | Affects timeline/cost |
| Q3 | Compose Multiplatform UI vs native per platform? | Architecture | Reuse vs fidelity trade-off |
| Q4 | Source & licensing for Bible translation(s) and hymns | Leadership | Blocks content packs |
| Q5 | Applicable data-protection regime for minors' data | Legal | Drives §8.13 specifics |
| Q6 | Parent app experience — same app (role) or lighter surface? | Product | Currently: same app, Parent role |
| Q7 | Single-church now, multi-tenant later — commit to tenant-ready schema from day one? | Architecture | Cheaper now than retrofitting |
| Q8 | Which external tools to deep-link (video, maps, SMS provider)? | Product | Integrations backlog |

---

## 16. Glossary

| Term | Meaning |
|---|---|
| **Servant** | A volunteer/leader/teacher/mentor who serves others (configurable label). |
| **Served member** | A person receiving the service — child, youth, or member (configurable label). |
| **Stage / Grade** | An organizational tier grouping members (e.g., by age/grade). |
| **Follow-up** | Contacting an absent or at-risk member and logging the outcome. |
| **Content pack** | A versioned, configurable bundle of readings, prayers, hymns, and calendar for a tradition/language. |
| **Outbox** | Local queue of pending mutations awaiting sync. |
| **Delta sync** | Pulling only changes since the last sync token. |
| **Tombstone** | A deletion marker propagated so clients remove deleted records. |
| **Scope** | The boundary (org/stage/group/self) limiting what a role can access. |
| **RBAC** | Role-Based Access Control. |
| **KMP** | Kotlin Multiplatform (shared code across Android/iOS). |

---

## 17. Mapping to Your Original Request

Every feature you listed is captured and extended:

| Your request | Where it lives |
|---|---|
| Bible reading & tracking | FR-9.1 |
| Random daily verses | FR-9.2 |
| Login & role assignment | §6, FR-1.x |
| Groups & responsible servants (esp. for children) | §8.3, safeguarding §8.13 |
| Shared meeting/training schedules that update for all | FR-4.1/4.2 |
| Jira-like task distribution between servants | §8.6 |
| Curriculum & lesson prep/delivery | §8.8 |
| Trips & conferences | §8.11 |
| Full portable records of the served across group/servant changes | FR-2.4 |
| Hymns in the app | FR-9.3 |
| Appointment notifications & absentee reminders | §8.5, §8.12 |
| **Added:** attendance/follow-up engine, memorization & points, safeguarding & audit, prayer/praise board, analytics, family linking, annual promotion, offline-first sync design | §8.5, §8.10, §8.13, §8.15, §8.14, §8.2, §8.3, §11 |

---

*End of BRD v0.1 (Draft). Recommended next artifacts: a detailed ERD + data dictionary, API contract, wireframes for the MVP core loop, and a security/privacy assessment for minors' data.*
