# Agent Guide — Lao Pai

## Read first

Before planning or editing, read:

1. [PRD.md](PRD.md) for scope, acceptance criteria, and delivery slices.
2. [design.md](design.md) for all UI decisions and accessibility baseline.
3. [ARCHITECTURE.md](ARCHITECTURE.md) before changing Flutter or Rust structure.

These documents are the product and design source of truth. Source code and existing API controllers are the technical source of truth when they differ from examples in documentation.

## Mission

Build the English-first Lao Pai passenger app in small, verified slices. Preserve the approved **native iOS (HIG)** design direction and the existing Flutter/Rust clean architecture.

## Execution loop

1. **Trace.** Inspect the closest existing feature, DTO, controller, and test before adding a new path.
2. **Slice.** Pick one PRD delivery slice or one coherent acceptance criterion.
3. **Build.** Keep changes inside the relevant feature/layer boundary.
4. **Verify.** Run the narrowest relevant analysis/test command, then inspect the diff for unrelated changes.
5. **Report.** State the outcome, tests run, and any remaining limitation.

Completion means the acceptance criterion is met in code and the relevant verification passes—not merely that a screen or endpoint exists.

## UI rules

- Follow [design.md](design.md); use semantic iOS system-color tokens instead of local visual values.
- Follow Flutter Cupertino conventions; no Material chrome in the shipped UI.
- Home is map-first. History and Account are full pages with no map and no bottom sheet.
- Bottom navigation contains only Home, History, and Account.
- Primary touch targets are at least 44pt (HIG); the primary CTA is 50pt; preserve safe-area, home-indicator, and bottom-navigation insets.
- Use one primary CTA per state. Implement loading, empty, error, and success states deliberately.
- Use vector/material icons with labels or accessible descriptions. Do not use emoji as structural UI icons.
- Maintain English-first copy and keep strings localization-ready.

## Flutter rules

- Respect `data → domain → presentation` separation inside each feature.
- Add use cases for business operations; do not put business rules in widgets.
- Keep API models, domain entities, and UI state types separate.
- Prefer Bloc events/states for screen modes over local Boolean state.
- Run from `ride_booking/`:

```bash
flutter analyze
flutter test
```

## Rust rules

- Preserve the dependency direction: `presentation → application → domain`.
- Infrastructure implements domain/application ports; domain never imports Axum, SQLx, or config.
- Check current controller DTOs before changing client API calls.
- Add a new migration for schema evolution; retain existing migration intent.
- Run from `backend/`:

```bash
cargo test
```

## Scope control

- Implement the current PRD slice only. Record a new product idea in the final report rather than silently expanding scope.
- Do not replace authentication, maps, payments, or dispatch providers without an explicit decision.
- Do not introduce a UI package solely for a single visual effect; use existing Flutter/Material capabilities first.
- Preserve user changes in a dirty worktree. Do not reset, overwrite, or delete unrelated files.

## Required final report

Every implementation report must include:

- What changed and which PRD acceptance criterion it satisfies.
- Files changed.
- Verification run and result.
- Any known limitation, mocked behavior, or follow-up needed.


