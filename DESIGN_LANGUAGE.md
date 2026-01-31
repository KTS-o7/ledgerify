# Ledgerify Design Language

> **Quiet Finance** — A calm, premium personal finance experience.

---

## Philosophy

Ledgerify is *quiet finance*. It avoids loud colors, hype, or gamification. The UI should feel trustworthy, weighty, and calming—like a well-crafted physical object. The user should feel **in control**, not stimulated.

**Core Principles:**
1. **Clarity over decoration** — Every element serves a purpose
2. **Calm over excitement** — No hype, no gamification
3. **Trust over engagement** — Build confidence, not addiction
4. **Restraint over expression** — Quiet confidence in every detail

---

## Color System

### Base Palette

| Token | Name | Hex | RGB | Usage |
|-------|------|-----|-----|-------|
| `background` | Deep Charcoal | `#121212` | `18, 18, 18` | Primary app background |
| `surface` | Charcoal | `#1E1E1E` | `30, 30, 30` | Cards, containers |
| `surfaceElevated` | Soft Charcoal | `#252525` | `37, 37, 37` | Elevated cards, modals |
| `surfaceHighlight` | Ash | `#2C2C2C` | `44, 44, 44` | Hover states, selection |

### Text Colors

| Token | Name | Hex | Opacity | Usage |
|-------|------|-----|---------|-------|
| `textPrimary` | White | `#FFFFFF` | 100% | Headlines, amounts, key data |
| `textSecondary` | White | `#FFFFFF` | 70% | Labels, descriptions |
| `textTertiary` | White | `#FFFFFF` | 50% | Metadata, timestamps, hints |
| `textDisabled` | White | `#FFFFFF` | 30% | Disabled states |

### Semantic Colors

| Token | Name | Hex | RGB | Usage |
|-------|------|-----|-----|-------|
| `accent` | Pistachio | `#A8E6CF` | `168, 230, 207` | Primary actions, positive values |
| `accentMuted` | Soft Pistachio | `#A8E6CF` @ 15% | — | Accent backgrounds, badges |
| `negative` | Soft Coral | `#FF6B6B` | `255, 107, 107` | Negative values only |
| `negativeMuted` | Soft Coral | `#FF6B6B` @ 15% | — | Negative backgrounds |
| `warning` | Amber | `#FFB347` | `255, 179, 71` | Warnings (use sparingly) |

### Color Rules

```
DO:
✓ Use accent (pistachio) for positive values, progress, primary CTAs
✓ Use negative (coral) only for negative deltas and amounts
✓ Reduce opacity before introducing new colors
✓ Keep surfaces in the charcoal family

DON'T:
✗ Use pure black (#000000) — always use deep charcoal
✗ Use bright blues, purples, or decorative gradients
✗ Use accent color for non-semantic decoration
✗ Use high-contrast borders — prefer elevation
```

---

## Typography

### Font Family

**Primary:** `Inter` (or system default: SF Pro on iOS, Roboto on Android)

Inter is preferred for its:
- Excellent number legibility
- Neutral, professional tone
- Wide weight range

### Type Scale

| Token | Size | Weight | Line Height | Letter Spacing | Usage |
|-------|------|--------|-------------|----------------|-------|
| `displayLarge` | 48sp | 700 | 1.1 | -0.02em | Hero amounts (₹1,23,456) |
| `displayMedium` | 36sp | 700 | 1.15 | -0.01em | Section totals |
| `displaySmall` | 28sp | 600 | 1.2 | -0.01em | Card headlines |
| `headlineLarge` | 24sp | 600 | 1.25 | 0 | Screen titles |
| `headlineMedium` | 20sp | 600 | 1.3 | 0 | Card titles |
| `headlineSmall` | 18sp | 600 | 1.35 | 0 | Subsection titles |
| `bodyLarge` | 16sp | 400 | 1.5 | 0 | Primary body text |
| `bodyMedium` | 14sp | 400 | 1.5 | 0.01em | Secondary text, descriptions |
| `bodySmall` | 12sp | 400 | 1.5 | 0.02em | Captions, metadata |
| `labelLarge` | 14sp | 500 | 1.4 | 0.02em | Button labels |
| `labelMedium` | 12sp | 500 | 1.4 | 0.03em | Tabs, chips |
| `labelSmall` | 10sp | 500 | 1.4 | 0.04em | Badges, tiny labels |

### Typography Rules

```
DO:
✓ Numbers dominate — they are the visual anchors
✓ Labels whisper — lower contrast, smaller size
✓ Reduce opacity before reducing font size
✓ Use tabular figures for amounts (monospace numbers)

DON'T:
✗ Make labels compete with numbers visually
✗ Use more than 3 type sizes on one card
✗ Use italics or decorative fonts
```

