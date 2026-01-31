# Recurring Expenses Feature - Implementation Plan

**Date:** January 31, 2026  
**Branch:** `feature/recurring-expenses`  
**Status:** Planning

---

## 1. Overview

### Problem Statement
Users have regular expenses (rent, subscriptions, bills) that occur on predictable schedules. Currently, they must manually add these every time, which is tedious and error-prone.

### Solution
Implement a recurring expense system that:
- Allows users to define expense templates with recurrence patterns
- Automatically generates actual expense entries when due
- Supports pause/resume and editing of recurring items
- Provides visibility into upcoming expenses

### Design Philosophy
Following Ledgerify's "Quiet Finance" principles:
- No gamification or streaks for "consistent tracking"
- Neutral language ("Recurring" not "Autopilot" or "Smart Expenses")
- Simple, predictable behavior
- User remains in control (can pause, edit, delete anytime)

---

## 2. Data Model

### 2.1 RecurrenceFrequency Enum

```dart
@HiveType(typeId: 3)
enum RecurrenceFrequency {
  @HiveField(0)
  daily,      // Every day
  
  @HiveField(1)
  weekly,     // Every week (same weekday)
  
  @HiveField(2)
  monthly,    // Every month (same day of month)
  
  @HiveField(3)
  yearly,     // Every year (same date)
  
  @HiveField(4)
  custom,     // Every N days (uses customIntervalDays)
}
```

**Extension methods:**
- `displayName` - "Daily", "Weekly", "Monthly", "Yearly", "Custom"
- `icon` - Material icon for each frequency

### 2.2 RecurringExpense Model

```dart
@HiveType(typeId: 4)
class RecurringExpense extends HiveObject {
  @HiveField(0)
  final String id;                          // UUID
  
  @HiveField(1)
  final String title;                       // e.g., "Netflix", "Rent"
  
  @HiveField(2)
  final double amount;                      // Expense amount
  
  @HiveField(3)
  final ExpenseCategory category;           // Reuse existing enum
  
  @HiveField(4)
  final RecurrenceFrequency frequency;      // How often
  
  @HiveField(5)
  final int customIntervalDays;             // For custom: every N days (default: 1)
  
  @HiveField(6)
  final List<int>? weekdays;                // For weekly: specific days [1-7] (Mon=1, Sun=7)
                                            // null = same weekday as startDate
  
  @HiveField(7)
  final int? dayOfMonth;                    // For monthly: specific day (1-31)
                                            // null = same day as startDate
                                            // 32 = last day of month
  
  @HiveField(8)
  final DateTime startDate;                 // When recurrence begins
  
  @HiveField(9)
  final DateTime? endDate;                  // Optional: when recurrence ends
  
  @HiveField(10)
  final DateTime? lastGeneratedDate;        // Last date an expense was generated
  
  @HiveField(11)
  final DateTime nextDueDate;               // Calculated: next expense date
  
  @HiveField(12)
  final bool isActive;                      // Can be paused
  
  @HiveField(13)
  final String? note;                       // Optional note for generated expenses
  
  @HiveField(14)
  final DateTime createdAt;                 // When this recurring item was created
}
```

**Key Design Decisions:**

1. **`customIntervalDays`** - Only used when `frequency == custom`. Allows "every 3 days", "every 14 days", etc.

2. **`weekdays`** - List allows multiple days per week (e.g., gym membership Mon/Wed/Fri). Values 1-7 where Monday=1, Sunday=7 (ISO standard).

3. **`dayOfMonth`** - Handles edge cases:
   - `null`: Use same day as startDate
   - `1-28`: Specific day (safe for all months)
   - `29-31`: Will use last day if month is shorter
   - `32`: Special value meaning "last day of month"

4. **`nextDueDate`** - Pre-calculated for efficient querying. Updated after each generation.

5. **`lastGeneratedDate`** - Prevents duplicate generation. If app opens multiple times on same day, only generates once.

### 2.3 Relationship to Expense

Generated expenses will have:
- `source: ExpenseSource.recurring` (new enum value)
- `note`: Include recurring title, e.g., "[Netflix] Monthly subscription"
- `merchant`: Set to recurring expense title

