# Performance Optimization Plan - Ledgerify

**Date:** January 31, 2026  
**Branch:** `feature/ledgerify-basics`  
**Status:** Complete

---

## 1. Overview

Performance audit identified **27 issues** across the codebase. This plan prioritizes fixes by impact and effort.

### Summary

| Severity | Count | Description |
|----------|-------|-------------|
| HIGH | 5 | Expensive computations, N+1 queries, unnecessary rebuilds |
| MEDIUM | 10 | Missing const, redundant lookups, animation overhead |
| LOW | 12 | Minor optimizations, acceptable trade-offs |

---

## 2. High Severity Issues

### 2.1 Expensive Computations in ExpenseService

**File:** `lib/services/expense_service.dart:82-93`

**Problem:** `getAllExpenses()` sorts the entire list every call. `getExpensesForMonth()` calls `getAllExpenses()` first (sorting ALL), then filters.

```dart
// Current - BAD
List<Expense> getExpensesForMonth(int year, int month) {
  return getAllExpenses().where((expense) {  // Sorts ALL first!
    return expense.date.year == year && expense.date.month == month;
  }).toList();
}
```

**Fix:** Filter first, then sort only the filtered subset:

```dart
// Fixed - GOOD
List<Expense> getExpensesForMonth(int year, int month) {
  final monthExpenses = _expenseBox.values.where((expense) {
    return expense.date.year == year && expense.date.month == month;
  }).toList();
  monthExpenses.sort((a, b) => b.date.compareTo(a.date));
  return monthExpenses;
}
```

**Effort:** 15 min | **Impact:** High

---

### 2.2 Triple Data Processing in HomeScreen

**File:** `lib/screens/home_screen.dart:188-198`

**Problem:** Inside `ValueListenableBuilder`, three expensive operations run on every Hive box change:

```dart
final monthExpenses = widget.expenseService.getExpensesForMonth(...)  // Sort + Filter
final monthTotal = widget.expenseService.calculateTotal(monthExpenses);  // Iteration
final categoryBreakdown = widget.expenseService.getCategoryBreakdown(monthExpenses);  // Iteration
```

**Fix:** Create a combined method that does a single pass:

```dart
// In ExpenseService
MonthSummary getMonthSummary(int year, int month) {
  final expenses = _expenseBox.values.where((e) => 
    e.date.year == year && e.date.month == month).toList();
  expenses.sort((a, b) => b.date.compareTo(a.date));
  
  double total = 0;
  final breakdown = <ExpenseCategory, double>{};
  for (final expense in expenses) {
    total += expense.amount;
    breakdown[expense.category] = (breakdown[expense.category] ?? 0) + expense.amount;
  }
  
  return MonthSummary(expenses: expenses, total: total, breakdown: breakdown);
}
```

**Effort:** 30 min | **Impact:** High

---

### 2.3 N+1 Query Pattern in RecurringListScreen

**File:** `lib/screens/recurring_list_screen.dart:61-73`

**Problem:** List is filtered three times for active, paused, and ended items:

```dart
final allItems = recurringService.getAll();  // Sort
final activeItems = allItems.where(...).toList();  // Filter 1
final pausedItems = allItems.where(...).toList();  // Filter 2
final endedItems = allItems.where(...).toList();  // Filter 3
```

**Fix:** Single-pass categorization:

```dart
// In RecurringExpenseService
RecurringCategories getCategorizedItems() {
  final active = <RecurringExpense>[];
  final paused = <RecurringExpense>[];
  final ended = <RecurringExpense>[];
  
  for (final item in _box.values) {
    if (item.hasEnded) {
      ended.add(item);
    } else if (item.isActive) {
      active.add(item);
    } else {
      paused.add(item);
    }
  }
  
  // Sort each list by title
  active.sort((a, b) => a.title.compareTo(b.title));
  paused.sort((a, b) => a.title.compareTo(b.title));
  ended.sort((a, b) => a.title.compareTo(b.title));
  
  return RecurringCategories(active: active, paused: paused, ended: ended);
}
```

**Effort:** 30 min | **Impact:** High

---

### 2.4 Form onChanged Triggers Full Rebuild