### Number Formatting

- Use **Indian numbering system**: ₹1,23,456.00
- Always show 2 decimal places for amounts
- Use `+` and `−` (minus sign, not hyphen) for deltas
- Positive deltas: `+12.5%` in accent color
- Negative deltas: `−8.3%` in negative color

---

## Spacing System

### Base Unit

**Base unit: 4dp**

All spacing should be multiples of 4dp for consistency.

| Token | Value | Usage |
|-------|-------|-------|
| `space-xs` | 4dp | Tight gaps, icon padding |
| `space-sm` | 8dp | Related element gaps |
| `space-md` | 12dp | Intra-card spacing |
| `space-lg` | 16dp | Card padding, section gaps |
| `space-xl` | 24dp | Between cards |
| `space-2xl` | 32dp | Section separators |
| `space-3xl` | 48dp | Major section breaks |

### Screen Margins

- **Horizontal padding:** 16dp (both sides)
- **Top safe area:** respect system + 16dp
- **Bottom safe area:** respect system + 16dp (for nav bar)

---

## Elevation & Depth

### Philosophy

Use **soft elevation and depth** instead of visible borders. Surfaces should feel like they float at different levels.

### Elevation Levels

| Level | Usage | Shadow |
|-------|-------|--------|
| 0 | Background | None |
| 1 | Cards, containers | `0 2dp 8dp rgba(0,0,0,0.3)` |
| 2 | Elevated cards, dialogs | `0 4dp 16dp rgba(0,0,0,0.4)` |
| 3 | Modals, bottom sheets | `0 8dp 24dp rgba(0,0,0,0.5)` |

### Surface Differentiation

Instead of borders, differentiate surfaces by:
1. **Background color shift** (surface vs surfaceElevated)
2. **Subtle shadow**
3. **Spacing** (whitespace separation)

```
DO:
✓ Use elevation to create hierarchy
✓ Keep shadows soft and diffused
✓ Use color shift between surface levels

DON'T:
✗ Use visible borders or outlines
✗ Use hard, sharp shadows
✗ Mix border and elevation approaches
```

---

## Border Radius

### Radius Scale

| Token | Value | Usage |
|-------|-------|-------|
| `radius-sm` | 8dp | Small chips, badges |
| `radius-md` | 12dp | Buttons, input fields |
| `radius-lg` | 16dp | Cards, containers |
| `radius-xl` | 24dp | Large cards, bottom sheets |
| `radius-full` | 9999dp | Circular elements, pills |

### Rules

- **Cards:** Always use `radius-lg` (16dp)
- **Buttons:** Use `radius-md` (12dp) for standard, `radius-full` for pills
- **Consistency:** All corners of an element should have the same radius

---

## Components

### Cards

Cards are the primary container for content.

```
Structure:
┌─────────────────────────────────────┐
│  padding: 16dp                      │
│  ┌─────────────────────────────┐    │
│  │  Card Content               │    │
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘

Properties:
- Background: surface (#1E1E1E)
- Border radius: 16dp
- Padding: 16dp
- Shadow: level 1
- No borders
```

### Buttons

#### Primary Button (Full Width)

```
Properties:
- Background: accent (#A8E6CF)
- Text: background (#121212)
- Height: 56dp
- Border radius: 12dp
- Font: labelLarge, weight 600
- Full width with 16dp margin

States:
- Default: accent background
- Pressed: accent @ 80%
- Disabled: surface with textDisabled
```

#### Secondary Button

```
Properties:
- Background: transparent
- Border: 1dp accent @ 50%
- Text: accent
- Height: 48dp
- Border radius: 12dp
```

#### Text Button

```
Properties:
- Background: transparent
- Text: accent
- No border
- Padding: 12dp horizontal
```

### Input Fields

```
Properties:
- Background: surfaceHighlight (#2C2C2C)
- Text: textPrimary
- Placeholder: textTertiary
- Height: 56dp
- Border radius: 12dp
- Padding: 16dp horizontal
- No border in default state
- Accent border on focus (1dp)

Label:
- Position: above field
- Style: bodySmall, textSecondary
- Margin bottom: 8dp
```

### List Items

```
Properties:
- Background: transparent (inherits card)
- Padding: 16dp vertical, 0 horizontal
- Divider: surfaceHighlight, 1dp, inset 16dp

Content:
- Leading: icon or avatar (40dp)
- Title: bodyLarge, textPrimary
- Subtitle: bodySmall, textTertiary
- Trailing: amount or action
```