**Update ExpenseSource enum:**
```dart
@HiveType(typeId: 1)
enum ExpenseSource {
  @HiveField(0)
  manual,
  
  @HiveField(1)
  sms,
  
  @HiveField(2)
  recurring,  // NEW
}
```

---

## 3. Service Layer

### 3.1 RecurringExpenseService

**File:** `lib/services/recurring_expense_service.dart`

```dart
class RecurringExpenseService {
  static const String _boxName = 'recurring_expenses';
  late Box<RecurringExpense> _box;
  
  // Initialization
  Future<void> init();
  
  // CRUD Operations
  Future<RecurringExpense> add({...});
  Future<RecurringExpense> update(RecurringExpense item);
  Future<void> delete(String id);
  RecurringExpense? get(String id);
  List<RecurringExpense> getAll();
  
  // Filtering
  List<RecurringExpense> getActive();
  List<RecurringExpense> getPaused();
  List<RecurringExpense> getUpcoming({int days = 7});
  
  // State Management
  Future<void> pause(String id);
  Future<void> resume(String id);
  
  // Generation
  Future<List<Expense>> generateDueExpenses(ExpenseService expenseService);
  
  // Calculation
  DateTime calculateNextDueDate(RecurringExpense item, {DateTime? from});
  
  // Listenable for UI
  Box<RecurringExpense> get box;
}
```

### 3.2 Generation Logic

**`generateDueExpenses()` Algorithm:**

```
1. Get all active recurring expenses
2. For each recurring expense:
   a. If endDate is set and endDate < today, skip (expired)
   b. If nextDueDate > today, skip (not due yet)
   c. If lastGeneratedDate == today, skip (already generated today)
   d. Generate expense(s) for all due dates between lastGeneratedDate and today
   e. Update lastGeneratedDate and nextDueDate
3. Return list of generated expenses (for optional UI feedback)
```

**Edge Cases:**
- App not opened for 2 weeks → generates all missed expenses
- Monthly on 31st, current month has 30 days → use 30th
- Recurring ended while app was closed → don't generate past endDate
- User changes system date backward → lastGeneratedDate prevents duplicates

### 3.3 Next Due Date Calculation

```dart
DateTime calculateNextDueDate(RecurringExpense item, {DateTime? from}) {
  final baseDate = from ?? item.lastGeneratedDate ?? item.startDate;
  
  switch (item.frequency) {
    case RecurrenceFrequency.daily:
      return baseDate.add(Duration(days: 1));
      
    case RecurrenceFrequency.weekly:
      if (item.weekdays != null && item.weekdays!.isNotEmpty) {
        // Find next weekday in list
        return _findNextWeekday(baseDate, item.weekdays!);
      }
      return baseDate.add(Duration(days: 7));
      
    case RecurrenceFrequency.monthly:
      return _addMonths(baseDate, 1, item.dayOfMonth);
      
    case RecurrenceFrequency.yearly:
      return _addYears(baseDate, 1);
      
    case RecurrenceFrequency.custom:
      return baseDate.add(Duration(days: item.customIntervalDays));
  }
}
```

---

## 4. UI Components

### 4.1 Screens

#### 4.1.1 Recurring Expenses List Screen

**File:** `lib/screens/recurring_list_screen.dart`