**Files:** 
- `lib/screens/add_expense_screen.dart:195`
- `lib/screens/add_recurring_screen.dart:337`

**Problem:** `onChanged: () => setState(() {})` rebuilds entire screen on every keystroke.

**Fix:** Only rebuild the submit button using ValueListenableBuilder:

```dart
// Remove Form.onChanged

// In _buildBottomButton, wrap button in ValueListenableBuilder
ValueListenableBuilder(
  valueListenable: _amountController,
  builder: (context, _, __) {
    final isValid = _isFormValid;
    return ElevatedButton(
      onPressed: isValid ? _saveExpense : null,
      // ...
    );
  },
)
```

Or use a simpler approach - listen to controllers directly:

```dart
@override
void initState() {
  super.initState();
  _amountController.addListener(_updateFormState);
  _titleController.addListener(_updateFormState);
}

void _updateFormState() {
  final newValid = _isFormValid;
  if (newValid != _lastIsValid) {
    _lastIsValid = newValid;
    setState(() {});  // Only rebuilds when validity changes
  }
}
```

**Effort:** 45 min | **Impact:** High

---

### 2.5 Repeated getUpcoming() Calls in MainShell

**File:** `lib/screens/main_shell.dart:200-202`

**Problem:** Badge count computed on every box change via filtering and sorting.

**Fix:** Cache the count or debounce updates:

```dart
// Simple fix: compute count less expensively
int getUpcomingCount({int days = 7}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final endDate = today.add(Duration(days: days));
  
  int count = 0;
  for (final item in _box.values) {
    if (!item.isActive || item.hasEnded) continue;
    final dueDate = DateTime(item.nextDueDate.year, item.nextDueDate.month, item.nextDueDate.day);
    if (!dueDate.isAfter(endDate)) count++;
  }
  return count;
}
```

**Effort:** 15 min | **Impact:** Medium-High

---

## 3. Medium Severity Issues

### 3.1 Missing `const` Constructors

**Files:** Multiple screens and widgets

**Problem:** `SizedBox`, `EdgeInsets`, `BorderRadius` created without `const`.

**Fix:** Add `const` keyword to all eligible constructors. Run:

```bash
flutter analyze lib/ | grep prefer_const
```

**Effort:** 30 min | **Impact:** Medium

---

### 3.2 Redundant Color Lookups

**Files:** `home_screen.dart`, `recurring_list_screen.dart`, etc.

**Problem:** `LedgerifyColors.of(context)` called multiple times in same method.

**Fix:** Store in local variable once:

```dart
Future<void> _someMethod() async {
  final colors = LedgerifyColors.of(context);
  // Use colors throughout
}
```

**Effort:** 20 min | **Impact:** Low-Medium

---

### 3.3 _getTitle() and _getSubtitle() Called Twice

**File:** `lib/widgets/expense_list_tile.dart:104-111`

**Problem:** Methods called twice - once for check, once for display.

**Fix:** Compute once:

```dart
@override
Widget build(BuildContext context) {
  final colors = LedgerifyColors.of(context);
  final title = _getTitle();
  final subtitle = _getSubtitle();
  
  // Use title and subtitle variables
}
```

**Effort:** 10 min | **Impact:** Low-Medium

---

### 3.4 DateTime Operations in Build Methods

**Files:** 
- `lib/widgets/recurring_expense_list_tile.dart:306-373`
- `lib/widgets/upcoming_recurring_card.dart:250-294`

**Problem:** `DateTime.now()` and date calculations performed in build.

**Fix:** Compute `today` once at the top of build:

```dart
@override
Widget build(BuildContext context) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  
  // Pass today to helper methods
  final formattedDate = _formatNextDue(recurring, today);
}
```

**Effort:** 20 min | **Impact:** Medium

---

### 3.5 Missing Keys in List Builders

**File:** `lib/screens/recurring_list_screen.dart:82-99`

**Problem:** `.map()` without keys prevents efficient list updates.

**Fix:** Add keys:

```dart
...activeItems.map((item) => RecurringExpenseListTile(
  key: ValueKey(item.id),  // Add key
  recurring: item,
  // ...
)),
```

**Effort:** 15 min | **Impact:** Medium

---

