# Lao Pai — Visual Brand Direction

## Positioning

Lao Pai is a calm, dependable way to move through Laos. On iPhone it should feel like it belongs: a native iOS experience that riders already know how to use, expressed in English-first, local voice.

## Brand idea: Native confidence

The visual direction is full iOS Human Interface Guidelines. We do not manufacture a custom look; we earn trust by behaving exactly like the platform. Brand personality comes from copy, tone, and one restrained brand tint — not from custom chrome.

## Design platform

- Target: iOS (HIG), iPhone first.
- Flutter implementation follows Cupertino conventions (Cupertino widgets, iOS navigation patterns) rather than Material styling.
- English-first copy; stays localization-ready for Lao later.

## Color

Semantic system colors only, always through tokens — never raw literals in feature code. Every token resolves automatically in light and dark mode.

| Role | Token (Cupertino) | Light value | Usage |
|---|---|---|---|
| Brand / tint | `systemBlue` | `#007AFF` | Primary buttons, active tab, links, progress |
| Success | `systemGreen` | `#34C759` | Confirmed, driver assigned, completed |
| Warning / attention | `systemOrange` | `#FF9500` | Matching, fare highlights, time-sensitive status |
| Danger | `systemRed` | `#FF3B30` | Cancel ride, destructive actions, errors |
| Page background | `systemBackground` | `#FFFFFF` (system) | Main canvas |
| Grouped surface | `systemGroupedBackground` | `#F2F2F7` (system) | History, Account, settings-style screens |
| Card / inset surface | `secondarySystemGroupedBackground` | `#FFFFFF` (system) | Grouped list cards |
| Muted surface | `tertiarySystemFill` | `rgba(118,118,128,0.12)` | Secondary buttons, chips, icon tiles |
| Primary text | `label` | `#000000` 85–100% (system) | Titles, body |
| Secondary text | `secondaryLabel` | (system) | Metadata, captions |
| Tertiary text | `tertiaryLabel` | (system) | Footnotes, placeholders |
| Separator | `separator` | (system) | Hairline dividers (0.5pt) |

Rules:

- One accent: `systemBlue`. Orange, green, red carry meaning only, never decoration.
- Status is never color alone — pair with icon or text label.
- Dark mode is a first-class requirement; semantic tokens make it automatic.

## Typography

- SF Pro system font via the platform (`CupertinoTheme` default). No custom display font.
- Dynamic Type is mandatory: support text scaling up to the largest accessibility sizes without clipped controls.
- Standard iOS text styles:

| Role | iOS style | Usage |
|---|---|---|
| Large title | 34pt / bold | Top of History, Account |
| Title | 17pt / semibold | Nav title, section headers |
| Body | 17pt / regular | List rows, descriptions |
| Callout | 16pt / regular | Secondary rows |
| Footnote | 13pt / regular | Metadata, timestamps |
| Caption | 12pt / regular | Hints, legal |

- Use tabular (monospaced) figures for fares and countdowns.
- Sentence case everywhere; no all-caps labels.

## Layout and shape

- 16pt screen margins; grouped lists use iOS inset-grouped style (margins + rounded 10pt cards).
- Rows: 44pt minimum height; grouped rows 44–60pt with hairline separators inset to the text.
- Hit targets: at least 44×44pt, with 8pt separation between adjacent targets.
- Primary CTA lives in the thumb zone: full-width 50pt filled button, radius 12pt (iOS "prominent filled").
- Corner radius scale: 10pt list cards / sheets, 12pt buttons, 8pt chips.
- Respect safe areas, home indicator, and keyboard always; bottom content insets for fixed CTA and tab bar.

## iOS component language

- **Navigation bar:** large title that collapses on scroll; trailing icons only. No custom headers.
- **Tab bar:** exactly Home, History, Account; SF-Symbols-style outline icons with labels; frosted background. Map is allowed only under Home/active ride.
- **Grouped lists (inset grouped):** the backbone of History and Account — sections with footers, not repeated cards.
- **Bottom sheet:** destination search and ride selection use a sheet with a grabber handle, detents (peek → full).
- **Search:** iOS-style search field at the top of Home sheet, with recents/saved results.
- **Alerts & action sheets:** destructive actions (cancel ride) use an action sheet with red button; errors use a clear alert with one recovery action.
- **Context menus / swipe actions:** long-press context menu on history rows; swipe for repeat-trip shortcut.
- **Push transitions:** standard iOS push/pop; sheets slide with the platform's spring.
- No Material ripples; presses highlight per iOS behavior.
- No emoji as structural icons — use Cupertino icon equivalents.

## Screen hierarchy

1. **Home:** map-first with a floating search sheet; saved/recent places reduce typing.
2. **Ride selection:** bottom sheet over the map; fare and ETA are the prominent numbers; confirm CTA in the sheet's thumb-zone position.
3. **Tracking:** full map with the route; compact glass chip with ETA above the driver card; Call/Message actions grouped in one inset list row.
4. **History:** inset-grouped list under a large title; no map, no sheet.
5. **Account:** inset-grouped settings-style page under a large title; profile row leads to detail.

## Motion

- Use iOS-native springs, not durations-as-choreography: sheets undock with the system spring; pushed screens use the standard transition.
- Micro-feedback: 100–150ms press highlight; segmented/sheet position changes ~250ms ease-in-out.
- Driver status may pulse gently; everything else is static.
- Honor Reduce Motion: show end states immediately, disable pulses.

## Content voice

- Short and reassuring, in Apple tone: "Finding your driver", "Pickup in 3 min".
- Buttons state results: "Confirm ride", "Cancel ride" (destructive, red).
- Errors say what happened and how to fix it: "We couldn't find that address. Try a nearby landmark."

## Accessibility baseline

- Dynamic Type without clipped major flows.
- VoiceOver: every control has a readable label; decorative elements are hidden.
- 44pt minimum targets; color never the sole signal; blur behind text passes contrast.
- Map-only interactions (pins, moving markers) have.list/table equivalents (search results, driver details card).