**Layout:**
```
┌─────────────────────────────────────┐
│  ← Recurring Expenses        [+ Add]│  AppBar
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐    │
│  │  [icon] Netflix             │    │  Active Section
│  │  ₹499 · Monthly · Due Jan 5 │    │
│  │                      [pause]│    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │  [icon] Rent                │    │
│  │  ₹15,000 · Monthly · Due 1st│    │
│  │                      [pause]│    │
│  └─────────────────────────────┘    │
│                                     │
│  ── Paused ──────────────────────   │  Paused Section (if any)
│                                     │
│  ┌─────────────────────────────┐    │
│  │  [icon] Gym (paused)        │    │
│  │  ₹1,200 · Monthly           │    │
│  │                     [resume]│    │
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

**Interactions:**
- Tap item → Edit screen
- Swipe left → Delete (with confirmation)
- Tap pause/resume → Toggle state
- Tap + → Add screen
- Empty state: "No recurring expenses" with add button

#### 4.1.2 Add/Edit Recurring Expense Screen

**File:** `lib/screens/add_recurring_screen.dart`

**Layout:**
```
┌─────────────────────────────────────┐
│  ← Add Recurring                    │  AppBar (or "Edit Recurring")
├─────────────────────────────────────┤
│                                     │
│  Title                              │
│  ┌─────────────────────────────┐    │
│  │  Netflix                    │    │
│  └─────────────────────────────┘    │
│                                     │
│  Amount                             │
│  ┌─────────────────────────────┐    │
│  │  ₹ 499.00                   │    │
│  └─────────────────────────────┘    │
│                                     │
│  Category                           │
│  ┌─────────────────────────────┐    │
│  │  [icon] Entertainment     ▼ │    │
│  └─────────────────────────────┘    │
│                                     │
│  Frequency                          │
│  ┌─────────────────────────────┐    │
│  │  Monthly                  ▼ │    │
│  └─────────────────────────────┘    │
│                                     │
│  [Advanced options expand/collapse] │
│  ┌─────────────────────────────┐    │
│  │  Day of month: 5            │    │  (shown for monthly)
│  │  OR                         │    │
│  │  Every N days: 14           │    │  (shown for custom)
│  │  OR                         │    │
│  │  Weekdays: [M][T][W][T][F]  │    │  (shown for weekly)
│  └─────────────────────────────┘    │
│                                     │
│  Start Date                         │
│  ┌─────────────────────────────┐    │
│  │  January 5, 2026          📅│    │
│  └─────────────────────────────┘    │
│                                     │
│  End Date (optional)                │
│  ┌─────────────────────────────┐    │
│  │  No end date              📅│    │
│  └─────────────────────────────┘    │
│                                     │
│  Note (optional)                    │
│  ┌─────────────────────────────┐    │
│  │  Monthly subscription       │    │
│  └─────────────────────────────┘    │
│                                     │
├─────────────────────────────────────┤
│  [        Save Recurring         ]  │  Primary button
└─────────────────────────────────────┘
```

**Validation:**
- Title: Required, max 100 chars
- Amount: Required, > 0
- Category: Required
- Frequency: Required
- Start Date: Required, can be past or future
- Custom interval: Required if frequency is custom, min 1

### 4.2 Widgets

#### 4.2.1 RecurringExpenseListTile

**File:** `lib/widgets/recurring_expense_list_tile.dart`

**Props:**
- `RecurringExpense item`
- `VoidCallback onTap`
- `VoidCallback onTogglePause`
- `VoidCallback onDelete`

**Display:**
- Category icon (same style as expense list tile)
- Title (primary text)
- Amount + Frequency + Next due date (secondary text)
- Pause/Resume icon button
- Swipe to delete

#### 4.2.2 FrequencyPicker

**File:** `lib/widgets/frequency_picker.dart`

**Props:**
- `RecurrenceFrequency value`
- `ValueChanged<RecurrenceFrequency> onChanged`

**Display:**
- Dropdown or segmented control
- Options: Daily, Weekly, Monthly, Yearly, Custom

#### 4.2.3 WeekdaySelector

**File:** `lib/widgets/weekday_selector.dart`

**Props:**
- `List<int> selectedDays`
- `ValueChanged<List<int>> onChanged`

**Display:**
- Row of 7 circular toggles: M T W T F S S
- Selected days highlighted with accent color

#### 4.2.4 UpcomingRecurringCard (Optional - Home Screen)

**File:** `lib/widgets/upcoming_recurring_card.dart`

**Display:**
- Card showing next 3 upcoming recurring expenses
- "View all" link to recurring list screen

---

## 5. Navigation & Integration

### 5.1 App Initialization

**Update `main.dart`:**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final expenseService = ExpenseService();
  final themeService = ThemeService();
  final recurringService = RecurringExpenseService();  // NEW
  
  await Future.wait([
    expenseService.init(),
    themeService.init(),
    recurringService.init(),  // NEW
  ]);
  
  // Generate due recurring expenses on app open
  await recurringService.generateDueExpenses(expenseService);  // NEW
  
  runApp(LedgerifyApp(...));
}
```

