# Lao Pai Design System

Version 2.0 · Passenger app · iOS native · English-first

The authoritative UI source of truth for the Lao Pai passenger app. [BRAND_DIRECTION.md](BRAND_DIRECTION.md) carries the strategy; this document carries the implementation system.

## Brand foundation

**Lao Pai** helps people move through Laos with confidence. On iOS it should feel native: calm, dependable, and immediately understandable — easy to read in bright daylight and direct when a rider is in a hurry.

The brand idea is **native confidence**: we follow iOS Human Interface Guidelines exactly, so trust comes from platform-familiar behavior. Personality comes from copy, tone, and one restrained accent — not custom chrome.

### Principles

1. **The ride is the hero.** The map, destination, ETA, and fare are more prominent than decoration.
2. **One decisive action per state.** The next useful action is always visible in the bottom thumb zone.
3. **Native, not branded chrome.** Use standard iOS components; customize behavior, not appearance.
4. **Grouped lists over repeated cards.** Structure comes from inset-grouped sections and spacing.
5. **Trust is visible.** Driver identity, live status, fare, and safety actions are clear at every important moment.

## Color

Semantic system colors only. Reference them through defined tokens; never use raw color literals inside feature widgets. All tokens resolve automatically for light and dark mode.

| Token | Cupertino system color | Light reference | Usage |
|---|---|---|---|
| `tint` | `systemBlue` | `#007AFF` | Primary buttons, active tab, links, progress |
| `success` | `systemGreen` | `#34C759` | Confirmed, driver assigned, completed |
| `attention` | `systemOrange` | `#FF9500` | Matching, fare highlight, time-sensitive status |
| `danger` | `systemRed` | `#FF3B30` | Cancel ride, destructive, errors |
| `background` | `systemBackground` | `#FFFFFF` | Map-adjacent pages, sheets |
| `groupedBackground` | `systemGroupedBackground` | `#F2F2F7` | History, Account full-page canvas |
| `cardSurface` | `secondarySystemGroupedBackground` | `#FFFFFF` | Grouped list cards |
| `fillSurface` | `tertiarySystemFill` | `rgba(118,118,128,0.12)` | Secondary buttons, chips, icon tiles |
| `textPrimary` | `label` | system | Titles, body |
| `textSecondary` | `secondaryLabel` | system | Metadata, captions |
| `textTertiary` | `tertiaryLabel` | system | Placeholders, footnotes |
| `separator` | `separator` | system | Hairlines (0.5pt), inactive outlines |

### Usage rules

- One accent only: `tint`. Green, orange, and red carry meaning — they are never decorative.
- Status is never color alone: pair with an icon or text label.
- Dark mode is first-class; because tokens are semantic, it comes for free. Never hard-code light values.
- Map chrome (pins, route, shadows) may use map-native styling; the surrounding UI still uses tokens.

## Typography

SF Pro via the system (Flutter `CupertinoTheme` default text styles). No custom font. Lao localization later pairs **Noto Sans Lao** at the same weight hierarchy.

Dynamic Type is mandatory. All text uses iOS text styles so it scales; the major flows must not clip at accessibility sizes.

| Role | iOS text style | Size / weight | Usage |
|---|---|---|---|
| Large title | `largeTitle` | 34 / bold | Top of History, Account |
| Title | `title3` / `title` | 20–17 / semibold | Screen titles, section headers |
| Body | `body` | 17 / regular | List rows, descriptions, primary CTA |
| Callout | `callout` | 16 / regular | Secondary row text |
| Footnote | `footnote` | 13 / regular | Metadata, timestamps |
| Caption | `caption1` | 12 / regular | Hints, legal, tab labels |

- Tabular (monospaced digit) variants for fares, distances, and countdowns.
- Sentence case everywhere; no all-caps labels.
- Max four text roles per screen.

## Spacing and layout

Base unit: **8pt**, with 4pt for icon/text pairing. Standards: `4, 8, 12, 16, 20, 24, 32`.

| Token | Value | Usage |
|---|---|---|
| `spaceXs` | 4 | Icon ↔ text inside a row |
| `spaceSm` | 8 | Between adjacent items |
| `spaceMd` | 16 | Screen margins, grouped-list insets |
| `spaceLg` | 20 | Row internal padding |
| `spaceXl` | 24 | Section separation |
| `space2xl` | 32 | Between major content groups |

- Screen margins: 16pt. Inset-grouped cards inherit the standard inset.
- Grouped sections separated by 24pt with an informative footer where helpful.
- Minimum hit target: **44×44pt**, 8pt apart; primary CTA is 50pt tall.
- Fixed headers, tab bar, and fixed CTAs always respect safe areas and the home indicator.
- Content bottom inset when bottom navigation or a fixed CTA is visible so nothing scrolls beneath it.

## Shape and materials

| Element | Radius | Material |
|---|---:|---|
| List card / sheet | 10pt | `cardSurface` on `groupedBackground` |
| Button | 12pt | Filled or `fillSurface` |
| Chip | 8pt | `fillSurface` |
| Bars / sheets (frosted) | — | iOS blur material (`SystemUltraThinMaterial`-equivalent) |

- Use the platform blur/frosted material for the toolbar over maps, compact status chips, and the tab bar.
- Prefer hairline `separator` strokes over shadows. No pure-black shadows; map cast shadows follow map convention.

## Iconography

- Outline SF-Symbols-style icons: 20pt inside rows, 24pt for standalone bar/CTA controls.
- Map to the Cupertino icon set in Flutter (`cupertino_icons`); match glyph visual weight across the app.
- Icon-only controls need an accessible label and a 44pt target.
- Never use emoji as navigation, account, or system icons.

