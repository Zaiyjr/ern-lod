# Lao Pai — Passenger App PRD

## 1. Summary

Lao Pai is an English-first ride-hailing passenger app for Laos. This release establishes a reliable rider experience from account creation through requesting, tracking, and reviewing a trip.

**Product principle:** the next useful action must be immediately clear.

## 2. Problem

Riders need a simple, trustworthy way to request transport, understand the cost and arrival estimate, and retain a record of past trips. They should not need to navigate a dense interface or decipher ambiguous statuses while on the move.

## 3. Goals and non-goals

### Goals

- A rider can register, sign in, and remain signed in.
- A rider can choose a pickup and destination, compare ride options, and request a ride.
- A rider can see an unambiguous ride state and assigned driver details.
- A rider can review completed rides and manage their account.
- The shipped UI follows [design.md](design.md).

### Non-goals for this release

- Driver-facing workflow or driver earnings.
- Live dispatch optimization, surge pricing, or real payment processing.
- Multi-stop trips, scheduled rides, referrals, promotions, and loyalty.
- Production-grade maps/search provider integration beyond the current OpenStreetMap/location implementation.

## 4. Users and jobs

| User | Job to be done | Success signal |
|---|---|---|
| Returning rider | “Get me to a familiar place quickly.” | Uses saved/recent place or search in under two taps. |
| New rider | “Know what will happen before I request a car.” | Sees pickup, ride type, price estimate, and confirmation. |
| Rider waiting for a car | “Know whether I should wait and who is coming.” | Sees driver identity, car, ETA, and contact actions. |

## 5. Primary flow

```text
Home → destination search → ride selection → confirmation
     → finding driver → driver tracking → completed ride → history
```

Home, History, and Account are persistent bottom-navigation destinations. Map UI is limited to Home and active ride states.

## 6. Functional requirements

### Authentication

- Register using email, password, display name, and `rider` role.
- Sign in, sign out, and restore a valid session on app launch.
- Show clear inline errors for invalid or failed authentication.

### Home

- Show the rider’s current location on the map when permission is granted.
- Offer a visible destination search entry point, recent destinations, and saved places.
- Show vehicle category choices when a destination is selected.

### Ride request and tracking

- Collect a pickup, destination, and selected ride category before enabling confirmation.
- Display a fare estimate and estimated pickup window before request submission.
- Submit the request through the rides API.
- Render one clear state at a time: requested, matching, driver assigned, arriving, in progress, completed, cancelled.
- When matched, show driver name, vehicle details, rating, ETA, and Call/Message actions.

### History

- List completed/cancelled rides newest first.
- Each row shows route, date/time, service type, status, and fare.
- Include an empty state with a direct path to Home when there are no rides.

### Account

- Show profile name and email.
- Offer routes to payment methods, saved places, settings, and help.
- Payment methods are presentation-only in this release; cash is the default.

## 7. UX and visual requirements

- Use the token and component rules in [design.md](design.md).
- Home is map-first; History and Account are full-canvas pages without a map or bottom sheet.
- Bottom navigation has exactly Home, History, and Account.
- Primary controls are in the bottom thumb zone and measure at least 44pt (HIG); the primary CTA is 50pt.
- Fares use Lao kip (`₭`) and tabular numerals.
- Support English first; do not hard-code copy such that Lao localization becomes difficult.
- All loading, empty, error, and success states are deliberate and actionable.

## 8. API contract currently available

| Area | Base path | Notes |
|---|---|---|
| Health | `GET /health` | Unauthenticated |
| Auth | `/api/v1/auth` | Register, login, current profile |
| Rides | `/api/v1/rides` | Request, pending, match, status routes |

The implementation must inspect the current Rust controllers before adding client calls. API shape in code is authoritative over this PRD.

## 9. Acceptance criteria

### Happy path

1. A new rider can register and reach Home.
2. The rider selects a destination and a ride type.
3. The rider sees fare and pickup information, confirms, and gets a request-created state.
4. Once the API returns an assignment, the tracking state shows driver information and actions.
5. A completed trip appears in History.

### Quality gates

- `flutter analyze` passes.
- Existing Flutter tests pass; new logic has focused tests.
- `cargo test` passes after backend changes.
- No route, list, or CTA is hidden behind the bottom navigation.
- Main flows work on a 375px-wide phone viewport.

## 10. Delivery slices

| Slice | Scope | Done when |
|---|---|---|
| 1 | Theme, navigation, static Home/History/Account | Matches `design.md`; no map on History/Account. |
| 2 | Auth wiring and session restoration | Register/login/logout work with backend. |
| 3 | Ride request and lifecycle UI | State-driven request/matching/tracking flow is connected. |
| 4 | History and account data | API-backed history/profile with empty/error states. |
| 5 | Validation pass | Tests, accessibility, copy, and layout checks complete. |

## 11. Metrics for a later production release

- Completed rides / requested rides
- Median time from request to driver match
- Median pickup ETA accuracy
- Destination-search to request conversion
- Authentication success rate


