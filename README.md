<p align="center">
  <img src="Ledegerify_logo.png" alt="Ledgerify Logo" width="200"/>
</p>

<h1 align="center">Ledgerify</h1>

<p align="center">
  A personal expense tracker built with Flutter. Simple, fast, and offline-first.
</p>

## About

Ledgerify is designed to be a calm, frictionless tool for daily expense tracking. No accounts, no cloud sync, no ads - just a straightforward way to track where your money goes.

### Philosophy: Quiet Finance

Most expense tracking apps feel over-engineered or cluttered with features you don't need. Ledgerify follows a "Quiet Finance" design philosophy:

- **Clarity over decoration** - Numbers are the main content
- **Calm over excitement** - No gamification, streaks, or badges
- **Trust over engagement** - Your data stays on your device
- **Restraint over expression** - Subtle animations, professional tone

## Features

### Expense Tracking
- Add expenses with amount, category, date, and optional notes
- View expenses in reverse chronological order
- Swipe-to-delete gesture
- Edit and delete expenses
- Custom categories support
- Tag expenses for better organization

### Income Tracking
- Track income from multiple sources (salary, freelance, investments, etc.)
- Automatic goal allocation - distribute income to savings goals by percentage
- Recurring income templates for scheduled income

### Recurring Transactions
- Set up recurring expenses (rent, subscriptions, etc.)
- Set up recurring income (salary, dividends, etc.)
- Auto-generate transactions on due dates
- Configurable frequencies (daily, weekly, monthly, yearly)

### Savings Goals
- Create savings goals with target amounts and deadlines
- Track progress with visual indicators
- Automatic contributions from income allocations
- Milestone notifications (25%, 50%, 75%, 100%)

### Budgets
- Set monthly overall budget or per-category budgets
- Visual progress indicators
- Customizable warning thresholds (50-95%)
- Notifications when approaching or exceeding limits

### Analytics
- **Financial Summary** - Total income, expenses, net income, savings rate
- **Income vs Expense Chart** - 6-month side-by-side comparison
- **Category Breakdown** - Donut chart showing spending distribution
- **Spending Trends** - Line chart with daily/weekly/monthly views
- **Monthly Comparison** - Bar chart of monthly totals
- Filter by time period (this month, 3 months, 6 months, year, all time)

### Notifications (Fully Configurable)
- **Budget Alerts** - Warning at customizable threshold, exceeded at 100%
- **Recurring Reminders** - Upcoming expenses/income (1-7 days before)
- **Overdue Reminders** - Notify about missed recurring items
- **Goal Notifications** - Milestone achievements and completions
- **Weekly Summary** - Scheduled spending overview (day & time configurable)
- **Daily Reminder** - Prompt to log expenses (time configurable)
- **Quiet Hours** - No notifications during specified period

### Home Screen Widget
- **Native Android widget** - Quick access without opening the app
- **Budget progress** - Visual progress bar showing monthly spending
- **Context-aware messaging** - Time-of-day greetings, budget alerts, upcoming expenses
- **Quick-add buttons** - 4 category shortcuts that auto-learn from your spending habits
- **Theme sync** - Widget matches app theme (dark/light)
- **Configurable update frequency** - Manual, 30min, 1hr, 2hr, 4hr, or 6hr

### Appearance
- Dark theme (default) - Premium, calm aesthetic
- Light theme - Clean, professional look
- System theme - Follow device settings

### Data & Privacy
- **Offline-first** - Works without internet
- **Local storage** - All data stays on your device
- **No account required** - No sign-up, no cloud sync
- **CSV export/import** - Export/share or import transactions via Settings → Data

## CSV Format (v1)

Ledgerify exports a single transactions CSV with a versioned header comment:

- First line: `# ledgerify_transactions_csv_v1`
- Required columns for import: `type,amount,date`
- `type`: `expense` or `income`
- `amount`: positive decimal (import will accept negative and use absolute value)
- `date`: ISO-8601 (`YYYY-MM-DD` or timestamp)
- Optional columns: `id,created_at,currency,...` plus expense/income-specific fields

For best results, re-import files exported by Ledgerify (they include the full header set).

## Screenshots

```
[Home]          [Analytics]      [Goals]         [Settings]
  |                 |               |                |
  v                 v               v                v
--------         --------        --------         --------
|Monthly|        |Summary|       | Goal |         |Theme  |
|Total  |        |Income |       |Progress|       |--------|
|-------|        |Expense|       |--------|       |Notifi- |
|Recent |        |-------|       | Add   |        |cations|
|Expenses|       |Charts |       | Goal  |        |--------|
|       |        |       |       |       |        |Data   |
--------         --------        --------         --------
```

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or later)
- Android Studio / VS Code with Flutter extension
- An Android device or emulator

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/KTS-o7/ledgerify.git
   cd ledgerify
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Generate Hive adapters:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. Run the app:
   ```bash
   flutter run
   ```

