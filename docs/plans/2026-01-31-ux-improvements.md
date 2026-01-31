# UX Improvements Plan - Navigation & Recurring Visibility

**Date:** January 31, 2026  
**Branch:** `feature/ux-improvements`  
**Status:** Planning

---

## 1. Overview

### Problems Identified
1. **Recurring expenses buried** - 3 taps deep in Settings
2. **No visibility** of upcoming recurring on home screen
3. **No conversion path** from expense to recurring
4. **Complex form** for adding recurring expenses

### Solutions Chosen
1. **Bottom Navigation Bar** - Home | Recurring | Settings
2. **Upcoming Recurring Card** on home screen
3. **"Make Recurring" button** in expense edit screen
4. **Smart Defaults** with collapsible advanced options

---

## 2. Bottom Navigation Bar

### Current Flow
```
HomeScreen (full screen)
└── AppBar: Settings icon → SettingsScreen
                           └── Recurring tile → RecurringListScreen
```

### New Flow
```
BottomNavigation
├── Home (index 0) - HomeScreen (expense dashboard)
├── Recurring (index 1) - RecurringListScreen (promoted)
└── Settings (index 2) - SettingsScreen (preferences only)
```

### Implementation

#### 2.1 Create Main Shell Widget

**File:** `lib/screens/main_shell.dart`

```dart
class MainShell extends StatefulWidget {
  final ExpenseService expenseService;
  final ThemeService themeService;
  final RecurringExpenseService recurringService;
  
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(...),
          RecurringListScreen(...),
          SettingsScreen(...),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
}
```

#### 2.2 Bottom Nav Design (Ledgerify Style)

```
┌─────────────────────────────────────┐
│                                     │
│          (Screen Content)           │
│                                     │
├─────────────────────────────────────┤
│   [Home]     [Recurring]   [Settings] │
│     ○            ○            ○      │
│   Active       3 due        ○       │
└─────────────────────────────────────┘
```

**Design Specs:**
- Background: `colors.surface`
- Height: 64dp + safe area
- Icons: Rounded Material Icons
  - Home: `Icons.home_rounded`
  - Recurring: `Icons.repeat_rounded`
  - Settings: `Icons.settings_rounded`
- Active: `colors.accent` icon + label
- Inactive: `colors.textTertiary` icon only
- Badge on Recurring: Show count of items due within 7 days
- No elevation, use subtle top border (`colors.divider`)

#### 2.3 Update main.dart

Change home from `HomeScreen` to `MainShell`:

```dart
runApp(LedgerifyApp(
  ...
  // home: HomeScreen(...),  // OLD
  home: MainShell(...),      // NEW
));
```

#### 2.4 Update HomeScreen

- Remove Settings icon from AppBar (now in bottom nav)
- Remove recurringService parameter (handled by shell)
- Keep FAB for adding expenses

#### 2.5 Update RecurringListScreen

- Remove back button (now a tab, not pushed screen)
- Keep FAB for adding recurring

#### 2.6 Update SettingsScreen

- Remove "Recurring Expenses" tile (now in bottom nav)
- Remove recurringService parameter
- Keep: Appearance, About sections

---

## 3. Upcoming Recurring Card on Home

### Design

```
┌─────────────────────────────────────┐
│  Upcoming                   View all │
├─────────────────────────────────────┤
│  [icon] Netflix            Tomorrow  │
│         ₹499                         │
│  ─────────────────────────────────  │
│  [icon] Rent               Feb 1     │
│         ₹15,000                      │
│  ─────────────────────────────────  │
│  [icon] Gym                Feb 3     │
│         ₹1,200                       │
└─────────────────────────────────────┘
```

**Placement:** Between Monthly Summary Card and Category Breakdown

**Behavior:**
- Shows next 3 upcoming recurring (within 14 days)
- "View all" navigates to Recurring tab
- Tap item opens edit screen
- Hidden if no upcoming items

### Implementation

**File:** `lib/widgets/upcoming_recurring_card.dart`

```dart
class UpcomingRecurringCard extends StatelessWidget {
  final RecurringExpenseService recurringService;
  final VoidCallback onViewAll;
  final Function(RecurringExpense) onTapItem;
  
  @override
  Widget build(BuildContext context) {
    final upcoming = recurringService.getUpcoming(days: 14).take(3).toList();
    
    if (upcoming.isEmpty) return SizedBox.shrink();
    
    return Container(
      // Card styling per design language
      child: Column(
        children: [
          // Header: "Upcoming" + "View all"
          // List of upcoming items
        ],
      ),
    );
  }
}
```

