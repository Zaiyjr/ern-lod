# Lao Pai Architecture

## Overview

The repository has two deployable parts:

```text
ride_booking/  Flutter passenger client
      │ HTTP + Bearer token
      ▼
backend/       Rust/Axum API
      │ SQLx
      ▼
PostgreSQL
```

The UI design reference is [design.md](design.md). Product scope and acceptance criteria live in [PRD.md](PRD.md).

## Flutter client

### Current structure

```text
ride_booking/lib/
├── app.dart                         # MaterialApp and auth-driven root routing
├── main.dart                        # bootstrap
├── injection_container.dart          # GetIt dependency graph
├── core/                             # theme, errors, network, location, use cases
└── features/
    ├── auth/
    │   ├── data/                     # remote/local sources and repository implementation
    │   ├── domain/                   # User entity, repository contract, auth use cases
    │   └── presentation/             # Bloc and authentication pages
    └── ride/
        └── presentation/             # map widgets; expand using the same layers
```

### Client rules

- Keep dependencies flowing inward: presentation → application/domain → data/infrastructure.
- Use a feature directory for new ride behavior: `data`, `domain`, and `presentation`.
- Put business decisions in use cases; widgets render Bloc state and dispatch events.
- Reuse the app theme tokens; no feature-specific hex values.
- Keep API data models separate from domain entities.
- Location/map services remain behind `core/services` or a feature datasource; widgets do not call platform APIs directly.

### State model

Use explicit states for mutually exclusive ride phases:

```text
idle → destination selected → quote selected → requesting
     → matching → assigned → arriving → in progress → completed
                                      └──────────→ cancelled / failed
```

The active state, not widget-local booleans, decides which primary screen and CTA render.

## Rust backend

### Clean Architecture layers

```text
backend/src/
├── domain/           # entities, repository traits, domain errors
├── application/      # use cases, DTOs, service port traits
├── infrastructure/   # PostgreSQL repository implementations, config, Argon2, JWT
└── presentation/     # Axum routes/controllers/middleware/AppState
```

### Dependency rule

```text
presentation → application → domain
infrastructure ───────────→ domain/application ports
```

Domain code never imports Axum, SQLx, or environment/config code. Controllers translate HTTP into application DTOs and translate typed errors into HTTP responses.

### Existing HTTP surface

`backend/src/presentation/routes.rs` nests routes under `/api/v1`:

```text
GET  /health
/api/v1/auth/*
/api/v1/rides/*
```

Auth and ride route/controller definitions in source are the current contract. Update the Flutter client only after verifying the precise request/response DTOs.

### Persistence and security

- PostgreSQL schema is in `backend/migrations/0001_init.sql`.
- Startup applies this migration with SQLx raw SQL.
- Passwords use Argon2; authentication tokens use HS256 JWT.
- Keep secrets in `.env`, never in source or client builds.
- Add a migration rather than changing historical migration behavior once environments exist.

## Request lifecycle

```text
Flutter Bloc event
  → use case
  → repository contract
  → remote datasource / HTTP client
  → Axum controller
  → application ride use case
  → repository port
  → PostgreSQL implementation
```

Responses travel back through DTO/model mapping to a domain entity, then into a Bloc state. Preserve typed failures across each boundary so the UI can offer an actionable state.

## Implementation seams for the next agent

| Need | Flutter seam | Rust seam |
|---|---|---|
| Ride request | `features/ride/domain/usecases` + ride Bloc | `application/usecases/ride_usecase.rs` |
| Ride history | ride repository and history Bloc state | ride repository trait + controller |
| Saved places | `features/places` (new feature) | add entity/repository only when API scope is approved |
| Profile/settings | auth/profile feature | auth controller/use case |
| Live tracking | abstract stream datasource first | event/polling contract before websocket work |

## Quality boundaries

- Flutter: use `flutter analyze` and targeted widget/Bloc tests.
- Rust: use `cargo test`; preserve the clean-architecture test boundaries already present.
- Test each API error mapping at a controller/use-case boundary.
- Avoid cross-cutting UI changes inside the auth feature when implementing ride states; create ride presentation modules.