### 5.2 Settings Screen Navigation

**Update `settings_screen.dart`:**

Add a list tile:
```
┌─────────────────────────────────────┐
│  [repeat icon] Recurring Expenses   │
│  Manage subscriptions and bills   > │
└─────────────────────────────────────┘
```

### 5.3 Home Screen (Optional Enhancement)

Add "Upcoming" section below monthly summary:
```
┌─────────────────────────────────────┐
│  Upcoming                   View all│
│  ┌─────────────────────────────┐    │
│  │  Netflix · ₹499 · Tomorrow  │    │
│  │  Rent · ₹15,000 · Feb 1     │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
```

---

## 6. Implementation Tasks

### Phase 1: Data Layer (Day 1)

| # | Task | File(s) | Est. |
|---|------|---------|------|
| 1.1 | Add `recurring` to ExpenseSource enum | `models/expense.dart` | 10m |
| 1.2 | Create RecurrenceFrequency enum | `models/recurring_expense.dart` | 15m |
| 1.3 | Create RecurringExpense model | `models/recurring_expense.dart` | 30m |
| 1.4 | Run build_runner for Hive adapters | - | 5m |
| 1.5 | Create RecurringExpenseService (CRUD) | `services/recurring_expense_service.dart` | 45m |
| 1.6 | Implement calculateNextDueDate | `services/recurring_expense_service.dart` | 30m |
| 1.7 | Implement generateDueExpenses | `services/recurring_expense_service.dart` | 45m |
| 1.8 | Write unit tests for service | `test/recurring_expense_service_test.dart` | 60m |

**Phase 1 Total: ~4 hours**

### Phase 2: UI - List Screen (Day 2)

| # | Task | File(s) | Est. |
|---|------|---------|------|
| 2.1 | Create RecurringExpenseListTile widget | `widgets/recurring_expense_list_tile.dart` | 45m |
| 2.2 | Create RecurringListScreen | `screens/recurring_list_screen.dart` | 60m |
| 2.3 | Add empty state | `screens/recurring_list_screen.dart` | 20m |
| 2.4 | Implement swipe-to-delete | `screens/recurring_list_screen.dart` | 20m |
| 2.5 | Implement pause/resume toggle | `screens/recurring_list_screen.dart` | 15m |

**Phase 2 Total: ~2.5 hours**

### Phase 3: UI - Add/Edit Screen (Day 2-3)

| # | Task | File(s) | Est. |
|---|------|---------|------|
| 3.1 | Create FrequencyPicker widget | `widgets/frequency_picker.dart` | 30m |
| 3.2 | Create WeekdaySelector widget | `widgets/weekday_selector.dart` | 30m |
| 3.3 | Create AddRecurringScreen (basic) | `screens/add_recurring_screen.dart` | 60m |
| 3.4 | Add frequency-specific options | `screens/add_recurring_screen.dart` | 45m |
| 3.5 | Add form validation | `screens/add_recurring_screen.dart` | 30m |
| 3.6 | Add edit mode support | `screens/add_recurring_screen.dart` | 30m |

**Phase 3 Total: ~3.5 hours**

### Phase 4: Integration (Day 3)

| # | Task | File(s) | Est. |
|---|------|---------|------|
| 4.1 | Initialize RecurringExpenseService in main | `main.dart` | 15m |
| 4.2 | Call generateDueExpenses on app open | `main.dart` | 15m |
| 4.3 | Add navigation from Settings screen | `screens/settings_screen.dart` | 20m |
| 4.4 | Pass recurringService through widget tree | Multiple | 30m |
| 4.5 | Test full flow end-to-end | - | 30m |

**Phase 4 Total: ~2 hours**

### Phase 5: Polish & Optional (Day 4)