### Bottom Navigation

```
Properties:
- Background: surface (#1E1E1E)
- Height: 64dp + safe area
- Items: 3-5 max

Item States:
- Inactive: textTertiary icon
- Active: accent icon with pill background (accentMuted)
- No labels or minimal labels
```

---

## Icons

### Style

- **Family:** Rounded, solid icons (Material Symbols Rounded or SF Symbols)
- **Weight:** 400 (regular)
- **Size:** 24dp standard, 20dp compact
- **Optical size:** Match to display size

### Usage

| Context | Size | Color |
|---------|------|-------|
| Navigation | 24dp | textTertiary (inactive), accent (active) |
| List items | 24dp | textSecondary |
| Actions | 24dp | accent |
| Inline with text | 20dp | inherit text color |

### Rules

```
DO:
✓ Use icons to support navigation and actions
✓ Keep icons simple and recognizable
✓ Maintain consistent stroke weight

DON'T:
✗ Use icons as decoration
✗ Use outlined icons (prefer solid/filled)
✗ Use colorful or multi-color icons
```

---

## Data Visualization

### Philosophy

Charts communicate **direction and trends**, not precision. Keep them simple and supportive.

### Chart Styling

```
Properties:
- Primary line/bar: accent (#A8E6CF)
- Secondary line/bar: textTertiary
- Negative bars: negative (#FF6B6B)
- Background: transparent
- No gridlines
- No heavy axes
- Minimal or no labels inside chart

Shape:
- Soft, rounded bar ends (radius-sm)
- Smooth curves for line charts
- No sharp corners
```

### Indicators

| Element | Style |
|---------|-------|
| Positive delta | `+12.5%` in accent |
| Negative delta | `−8.3%` in negative |
| Neutral | `0%` in textSecondary |
| Progress | Accent bar on surface track |
| Badges | Small pill, accentMuted background |

### Rules

```
DO:
✓ Show direction and trends clearly
✓ Use subtle shapes: soft bars, waves
✓ Keep precision in numbers, not charts

DON'T:
✗ Add gridlines or heavy axes
✗ Use 3D effects or gradients
✗ Overcrowd with data points
```

---

## Motion & Animation

### Philosophy

Motion should be **calm and predictable**. It reassures rather than entertains.

### Timing

| Type | Duration | Curve |
|------|----------|-------|
| Micro (buttons, toggles) | 100-150ms | ease-out |
| Small (cards, reveals) | 200-250ms | ease-in-out |
| Medium (page transitions) | 300-350ms | ease-in-out |
| Large (modals, sheets) | 350-400ms | ease-in-out |

### Easing Curves

```dart
// Standard easing - use for most transitions
Curves.easeInOut

// Decelerate - use for elements entering
Curves.easeOut

// Accelerate - use for elements leaving
Curves.easeIn

// NEVER use:
// - Curves.bounceOut
// - Curves.elasticOut
// - Any spring/playful animations
```

### Transition Patterns

| Action | Animation |
|--------|-----------|
| Screen push | Slide from right, 300ms |
| Screen pop | Slide to right, 300ms |
| Modal open | Slide from bottom + fade, 350ms |
| Modal close | Slide to bottom + fade, 300ms |
| Card expand | Scale + fade, 250ms |
| List item | Stagger fade-in, 50ms delay each |

### Rules

```
DO:
✓ Use slow-in, slow-out easing
✓ Keep animations subtle and purposeful
✓ Maintain consistent timing across similar actions

DON'T:
✗ Use bounce or spring effects
✗ Add playful or decorative animations
✗ Make animations too fast or too slow
✗ Animate multiple properties unnecessarily
```

---

## Layout Principles

### Screen Structure

```
┌─────────────────────────────────────┐
│  Status Bar (system)                │
├─────────────────────────────────────┤
│  App Bar (optional)                 │
│  - Title left-aligned              │
│  - Actions right-aligned           │
├─────────────────────────────────────┤
│                                     │
│  Content Area                       │
│  ┌─────────────────────────────┐    │
│  │  Summary Card               │    │
│  │  (Hero numbers, totals)     │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │  Trends / Insights          │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │  Actions / List             │    │
│  └─────────────────────────────┘    │
│                                     │
├─────────────────────────────────────┤
│  Primary Action (if needed)         │
│  Full-width button, 16dp margin    │
├─────────────────────────────────────┤
│  Bottom Navigation                  │
│  Safe area                          │
└─────────────────────────────────────┘
```

### Vertical Flow

1. **Summary** — Hero numbers, current state
2. **Trends** — Charts, comparisons, insights  
3. **Actions** — Lists, buttons, forms

