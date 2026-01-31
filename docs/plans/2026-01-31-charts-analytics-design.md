# Charts & Analytics Feature Design - Ledgerify

**Date:** January 31, 2026  
**Branch:** `feature/ledgerify-basics`  
**Status:** Ready for Implementation

---

## 1. Overview

Add beautiful, interactive charts and visualizations to Ledgerify for better spending insights.

### Goals
- Understand spending patterns over time
- Quick visual summary of category breakdown
- Compare spending across periods
- Motivation through visual feedback

### Scope
- **Home Screen**: Interactive donut chart replacing `CategoryBreakdownCard`
- **New Analytics Tab**: Dedicated 4th tab with comprehensive visualizations
- **Library**: `fl_chart` package for all charts
- **Colors**: Unique color per category, consistent across all charts

---

## 2. Category Color Palette

Each category gets a unique, muted color that works in both themes.

| Category | Dark Theme | Light Theme | Hex Dark | Hex Light |
|----------|-----------|-------------|----------|-----------|
| Food & Dining | Green | Dark Green | `#4CAF50` | `#2E7D32` |
| Transport | Blue | Dark Blue | `#42A5F5` | `#1565C0` |
| Shopping | Purple | Dark Purple | `#AB47BC` | `#7B1FA2` |
| Entertainment | Orange | Dark Orange | `#FF7043` | `#E64A19` |
| Bills & Utilities | Blue Grey | Dark Blue Grey | `#78909C` | `#546E7A` |
| Health | Red | Dark Red | `#EF5350` | `#C62828` |
| Education | Indigo | Dark Indigo | `#5C6BC0` | `#3949AB` |
| Other | Brown | Dark Brown | `#8D6E63` | `#5D4037` |

### Implementation
Add `color` extension to `ExpenseCategory` in new file `lib/theme/category_colors.dart`:

```dart
extension ExpenseCategoryColor on ExpenseCategory {
  Color color(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (this) {
      case ExpenseCategory.food:
        return isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);
      // ... etc
    }
  }
}
```

---

## 3. Home Screen Donut Chart

### Replaces
`CategoryBreakdownCard` (collapsible progress bars)

### Visual Design
```
┌─────────────────────────────────────┐
│                                     │
│         ┌───────────────┐           │
│        ╱                 ╲          │
│       │    ₹12,450       │          │
│       │   total spent    │          │
│        ╲                 ╱          │
│         └───────────────┘           │
│                                     │
│  ● Food  ● Transport  ● Shopping    │
│  ● Bills ● Health     ● Other       │
│                                     │
└─────────────────────────────────────┘
```

### Specifications
- **Chart diameter**: ~200dp
- **Donut thickness**: 24dp
- **Card padding**: 16dp all around
- **Center text**: Total amount + "total spent" label

### Behavior
- **Tap slice**: Expands slightly, center shows category name + amount + percentage
- **Legend**: Horizontal wrap, only non-zero categories
- **Empty state**: Dashed circle outline with "No expenses yet"
- **Animation**: Slices animate in (0.5s ease-out)

### Location
Between `MonthlySummaryCard` and `UpcomingRecurringCard` on Home screen.

---

## 4. Analytics Screen

### Navigation
New 4th tab in bottom navigation: Home | Recurring | **Analytics** | Settings

Icon: `Icons.bar_chart_rounded` or `Icons.analytics_rounded`

### Layout
```
┌─────────────────────────────────────┐
│  Analytics              [Filter ▼]  │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐    │
│  │      CATEGORY BREAKDOWN     │    │
│  │       (Donut Chart)         │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │      SPENDING TREND         │    │
│  │  [Daily] [Weekly] [Monthly] │    │
│  │       (Line Chart)          │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │    MONTHLY COMPARISON       │    │
│  │       (Bar Chart)           │    │
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

### Filter Options (AppBar dropdown)
- This Month (default)
- Last 3 Months
- Last 6 Months
- This Year
- All Time

---

## 5. Spending Trend Line Chart

### Toggle Modes

| Mode | X-Axis | Data Points | Use Case |
|------|--------|-------------|----------|
| Daily | Days 1-31 | Up to 31 | Current month pattern |
| Weekly | Week labels | Last 12 weeks | Medium-term trend |
| Monthly | Month names | Last 6-12 months | Long-term overview |

### Visual Design
```
  ₹50k ┤
       │            ╱╲
  ₹40k ┤     ╱╲    ╱  ╲
       │    ╱░░╲──╱░░░░╲
  ₹30k ┤   ╱░░░░░░░░░░░░╲    ╱
       │  ╱░░░░░░░░░░░░░░╲──╱
  ₹20k ┤ ╱░░░░░░░░░░░░░░░░░░
       │╱░░░░░░░░░░░░░░░░░░░
  ₹10k ┼─────────────────────
       Jan  Feb  Mar  Apr  May