---

## 4. "Make Recurring" from Expense

### Design

In `AddExpenseScreen` (when editing an existing expense), add a button:

```
┌─────────────────────────────────────┐
│  ← Edit Expense                     │
├─────────────────────────────────────┤
│                                     │
│  Amount                             │
│  ┌─────────────────────────────┐    │
│  │  ₹ 499.00                   │    │
│  └─────────────────────────────┘    │
│                                     │
│  Category                           │
│  ┌─────────────────────────────┐    │
│  │  Entertainment            ▼ │    │
│  └─────────────────────────────┘    │
│                                     │
│  ... other fields ...               │
│                                     │
│  ┌─────────────────────────────┐    │
│  │  [repeat] Make this recurring │   │  <- NEW
│  └─────────────────────────────┘    │
│                                     │
├─────────────────────────────────────┤
│  [        Update Expense         ]  │
└─────────────────────────────────────┘
```

**Behavior:**
1. Tap "Make this recurring"
2. Navigate to AddRecurringScreen with pre-filled:
   - Title: merchant or category name
   - Amount: current expense amount
   - Category: current expense category
   - Start date: current expense date
   - Frequency: Monthly (default)
3. User completes the recurring form
4. Returns to expense screen (unchanged)

### Implementation

Add to `AddExpenseScreen` (edit mode only):

```dart
if (_isEditing) ...[
  SizedBox(height: LedgerifySpacing.xl),
  _buildMakeRecurringButton(colors),
],
```

```dart
Widget _buildMakeRecurringButton(LedgerifyColorScheme colors) {
  return OutlinedButton.icon(
    onPressed: _navigateToMakeRecurring,
    icon: Icon(Icons.repeat_rounded),
    label: Text('Make this recurring'),
    style: OutlinedButton.styleFrom(
      foregroundColor: colors.accent,
      side: BorderSide(color: colors.accent.withOpacity(0.5)),
      padding: EdgeInsets.all(LedgerifySpacing.lg),
    ),
  );
}

void _navigateToMakeRecurring() {
  Navigator.push(context, MaterialPageRoute(
    builder: (context) => AddRecurringScreen(
      recurringService: widget.recurringService,  // Need to add this param
      prefillFromExpense: widget.expenseToEdit,   // New parameter
    ),
  ));
}
```

---

## 5. Smart Defaults for Add Recurring

### Current Form (11 fields, all visible)

```
Title
Amount
Category
Frequency
[Weekday selector / Day picker / Interval] (conditional)
Start date
End date (optional)
Note (optional)
```

### Improved Form (Progressive Disclosure)

**Initial View (5 fields):**
```
Title
Amount
Category
Frequency [Monthly ▼]  <- Smart default
Start date [Today]     <- Smart default

[Show advanced options ▼]

[Add Recurring]
```

**Expanded View (when "Show advanced options" tapped):**
```
Title
Amount
Category
Frequency [Monthly ▼]
Start date [Today]

▲ Hide advanced options

[Frequency-specific options]  <- Only if needed
End date (optional)
Note (optional)

[Add Recurring]
```

### Smart Defaults

| Field | Default Value |
|-------|---------------|
| Frequency | Monthly |
| Start date | Today |
| Day of month | Same as start date |
| Custom interval | 7 (if custom selected) |
| End date | None |

### Implementation Changes

1. Add `_showAdvancedOptions` state variable (default: false)
2. Move these fields into collapsible section:
   - Frequency-specific options (weekdays, day-of-month, interval)
   - End date
   - Note
3. Auto-expand if editing existing item with advanced options set
4. Add "Show/Hide advanced options" toggle

---

## 6. Implementation Tasks

### Phase A: Bottom Navigation (High Priority)

| # | Task | Est. |
|---|------|------|
| A.1 | Create MainShell widget with bottom nav | 45m |
| A.2 | Design bottom nav bar (Ledgerify style) | 30m |
| A.3 | Update main.dart to use MainShell | 15m |
| A.4 | Update HomeScreen (remove settings icon) | 15m |
| A.5 | Update RecurringListScreen (remove back button) | 15m |
| A.6 | Update SettingsScreen (remove recurring tile) | 15m |
| A.7 | Add badge for due recurring count | 30m |
| A.8 | Test navigation flow | 20m |

**Phase A Total: ~3 hours**

### Phase B: Upcoming Card on Home (Medium Priority)