### Card Architecture

- Group related content in cards
- One card = one concept
- Cards stack vertically with `space-xl` (24dp) gaps
- Never nest cards inside cards

### Action Placement

- **One primary action per screen**
- Primary action: full-width, bottom of content or fixed
- Secondary actions: text buttons or icon buttons
- Destructive actions: require confirmation

---

## Microcopy & Tone

### Voice

- **Neutral** — No excitement, no alarm
- **Reassuring** — Build confidence
- **Professional** — Respect the user's intelligence
- **Concise** — Say less, mean more

### Examples

| Instead of... | Use... |
|---------------|--------|
| "Awesome! You saved money!" | "On track this month" |
| "Oops! You overspent!" | "Over budget by ₹2,340" |
| "Let's add an expense!" | "Add expense" |
| "Your amazing savings goal" | "Savings goal" |
| "Tap here to see more" | "View details" |

### Labels

- Use sentence case (not Title Case)
- Keep labels short (1-3 words)
- Avoid redundancy ("Add new expense" → "Add expense")

### Empty States

```
Tone: Helpful, not sad or cute

Example:
Title: "No expenses yet"
Body: "Add your first expense to start tracking"
Action: "Add expense"

NOT:
"It's lonely here! 😢 Add some expenses to get started!"
```

### Error Messages

```
Tone: Clear, actionable, not alarming

Example:
"Couldn't save. Check your connection and try again."

NOT:
"Error 500: Internal server error"
"Oops! Something went wrong! 😅"
```

---

## Constraints & Don'ts

### Never Do

1. **Pure black backgrounds** — Always use deep charcoal (#121212)
2. **Visible borders** — Use elevation and color instead
3. **Bright/loud colors** — No bright blues, purples, oranges
4. **Gradients** — Keep surfaces flat
5. **Decorative elements** — Every element must have meaning
6. **Gamification** — No streaks, badges, or rewards
7. **Playful animations** — No bounce, wiggle, or spring
8. **Hype language** — No "Amazing!", "Awesome!", "Great job!"
9. **Emoji in UI** — Keep it professional (exception: category icons if user-set)
10. **High-contrast outlines** — Prefer subtle differentiation

### Always Do

1. **Prioritize numbers** — They are the main content
2. **Use whitespace generously** — Let content breathe
3. **Maintain consistency** — Same patterns everywhere
4. **Support dark mode** — It's the primary theme
5. **Respect system UI** — Safe areas, status bar
6. **Test contrast** — Ensure accessibility (4.5:1 minimum)
7. **Design for thumb reach** — Primary actions within reach

---

## Accessibility

### Color Contrast

| Element | Minimum Ratio |
|---------|---------------|
| Body text | 4.5:1 |
| Large text (24sp+) | 3:1 |
| UI components | 3:1 |
| Decorative | No requirement |

### Touch Targets

- Minimum touch target: **48dp × 48dp**
- Recommended: **56dp** for primary actions
- Spacing between targets: **8dp minimum**

### Screen Reader

- All interactive elements must have labels
- Images must have descriptions (or be decorative)
- Logical reading order
- Announce dynamic content changes

---

## Flutter Implementation

### Theme Configuration

```dart
// colors.dart
class LedgerifyColors {
  // Base
  static const background = Color(0xFF121212);
  static const surface = Color(0xFF1E1E1E);
  static const surfaceElevated = Color(0xFF252525);
  static const surfaceHighlight = Color(0xFF2C2C2C);
  
  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xB3FFFFFF); // 70%
  static const textTertiary = Color(0x80FFFFFF);  // 50%
  static const textDisabled = Color(0x4DFFFFFF);  // 30%
  
  // Semantic
  static const accent = Color(0xFFA8E6CF);
  static const accentMuted = Color(0x26A8E6CF);  // 15%
  static const negative = Color(0xFFFF6B6B);
  static const negativeMuted = Color(0x26FF6B6B); // 15%
  static const warning = Color(0xFFFFB347);
}
```

### Spacing

```dart
// spacing.dart
class LedgerifySpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}
```

### Border Radius

```dart
// radius.dart
class LedgerifyRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 9999;
}
```

---

## Summary

Ledgerify's design language creates a **refined financial instrument**—quiet, intentional, and confidence-building. Every decision should ask:

> "Does this make the user feel calm and in control?"

If not, simplify. Remove. Restrain.

**Remember:** Ledgerify is not trying to engage, entertain, or excite. It's trying to **inform, support, and reassure**.

---

*Last updated: January 2026*
*Version: 1.0*