```

### Specifications
- **Line**: 2dp stroke, accent color
- **Fill**: Gradient from accent (20% opacity) to transparent
- **Grid**: Subtle horizontal lines only
- **Touch**: Drag to see tooltip with exact value
- **Labels**: Y-axis currency (₹10k), X-axis dates/months
- **Animation**: Line draws left-to-right (0.8s)

### Empty State
Less than 2 data points: "Need more data to show trends"

---

## 6. Monthly Comparison Bar Chart

### Visual Design
```
        ₹52,430        ₹41,200        ₹48,750
       ┌───────┐                     ┌───────┐
       │░░░░░░░│      ┌───────┐      │░░░░░░░│
       │░░░░░░░│      │░░░░░░░│      │░░░░░░░│
       │░░░░░░░│      │░░░░░░░│      │░░░░░░░│
       └───────┘      └───────┘      └───────┘
          Mar            Apr            May
                                        ↑
                                   (current)
```

### Specifications
- **Bars**: Rounded top corners (8dp), 40dp width
- **Spacing**: 16dp between bars
- **Colors**: Current month = accent solid, past = accent 50% opacity
- **Labels**: Amount above bar, month below
- **Default**: Last 6 months
- **Touch**: Tap to highlight
- **Animation**: Bars grow from bottom (0.5s staggered)

### Scrolling
If >6 months, horizontally scrollable with latest month anchored right.

---

## 7. Service Layer Extensions

### New Methods in ExpenseService

```dart
/// Daily spending for a specific month
/// Returns map of day number (1-31) to total amount
Map<int, double> getDailySpending(int year, int month);

/// Weekly spending totals for last N weeks
List<WeeklyTotal> getWeeklySpending(int weeks);

/// Monthly spending totals for last N months
List<MonthlyTotal> getMonthlyTotals(int months);

/// Category breakdown for arbitrary date range
Map<ExpenseCategory, double> getCategoryBreakdownForRange(
  DateTime start,
  DateTime end,
);
```

### New Data Classes

```dart
class WeeklyTotal {
  final DateTime weekStart;
  final double total;
  
  const WeeklyTotal({
    required this.weekStart,
    required this.total,
  });
}

class MonthlyTotal {
  final int year;
  final int month;
  final double total;
  
  const MonthlyTotal({
    required this.year,
    required this.month,
    required this.total,
  });
}
```

### Performance
- Single-pass iteration over filtered expenses
- No redundant sorting or multiple loops
- Results cached in screen state, recalculated on filter change

---

## 8. File Structure

### New Files
```
lib/
├── theme/
│   └── category_colors.dart          # Category color extensions
├── widgets/
│   └── charts/
│       ├── category_donut_chart.dart # Reusable donut chart
│       ├── spending_line_chart.dart  # Line/area trend chart
│       └── monthly_bar_chart.dart    # Bar comparison chart
└── screens/
    └── analytics_screen.dart         # New analytics tab
```

### Modified Files
```
lib/
├── theme/
│   └── ledgerify_theme.dart          # Export category_colors
├── services/
│   └── expense_service.dart          # Add 4 new methods + data classes
├── screens/
│   ├── main_shell.dart               # Add 4th tab
│   └── home_screen.dart              # Replace breakdown card with donut
└── pubspec.yaml                      # Add fl_chart dependency
```

### Deleted Files
```
lib/widgets/category_breakdown_card.dart  # Replaced by donut chart
```

---

## 9. Implementation Phases

| Phase | Description | Est. Time |
|-------|-------------|-----------|
| 1 | Add `fl_chart` + category colors | 30 min |
| 2 | Service layer extensions | 45 min |
| 3 | Home screen donut chart | 1.5 hr |
| 4 | Analytics screen + navigation | 45 min |
| 5 | Spending trend line chart | 1.5 hr |
| 6 | Monthly comparison bar chart | 1 hr |
| 7 | Polish: animations, empty states | 1 hr |

**Total: ~7 hours**

---

## 10. Dependencies

### fl_chart
```yaml
dependencies:
  fl_chart: ^0.69.0  # or latest stable
```

**Why fl_chart:**
- Most popular Flutter charting library
- Beautiful default animations
- Highly customizable
- Active maintenance
- MIT license (free for commercial use)

---

## 11. Design Principles (Quiet Finance)

All charts follow Ledgerify design language:

- **No gamification**: No celebratory animations or achievement badges
- **Muted colors**: Sophisticated palette, not loud primary colors
- **Subtle animations**: Ease-in-out, 200-500ms, no bounce/spring
- **Numbers first**: Clear, readable amounts as primary content
- **Generous spacing**: Let charts breathe
- **Dark-first**: Optimized for dark theme, works well in light

---

*Design created: January 31, 2026*
*Author: Claude Code*
