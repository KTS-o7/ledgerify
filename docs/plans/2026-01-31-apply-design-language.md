# Design: Apply Ledgerify Design Language

**Date:** 2026-01-31  
**Status:** Ready for implementation

---

## Overview

Full redesign of all existing screens and components to match the Ledgerify Design Language. This transforms the app from the default Material look to the "Quiet Finance" aesthetic—dark, calm, premium.

## Scope

### Files to modify:
- `lib/main.dart` - Theme integration
- `lib/screens/home_screen.dart` - Main screen
- `lib/screens/add_expense_screen.dart` - Expense form
- `lib/widgets/expense_list_tile.dart` - List item
- `lib/widgets/monthly_summary_card.dart` - Summary display
- `lib/widgets/category_breakdown_card.dart` - Category breakdown
- `lib/models/expense.dart` - Update category icons

### Design tokens to use:
- `LedgerifyColors` - All colors
- `LedgerifyTypography` - All text styles
- `LedgerifySpacing` - All spacing
- `LedgerifyRadius` - All border radii
- `LedgerifyTheme.darkTheme` - App theme

---

## 1. App Shell (main.dart)

### Changes:
- Apply `LedgerifyTheme.darkTheme` as only theme
- Set `themeMode: ThemeMode.dark`
- Remove current color scheme
- Keep `ExpenseService` initialization

### System UI:
- Status bar: transparent, light icons
- Navigation bar: `LedgerifyColors.background`

---

## 2. Home Screen

### Structure:
```
AppBar (transparent, title left)
  ↓
MonthlySummaryCard
  ↓ (24dp gap)
CategoryBreakdownCard
  ↓ (24dp gap)
Expense List (grouped by date)
  ↓
FAB (bottom-right)
```

### AppBar:
- Title: "Ledgerify" (`headlineMedium`)
- Background: transparent
- No elevation

### Empty State:
- Icon: `Icons.receipt_long_outlined` (80dp, `textTertiary`)
- Title: "No expenses yet" (`headlineSmall`, `textSecondary`)
- Body: "Add your first expense to start tracking" (`bodyMedium`, `textTertiary`)
- Centered vertically

### FAB:
- Extended: icon + "Add Expense"
- Background: `accent`
- Foreground: `background`
- Radius: 12dp

### Spacing:
- Horizontal padding: 16dp
- Card gaps: 24dp
- List bottom padding: 88dp

---

## 3. Monthly Summary Card

### Visual:
```
┌───────────────────────────────┐
│      ←  January 2026  →       │  (tertiary, arrows subtle)
│                               │
│        ₹1,23,456.00           │  (displayLarge/amountHero)
│                               │
│         12 expenses           │  (bodySmall, tertiary)
└───────────────────────────────┘
```

### Specs:
- Background: `surface`
- Radius: 16dp
- Padding: 24dp
- No gradient, no shadow
- Amount: `LedgerifyTypography.amountHero`
- Month label: `bodyMedium`, `textTertiary`
- Expense count: `bodySmall`, `textTertiary`
- Arrows: `IconButton`, `textTertiary`, disabled at 30% opacity

---

## 4. Category Breakdown Card

### Visual (collapsed):
```
┌───────────────────────────────┐
│  ◉ Category Breakdown      ▼  │
└───────────────────────────────┘
```

### Visual (expanded):
```
┌───────────────────────────────┐
│  ◉ Category Breakdown      ▲  │
│                               │
│  🍽  Food & Dining    ₹45,000 │
│  ━━━━━━━━━━━━━━━━━━━━    45%  │
│                               │
│  🚗  Transport        ₹30,000 │
│  ━━━━━━━━━━━━━━━━        30%  │
└───────────────────────────────┘
```

### Specs:
- Background: `surface`
- Radius: 16dp
- Padding: 16dp
- Default: collapsed
- Animation: `AnimatedCrossFade`, 200ms, ease-in-out

