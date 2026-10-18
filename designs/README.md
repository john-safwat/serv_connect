# Designs

Source designs for ServeConnect, provided as **SVG** or **HTML** files. They are the reference for what the apps must look like; developers and the `design-parity-verifier` agent compare the built UI against them.

```
designs/
├── design-system.html      # optional: shared tokens & components (colors, type, spacing)
├── mobile/                 # Flutter app (serv_connect_mobile)
│   ├── en/                 # English (LTR) screens
│   └── ar/                 # Arabic (RTL) screens
└── dashboard/              # web/admin dashboard
    ├── en/
    └── ar/
```

## Naming

- One file per screen or state: `<NN>-<feature>-<screen>[-<state>].svg|html`, e.g. `03-attendance-take.svg`, `03-attendance-take-offline.svg`.
- The `en/` and `ar/` copies of a screen use the **same file name**, so they can be matched one-to-one.
- Group a large feature in a sub-folder if needed: `mobile/en/attendance/…` (mirror it in `ar/`).
- Exported assets (icons, illustrations) used by a design go in an `assets/` folder next to it.

## Rules

- Designs are input only — code never imports files from `designs/`. Assets the app needs are copied into the app project in the right format.
- Don't put real member data (names, photos, phone numbers) in designs; use obviously fake data.
- When a design changes, the plan for that feature (`plans/`) notes which files changed.