## Components

### Prominent filled button (primary CTA)

- Height: 50pt; full width within screen margins; radius 12pt; `tint` background; white bold body text.
- Exactly one per state; disabled state is 30% opacity of the same style.
- Pressed: standard iOS highlight (opacity dim), never layout shift.

### Filled gray button (secondary)

- Height: 44–50pt; `fillSurface` background; `tint` text; radius 12pt.

### Destructive button

- Same metrics as secondary; `danger` text on `fillSurface`, or plain red text row inside an action sheet.

### Search field (destination)

- iOS search-field look on `background` inside the Home sheet: `fillSurface` pill, magnifier icon, placeholder "Where would you like to go?".
- Never an empty search experience: recents and saved places render below immediately.

### Bottom sheet (detents)

- Grabber handle, radius 10pt, two detents: peek (~35% height) and full.
- Ride selection and destination search live here, over the map.
- Peek must always show the primary CTA ahead of the full sheet.

### Grouped list

- Inset-grouped sections: `cardSurface` cards, radius 10pt, 0.5pt `separator` hairlines inset to text.
- Rows: 44pt (compact) to 60pt (double-line), 20pt horizontal padding.
- Section footnotes use `textTertiary` footnote style.

### List row

- Title (body) + supporting line (footnote); trailing value or chevron in `textTertiary`.
- Divider between rows instead of surrounding every row in its own card.

### Fare and status

- Fare: tabular digits, title weight, `textPrimary`; suffix `₭` (Lao kip).
- ETA during tracking: largest emphasis on screen — 34pt large title weight after the driver card.
- Status = text label + icon shape; color is supportive, never the sole signal.

### Navigation bar

- Large title collapsing on scroll; built-in Cupertino nav bar; no custom headers.
- Trailing icon buttons only (notifications, info).

### Tab bar

Exactly three destinations, frosted material background, safe-area aware:

| Tab | Purpose | Map allowed |
|---|---|---|
| Home | Start or track a ride | Yes |
| History | Review completed rides | No |
| Account | Profile and preferences | No |

- 49pt bar + safe-area inset; 44pt hit target per tab.
- Selected: `tint` icon + label; unselected: gray. Label always visible.

### Alerts and action sheets

- Destructive flows (cancel ride) use an action sheet with red destructive text and a cancel action.
- Errors use a one-provider alert: explanation + one recovery action.

### Context and swipe actions

- History rows: long-press context menu (View details, Repeat trip); trailing swipe reveals Repeat trip.

## Screen blueprints

### Home (map-first)

```
          large map + live position + route

      ┌─── sheet grabber (peek detent) ───┐
      │ [ 🔍 Where would you like to go? ]│
      │ [ Home 🏠 ] [ Work  ] [ Recent ]  │
      └──────────────────────────────────-┘

 [ Home ]        [ History ]        [ Account ]   ← frosted tab bar
```

- Map owns the screen; the destination sheet is the dominant control.
- When a ride is active, the sheet area becomes the tracking state instead.

### Ride selection (sheet over map)

1. Pickup and destination rows (editable, tap to revise).
2. Ride options as inset-grouped rows: vehicle type, capacity, arrival range, fare (tabular).
3. Full-width "Confirm ride" CTA in the sheet's thumb-zone position.

### Driver tracking (map + compact chip)

- Peak moment: ETA in large title weight on a frosted compact chip.
- Below it: driver identity (avatar, name, car, plate, rating) and Call/Message actions as one grouped list row.
- CTA: "Cancel ride" via action sheet, never an ambient red button.

### History (no map, no sheet)

```
 History (large title)
 [This month: 6 rides · ₭ 342,000]      ← capsule summary
 ─ Rounded grouped card ─
 Yesterday 18:42 · Wat Ong Teu → Airport
 Sawadee Van · Completed · ₭ 95,000      >
 ─ end card ─
```

- Inset-grouped chronological rows, newest first.
- Empty state: reassurance + "Start a ride" CTA to Home.

### Account (no map, no sheet)

```
 Account (large title)
 [avatar · May Vong · may@example.com]   → profile
 ─ Payment (Cash default) ─
 ─ Saved places · Settings · Help ─
 ─ Sign out (red row) ─
```

- Single profile row leads to editing; grouped preference rows below.

## Motion

Ship platform behavior, not choreography:

| Trigger | Behavior |
|---|---|
| Releasing a sheet | System undocking spring (Cupertino default) |
| Push / pop screens | Standard iOS push transition |
| Press feedback | 100–150ms highlight |
| Chip segment / sheet detent | ~250ms ease-in-out |
| Driver status pulse | Gentle 900ms opacity pulse, only while matching/searching |

- Motion explains a state change; it does not decorate.
- Honor Reduce Motion: jump to end states, disable pulses.
- Never animate layout width/height for routine changes; fade or transition via the system.

## Content voice

- Short, direct, reassuring: "Finding your driver", "Pickup in 3 min".
- Buttons describe the result: "Confirm ride", "Add payment method".
- Errors state cause and recovery: "We couldn't confirm your pickup. Choose a point on the map."
- English-first copy lives in string resources, ready for Lao localization.

## Accessibility checklist

- All text scales with Dynamic Type; major flows must not clip at accessibility sizes.
- 4.5:1 contrast against their surfaces; text over blur material tested in both modes.
- Every control has a visible focused/pressed state and 44pt hit area.
- Icon-only controls have labels; decorative icons hidden from assistive tech.
- Fixed CTAs and the tab bar never hide scrollable content.
- Map-only interactions (pins, moving markers) have list/table equivalents (search results, driver details card).
- Status conveyed by label + icon; color alone never differentiates.