| # | Task | Est. |
|---|------|------|
| B.1 | Create UpcomingRecurringCard widget | 45m |
| B.2 | Create UpcomingRecurringTile (list item) | 30m |
| B.3 | Add card to HomeScreen | 15m |
| B.4 | Implement "View all" navigation to tab | 15m |
| B.5 | Test with various scenarios | 20m |

**Phase B Total: ~2 hours**

### Phase C: Make Recurring from Expense (Medium Priority)

| # | Task | Est. |
|---|------|------|
| C.1 | Add recurringService to AddExpenseScreen | 15m |
| C.2 | Add "Make this recurring" button (edit mode) | 20m |
| C.3 | Add prefillFromExpense to AddRecurringScreen | 30m |
| C.4 | Implement prefill logic | 20m |
| C.5 | Test conversion flow | 15m |

**Phase C Total: ~1.5 hours**

### Phase D: Smart Defaults (Lower Priority)

| # | Task | Est. |
|---|------|------|
| D.1 | Add _showAdvancedOptions state | 10m |
| D.2 | Create collapsible section widget | 30m |
| D.3 | Move advanced fields into section | 30m |
| D.4 | Set smart defaults | 15m |
| D.5 | Auto-expand for edit mode with advanced options | 15m |
| D.6 | Test form behavior | 15m |

**Phase D Total: ~2 hours**

---

## 7. Total Estimate

| Phase | Description | Time |
|-------|-------------|------|
| A | Bottom Navigation | 3h |
| B | Upcoming Card | 2h |
| C | Make Recurring | 1.5h |
| D | Smart Defaults | 2h |
| **Total** | | **~8.5 hours** |

---

## 8. Navigation Flow After Changes

### New Information Architecture

```
MainShell (BottomNavigationBar)
│
├── Tab 0: Home
│   ├── Monthly Summary Card
│   ├── Upcoming Recurring Card (NEW)
│   ├── Category Breakdown Card
│   └── Expense List
│       └── Tap → Edit Expense
│           └── "Make this recurring" (NEW) → Add Recurring
│   └── FAB → Add Expense
│
├── Tab 1: Recurring (PROMOTED)
│   ├── Active Section
│   ├── Paused Section
│   └── Ended Section
│   └── FAB → Add Recurring
│
└── Tab 2: Settings (SIMPLIFIED)
    ├── Appearance
    │   └── Theme picker
    └── About
        └── Version
```

### User Journey Improvements

| Task | Before | After |
|------|--------|-------|
| Add expense | 1 tap | 1 tap (same) |
| Add recurring | 4 taps | 2 taps |
| View recurring list | 2 taps | 1 tap |
| See upcoming recurring | N/A | 0 taps (on home) |
| Convert expense to recurring | N/A | 2 taps |

---

## 9. Visual Mockup: Bottom Navigation

```
Dark Theme:
┌─────────────────────────────────────┐
│ #121212 background                  │
│                                     │
│         (Screen Content)            │
│                                     │
├─────────────────────────────────────┤
│ #1E1E1E surface                     │
│                                     │
│   🏠          🔁           ⚙️       │
│  Home     Recurring    Settings     │
│ #A8E6CF   #808080      #808080      │
│ (active)  (3 badge)                 │
│                                     │
└─────────────────────────────────────┘

Light Theme:
┌─────────────────────────────────────┐
│ #F5F5F3 background                  │
│                                     │
│         (Screen Content)            │
│                                     │
├─────────────────────────────────────┤
│ #FFFFFF surface                     │
│                                     │
│   🏠          🔁           ⚙️       │
│  Home     Recurring    Settings     │
│ #2E9E6B   #808080      #808080      │
│ (active)  (3 badge)                 │
│                                     │
└─────────────────────────────────────┘
```

---

## 10. Acceptance Criteria

### Must Have
- [ ] Bottom navigation with 3 tabs: Home, Recurring, Settings
- [ ] Recurring tab shows full list (same as current RecurringListScreen)
- [ ] Settings no longer has "Recurring Expenses" tile
- [ ] Navigation state preserved when switching tabs
- [ ] FABs work correctly on each tab
- [ ] Theme applies correctly to bottom nav

### Should Have
- [ ] Upcoming Recurring Card on home screen
- [ ] "Make this recurring" button in expense edit mode
- [ ] Badge on Recurring tab showing due count

### Nice to Have
- [ ] Smart defaults with collapsible advanced options
- [ ] Smooth tab transitions
- [ ] Remember last selected tab across app restarts

---

*Plan created: January 31, 2026*
*Author: Claude Code*
