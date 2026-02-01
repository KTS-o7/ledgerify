# Ledgerify - Claude Code Guidelines

## Project Overview

**Ledgerify** is a personal expense tracker Flutter app for Android. It follows a "Quiet Finance" design philosophy - calm, premium, dark-themed UI with no gamification.

- **Platform:** Android (Flutter)
- **Storage:** Hive (local, offline-first)
- **Design:** Dark-first with light theme support

## Quick Commands

```bash
# Analyze code
flutter analyze lib/

# Build debug APK
flutter build apk --debug

# Run on connected device/emulator
flutter run

# Generate Hive adapters (after modifying models)
flutter pub run build_runner build --delete-conflicting-outputs
```

## Project Structure

```
lib/
├── main.dart                 # App entry, theme setup
├── models/
│   ├── expense.dart          # Expense model + ExpenseCategory enum
│   └── expense.g.dart        # Generated Hive adapter
├── services/
│   ├── expense_service.dart  # CRUD operations for expenses
│   └── theme_service.dart    # Theme persistence (system/light/dark)
├── screens/
│   ├── home_screen.dart      # Main dashboard
│   ├── add_expense_screen.dart
│   └── settings_screen.dart  # Theme selection
├── widgets/
│   ├── monthly_summary_card.dart
│   ├── category_breakdown_card.dart
│   └── expense_list_tile.dart
├── theme/
│   ├── ledgerify_theme.dart  # Barrel export
│   ├── colors.dart           # LedgerifyColors + LedgerifyColorScheme
│   ├── typography.dart       # LedgerifyTypography
│   ├── spacing.dart          # LedgerifySpacing + LedgerifyRadius
│   └── theme.dart            # LedgerifyTheme (MaterialTheme)
└── utils/
    └── currency_formatter.dart
```

## Design Philosophy: Quiet Finance

**Core principles:**
1. Clarity over decoration
2. Calm over excitement
3. Trust over engagement
4. Restraint over expression

**Never do:**
- Gamification (streaks, badges, rewards)
- Playful animations (bounce, wiggle, spring)
- Hype language ("Amazing!", "Awesome!", "Great job!")
- Emoji in UI
- Pure black backgrounds (use #121212)
- Visible borders (use elevation instead)

**Always do:**
- Prioritize numbers as main content
- Use whitespace generously
- Keep animations subtle (ease-in-out, 200-350ms)
- Neutral, professional microcopy

## Theme System

### Context-Aware Colors (Required Pattern)

Always use `LedgerifyColors.of(context)` for theme-aware colors:

```dart
@override
Widget build(BuildContext context) {
  final colors = LedgerifyColors.of(context);
  
  return Container(
    color: colors.background,
    child: Text(
      'Hello',
      style: TextStyle(color: colors.textPrimary),
    ),
  );
}
```

### Color Palette

| Token | Dark | Light |
|-------|------|-------|
| `background` | #121212 | #F5F5F3 |
| `surface` | #1E1E1E | #FFFFFF |
| `surfaceHighlight` | #2C2C2C | #EBEBEA |
| `accent` | #A8E6CF | #2E9E6B |
| `negative` | #FF6B6B | #DC4444 |
| `textPrimary` | #FFFFFF | #1A1A1A |
| `textSecondary` | 70% white | 70% black |
| `textTertiary` | 50% white | 45% black |

### Typography

Use `LedgerifyTypography` constants with color overrides:

```dart
Text(
  'Amount',
  style: LedgerifyTypography.labelMedium.copyWith(
    color: colors.textSecondary,
  ),
)
```

Key styles:
- `amountLarge` / `amountMedium` - For currency values
- `headlineMedium` - Screen titles
- `bodyLarge` - Primary body text
- `labelMedium` - Form labels

### Spacing

Use `LedgerifySpacing` constants:

```dart
SizedBox(height: LedgerifySpacing.md)  // 12dp
Padding(padding: EdgeInsets.all(LedgerifySpacing.lg))  // 16dp
```

| Token | Value |
|-------|-------|
| `xs` | 4dp |
| `sm` | 8dp |
| `md` | 12dp |
| `lg` | 16dp |
| `xl` | 24dp |

### Border Radius

Use `LedgerifyRadius`:

```dart
BorderRadius.circular(LedgerifyRadius.md)  // 12dp for buttons/inputs
BorderRadius.circular(LedgerifyRadius.lg)  // 16dp for cards
```

## Code Conventions

### Widget Parameters

When creating widgets that need theme colors in multiple methods, pass `LedgerifyColorScheme` as parameter:

```dart
Widget _buildAmountField(LedgerifyColorScheme colors) {
  return TextFormField(
    style: LedgerifyTypography.amountLarge.copyWith(
      color: colors.textPrimary,
    ),
    decoration: InputDecoration(
      fillColor: colors.surfaceHighlight,
      // ...
    ),
  );
}
```

### Imports

Use the barrel export for theme:

```dart
import '../theme/ledgerify_theme.dart';
```

This exports: `LedgerifyColors`, `LedgerifyTypography`, `LedgerifySpacing`, `LedgerifyRadius`, `LedgerifyTheme`

### Currency Formatting

Use Indian numbering system:

```dart
CurrencyFormatter.format(1234567.89)  // "12,34,567.89"
```

### Category Icons

Categories use Material Icons (not emoji):

```dart
ExpenseCategory.food.icon       // Icons.restaurant_rounded
ExpenseCategory.transport.icon  // Icons.directions_car_rounded
```

## Common Patterns

### Adding a New Screen

1. Create in `lib/screens/`
2. Use `Scaffold` with `colors.background`
3. Use transparent AppBar with `colors.textPrimary` for icons/title
4. Pass services as constructor parameters

### Adding a New Widget

1. Create in `lib/widgets/`
2. Get colors at start of `build()`: `final colors = LedgerifyColors.of(context);`
3. Use design tokens for all colors, spacing, typography

### Form Fields

```dart
TextFormField(
  style: LedgerifyTypography.bodyLarge.copyWith(color: colors.textPrimary),
  decoration: InputDecoration(
    filled: true,
    fillColor: colors.surfaceHighlight,
    border: OutlineInputBorder(
      borderRadius: LedgerifyRadius.borderRadiusMd,
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: LedgerifyRadius.borderRadiusMd,
      borderSide: BorderSide(color: colors.accent, width: 1),
    ),
  ),
)
```

### Cards

```dart
Container(
  padding: EdgeInsets.all(LedgerifySpacing.lg),
  decoration: BoxDecoration(
    color: colors.surface,
    borderRadius: LedgerifyRadius.borderRadiusLg,
  ),
  child: // ...
)
```

## Hive Models

When modifying `lib/models/expense.dart`:

1. Update the model class
2. Run: `flutter pub run build_runner build --delete-conflicting-outputs`
3. Check generated `expense.g.dart`

## Git Workflow

- Branch: `feature/ledgerify-basics`
- Commit style: Conventional commits (`feat:`, `fix:`, `docs:`, `refactor:`)
- Always run `flutter analyze` before committing

## Files to Never Commit

- `.idea/`
- `.metadata`
- `*.iml`
- `build/`
- `.dart_tool/`

These are in `.gitignore`.

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## Key Dependencies

| Package | Purpose |
|---------|---------|
| `hive` / `hive_flutter` | Local storage |
| `uuid` | Unique IDs for expenses |
| `intl` | Date/number formatting |
