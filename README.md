# Ledgerify

A personal expense tracker built with Flutter. Simple, fast, and offline-first.

## About

Ledgerify is designed to be a calm, frictionless tool for daily expense tracking. No accounts, no cloud sync, no ads - just a straightforward way to track where your money goes.

### Philosophy

Most expense tracking apps feel over-engineered or cluttered with features you don't need. Ledgerify intentionally keeps the scope small:

- Manual expense tracking with clear categories
- Monthly and category-wise insights
- Local storage - your data stays on your device
- No account system required

## Features

### V1 (Current)
- Add expenses with amount, category, date, and optional notes
- View expenses in reverse chronological order
- Monthly total summary
- Category-wise breakdown
- Edit and delete expenses
- Swipe-to-delete gesture
- Light and dark theme support (follows system)
- Offline-first - works without internet

### Planned
- SMS parsing for automatic expense detection
- Export data to CSV/JSON
- Basic search and filtering
- Custom categories

## Screenshots

<!-- Add screenshots here -->
```
[Home Screen]     [Add Expense]     [Category View]
     |                 |                  |
     v                 v                  v
  --------          --------          --------
 |        |        |        |        |        |
 | Monthly|        | Amount |        | Food   |
 | Total  |        |________|        | 45%    |
 |________|        |Category|        |--------|
 |        |        |________|        |Transport|
 | List   |        |  Date  |        | 30%    |
 | of     |        |________|        |--------|
 |Expenses|        |  Note  |        | Other  |
 |        |        |________|        | 25%    |
  --------          --------          --------
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
   flutter packages pub run build_runner build
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
├── main.dart              # App entry point
├── models/
│   └── expense.dart       # Expense data model with Hive annotations
├── screens/
│   ├── home_screen.dart   # Main screen with expense list
│   └── add_expense_screen.dart  # Form for adding/editing expenses
├── services/
│   └── expense_service.dart     # Hive-based data management
├── widgets/
│   ├── expense_list_tile.dart   # Individual expense row
│   ├── monthly_summary_card.dart    # Monthly total display
│   └── category_breakdown_card.dart # Category-wise summary
└── utils/
    └── currency_formatter.dart  # Currency and date formatting
```

## Tech Stack

- **Flutter** - UI framework
- **Hive** - Local NoSQL database (lightweight, fast)
- **intl** - Date and currency formatting

## Data Model

```dart
class Expense {
  String id;           // Unique identifier
  double amount;       // Expense amount
  ExpenseCategory category;  // Category enum
  DateTime date;       // When the expense occurred
  String? note;        // Optional description
  ExpenseSource source;    // manual or sms
  String? merchant;    // Optional merchant name
  DateTime createdAt;  // When the entry was created
}
```

### Categories

- Food & Dining
- Transport
- Shopping
- Entertainment
- Bills & Utilities
- Health
- Education
- Other

## Contributing

This is primarily a personal project, but suggestions and bug reports are welcome! Please open an issue first to discuss any changes.

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

Built as a personal tool to track daily expenses without the bloat of commercial apps.