| # | Task | File(s) | Est. |
|---|------|---------|------|
| 5.1 | Add UpcomingRecurringCard to Home | `widgets/upcoming_recurring_card.dart` | 45m |
| 5.2 | Add "Recurring" badge to generated expenses | `widgets/expense_list_tile.dart` | 20m |
| 5.3 | Handle edge cases (month overflow, etc.) | `services/recurring_expense_service.dart` | 30m |
| 5.4 | UI polish and animations | Multiple | 30m |
| 5.5 | Final testing and bug fixes | - | 60m |

**Phase 5 Total: ~3 hours**

---

## 7. Total Estimate

| Phase | Time |
|-------|------|
| Phase 1: Data Layer | 4h |
| Phase 2: List Screen | 2.5h |
| Phase 3: Add/Edit Screen | 3.5h |
| Phase 4: Integration | 2h |
| Phase 5: Polish | 3h |
| **Total** | **~15 hours** |

---

## 8. Testing Strategy

### Unit Tests
- `calculateNextDueDate()` for all frequency types
- `generateDueExpenses()` with various scenarios
- Edge cases: month overflow, year boundaries, DST

### Widget Tests
- RecurringExpenseListTile renders correctly
- FrequencyPicker state changes
- WeekdaySelector multi-select

### Integration Tests
- Create recurring → verify expense generated
- Pause recurring → verify no generation
- Delete recurring → verify cleanup

### Manual Testing Checklist
- [ ] Create daily recurring, verify next day generation
- [ ] Create monthly on 31st, verify Feb handling
- [ ] Create weekly with specific days
- [ ] Pause and resume recurring
- [ ] Edit existing recurring
- [ ] Delete recurring (verify no orphan expenses)
- [ ] App closed for week, verify catch-up generation
- [ ] Light/dark theme consistency

---

## 9. Future Enhancements (Out of Scope)

- **Notifications:** Remind user before recurring expense is due
- **Variable amounts:** Support for expenses that vary (e.g., utility bills)
- **Skip occurrence:** Skip next occurrence without pausing entirely
- **Recurring income:** Track recurring income (salary, etc.)
- **Categories for recurring:** Dedicated "Subscriptions" category
- **Import from calendar:** Import recurring events as expenses

---

## 10. Files to Create/Modify

### New Files
```
lib/models/recurring_expense.dart
lib/models/recurring_expense.g.dart (generated)
lib/services/recurring_expense_service.dart
lib/screens/recurring_list_screen.dart
lib/screens/add_recurring_screen.dart
lib/widgets/recurring_expense_list_tile.dart
lib/widgets/frequency_picker.dart
lib/widgets/weekday_selector.dart
lib/widgets/upcoming_recurring_card.dart (optional)
test/recurring_expense_service_test.dart
```

### Modified Files
```
lib/models/expense.dart (add ExpenseSource.recurring)
lib/models/expense.g.dart (regenerate)
lib/main.dart (init service, call generation)
lib/screens/settings_screen.dart (add navigation)
lib/screens/home_screen.dart (optional: upcoming section)
lib/widgets/expense_list_tile.dart (optional: recurring badge)
```

---

## 11. Acceptance Criteria

### Must Have
- [ ] User can create recurring expense with title, amount, category, frequency
- [ ] Supported frequencies: daily, weekly, monthly, yearly, custom (every N days)
- [ ] Expenses auto-generated on app open for all due recurring items
- [ ] User can view list of all recurring expenses
- [ ] User can pause/resume recurring expenses
- [ ] User can edit recurring expenses
- [ ] User can delete recurring expenses
- [ ] Works correctly with light/dark theme

### Should Have
- [ ] Weekly recurring with specific weekday selection
- [ ] Monthly recurring with specific day-of-month
- [ ] End date support for limited-duration recurring
- [ ] Empty state with helpful message

### Nice to Have
- [ ] Upcoming recurring section on home screen
- [ ] Visual indicator on generated expenses showing they're from recurring
- [ ] Catch-up generation for missed days when app wasn't opened

---

*Plan created: January 31, 2026*
*Author: Claude Code*