### Building for Release

```bash
flutter build apk --release
```

The APK will be available at `build/app/outputs/flutter-apk/app-release.apk`

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   ├── expense.dart             # Expense model + ExpenseCategory enum
│   ├── budget.dart              # Budget model
│   ├── recurring_expense.dart   # Recurring expense template
│   ├── goal.dart                # Savings goal model
│   ├── income.dart              # Income model + IncomeSource enum
│   ├── recurring_income.dart    # Recurring income template
│   ├── tag.dart                 # Tag model for categorization
│   ├── custom_category.dart     # User-defined categories
│   └── notification_preferences.dart  # Notification settings
├── screens/
│   ├── home_screen.dart         # Main dashboard
│   ├── add_expense_screen.dart  # Add/edit expense form
│   ├── analytics_screen.dart    # Charts and insights
│   ├── goals_screen.dart        # Savings goals list
│   ├── recurring_list_screen.dart    # Recurring expenses
│   ├── recurring_income_screen.dart  # Recurring income
│   ├── settings_screen.dart     # App settings
│   └── notification_settings_screen.dart  # Notification preferences
├── services/
│   ├── expense_service.dart     # Expense CRUD operations
│   ├── income_service.dart      # Income CRUD + goal allocation
│   ├── budget_service.dart      # Budget management
│   ├── goal_service.dart        # Goal tracking
│   ├── recurring_expense_service.dart   # Recurring expense logic
│   ├── recurring_income_service.dart    # Recurring income logic
│   ├── notification_service.dart        # Push notifications
│   ├── notification_preferences_service.dart  # Notification settings
│   ├── tag_service.dart         # Tag management
│   ├── custom_category_service.dart     # Custom category management
│   └── theme_service.dart       # Theme persistence
├── widgets/
│   ├── charts/                  # Chart widgets (donut, line, bar)
│   ├── monthly_summary_card.dart
│   ├── category_breakdown_card.dart
│   ├── expense_list_tile.dart
│   ├── financial_insights_card.dart
│   └── ...
├── theme/
│   ├── colors.dart              # Color palette (dark/light)
│   ├── typography.dart          # Text styles
│   ├── spacing.dart             # Spacing constants
│   └── theme.dart               # Material theme configuration
└── utils/
    └── currency_formatter.dart  # Indian numbering system formatting
```

## Tech Stack

- **Flutter** - UI framework
- **Hive** - Local NoSQL database (lightweight, fast)
- **fl_chart** - Beautiful charts
- **flutter_local_notifications** - Push notifications
- **timezone** - Scheduled notification support
- **intl** - Date and currency formatting
- **uuid** - Unique ID generation
- **home_widget** - Native home screen widget support

## Data Models

### Hive Type IDs

| ID | Model |
|----|-------|
| 0 | Expense |
| 1 | ExpenseSource |
| 2 | ExpenseCategory |
| 3 | RecurrenceFrequency |
| 4 | RecurringExpense |
| 5 | Budget |
| 6 | Tag |
| 7 | CustomCategory |
| 8 | Goal |
| 9 | IncomeSource |
| 10 | GoalAllocation |
| 11 | Income |
| 12 | RecurringIncome |
| 13 | NotificationPreferences |
| 17 | WidgetConfig |

### Categories (Built-in)

- Food & Dining
- Transport
- Shopping
- Entertainment
- Bills & Utilities
- Health
- Education
- Other

### Income Sources

- Salary
- Freelance
- Business
- Investments
- Rental
- Gifts
- Refunds
- Other

## Navigation

The app uses a 5-tab bottom navigation:

| Tab | Screen | Purpose |
|-----|--------|---------|
| Home | HomeScreen | Dashboard, recent expenses, quick add |
| Recurring | RecurringListScreen | Manage recurring expenses |
| Analytics | AnalyticsScreen | Charts, insights, budgets |
| Goals | GoalsScreen | Savings goals tracking |
| Settings | SettingsScreen | Theme, notifications, data |

## Contributing

This is primarily a personal project, but suggestions and bug reports are welcome! Please open an issue first to discuss any changes.

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

Built as a personal tool to track daily expenses without the bloat of commercial apps. Follows a "Quiet Finance" design philosophy - calm, premium, trustworthy.