### 3.6 Dropdown Items Rebuilt Every Time

**File:** `lib/screens/add_expense_screen.dart:410-429`

**Problem:** Category dropdown items recreated on every rebuild.

**Fix:** Make items static:

```dart
// At class level
static final _categoryItems = ExpenseCategory.values.map((category) {
  return DropdownMenuItem(
    value: category,
    child: Row(
      children: [
        Icon(category.icon, size: 24),
        SizedBox(width: 12),
        Text(category.displayName),
      ],
    ),
  );
}).toList();
```

Note: This loses theme-awareness. Alternative is to cache per-theme.

**Effort:** 20 min | **Impact:** Low-Medium

---

## 4. Low Severity Issues (Optional)

| Issue | File | Fix | Effort |
|-------|------|-----|--------|
| ExpenseCategory.icon uses switch | `expense.dart` | Use static map | 15 min |
| AnimatedCrossFade keeps both children | `add_recurring_screen.dart` | Use AnimatedSwitcher | 20 min |
| IndexedStack keeps all screens alive | `main_shell.dart` | Acceptable trade-off | - |
| Hive box.listenable() too broad | Multiple | Use keys filter | 30 min |
| Spread operator in list building | `settings_screen.dart` | Use for loop | 10 min |

---

## 5. Implementation Plan

### Phase 1: High-Impact Quick Wins (1-2 hours)

| # | Task | Est. |
|---|------|------|
| 1.1 | Fix getExpensesForMonth - filter before sort | 15m |
| 1.2 | Create getMonthSummary single-pass method | 30m |
| 1.3 | Create getCategorizedItems for recurring | 30m |
| 1.4 | Add getUpcomingCount efficient method | 15m |

### Phase 2: Form Performance (45 min)

| # | Task | Est. |
|---|------|------|
| 2.1 | Fix AddExpenseScreen form onChange | 25m |
| 2.2 | Fix AddRecurringScreen form onChange | 20m |

### Phase 3: Widget Optimizations (1 hour)

| # | Task | Est. |
|---|------|------|
| 3.1 | Add const constructors throughout | 30m |
| 3.2 | Fix redundant color lookups | 15m |
| 3.3 | Cache title/subtitle in list tiles | 10m |
| 3.4 | Add keys to list builders | 10m |

### Phase 4: DateTime & Minor Fixes (30 min)

| # | Task | Est. |
|---|------|------|
| 4.1 | Optimize DateTime operations | 15m |
| 4.2 | Cache dropdown items | 15m |

---

## 6. Total Estimate

| Phase | Description | Time |
|-------|-------------|------|
| 1 | High-Impact Quick Wins | 1.5h |
| 2 | Form Performance | 45m |
| 3 | Widget Optimizations | 1h |
| 4 | DateTime & Minor Fixes | 30m |
| **Total** | | **~4 hours** |

---

## 7. Success Metrics

After optimization, verify:

1. **Scroll Performance:** 60fps in expense list with 100+ items
2. **Form Input:** No visible lag when typing
3. **Tab Switching:** Instant (<100ms) tab switches
4. **Memory:** No increase in memory usage over time
5. **Build Time:** `flutter analyze` shows fewer warnings

### Testing Commands

```bash
# Profile mode testing
flutter run --profile

# DevTools performance overlay
# Press 'P' in terminal while running

# Analyze for remaining issues  
flutter analyze lib/
```

---

## 8. Files to Modify

### Services
- `lib/services/expense_service.dart`
- `lib/services/recurring_expense_service.dart`

### Screens
- `lib/screens/home_screen.dart`
- `lib/screens/recurring_list_screen.dart`
- `lib/screens/add_expense_screen.dart`
- `lib/screens/add_recurring_screen.dart`
- `lib/screens/main_shell.dart`

### Widgets
- `lib/widgets/expense_list_tile.dart`
- `lib/widgets/recurring_expense_list_tile.dart`
- `lib/widgets/upcoming_recurring_card.dart`
- `lib/widgets/category_breakdown_card.dart`

### Models (Optional)
- `lib/models/expense.dart` - icon lookup optimization

---

*Plan created: January 31, 2026*  
*Author: Claude Code*