### Category Row:
- Icon: Material icon, 24dp, `textSecondary`
- Name: `bodyLarge`, `textPrimary`
- Amount: `amountSmall`
- Percentage: `bodySmall`, `textTertiary`
- Progress bar: 4dp height, `accent` on `surfaceHighlight`, rounded ends

### Category Icons:
| Category | Icon |
|----------|------|
| Food | `Icons.restaurant_rounded` |
| Transport | `Icons.directions_car_rounded` |
| Shopping | `Icons.shopping_bag_rounded` |
| Entertainment | `Icons.movie_rounded` |
| Bills | `Icons.receipt_rounded` |
| Health | `Icons.medical_services_rounded` |
| Education | `Icons.school_rounded` |
| Other | `Icons.more_horiz_rounded` |

---

## 5. Expense List Tile

### Visual:
```
┌─────────────────────────────────────────┐
│  ┌────┐                                 │
│  │ 🍽 │  Food & Dining      ₹1,234.00  │
│  │    │  Lunch at cafe         Today   │
│  └────┘                                 │
└─────────────────────────────────────────┘
```

### Specs:
- Background: transparent
- Padding: 16dp horizontal, 12dp vertical
- Icon container: 44dp × 44dp, `surfaceHighlight`, 12dp radius
- Icon: 24dp, `textSecondary`
- Category: `bodyLarge`, `textPrimary`
- Amount: `amountMedium`, right-aligned
- Note: `bodySmall`, `textTertiary`, 1 line max
- Date: `bodySmall`, `textTertiary`

### Swipe to delete:
- Direction: end-to-start
- Background: `negative`
- Icon: `Icons.delete_rounded`, white

### Date Headers:
- Style: `labelMedium`, `textTertiary`
- Padding: 16dp horizontal, 16dp top, 8dp bottom
- Format: "Today", "Yesterday", weekday name, or "25 Jan 2026"

---

## 6. Add Expense Screen

### Structure:
```
AppBar ("Add Expense" / "Edit Expense")
  ↓
Amount Field (with ₹ prefix)
  ↓ (24dp)
Category Dropdown
  ↓ (24dp)
Date Picker
  ↓ (24dp)
Note Field (optional, 3 lines)
  ↓ (flex spacer)
Primary Button ("Add Expense" / "Update Expense")
  ↓ (16dp + safe area)
```

### Field Styling:
- Labels: `labelMedium`, `textSecondary`, 8dp above field
- Input background: `surfaceHighlight`
- Input radius: 12dp
- Focus: 1dp `accent` border
- Error: 1dp `negative` border

### Amount Field:
- Prefix: "₹ " in field
- Style: `amountLarge` (28sp)
- Keyboard: numeric with decimal
- Validation: required, > 0

### Category Dropdown:
- Shows icon + name
- Menu background: `surfaceElevated`
- Menu radius: 12dp

### Date Field:
- Display: "31 Jan 2026"
- Trailing icon: `Icons.calendar_today`
- Tap: opens date picker
- Max date: today

### Note Field:
- Placeholder: "Add a note..."
- Max lines: 3
- Max length: 200 chars
- Optional

### Primary Button:
- Full width
- Height: 56dp
- Background: `accent`
- Text: `background`
- Radius: 12dp
- Disabled when invalid (30% opacity)

---

## Implementation Order

1. **main.dart** - Apply theme
2. **expense.dart** - Add icon getter to category enum
3. **monthly_summary_card.dart** - Redesign
4. **category_breakdown_card.dart** - Redesign
5. **expense_list_tile.dart** - Redesign
6. **home_screen.dart** - Integrate redesigned widgets
7. **add_expense_screen.dart** - Redesign

---

## Testing Checklist

- [ ] App launches with dark theme
- [ ] Monthly summary displays correctly
- [ ] Month navigation works
- [ ] Category breakdown expands/collapses
- [ ] Expense list renders with date grouping
- [ ] Swipe to delete works
- [ ] Empty state displays correctly
- [ ] Add expense form validates
- [ ] Edit expense pre-fills data
- [ ] All colors match design tokens
- [ ] All typography matches design tokens
- [ ] All spacing matches design tokens
