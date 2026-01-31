# Design: Light & Dark Theme Support

**Date:** 2026-01-31  
**Status:** Ready for implementation

---

## Overview

Add light mode support while maintaining the "Quiet Finance" aesthetic. Users can choose between System default, Light, or Dark themes via a new Settings screen.

## Light Theme Color Palette

| Token | Dark Mode | Light Mode |
|-------|-----------|------------|
| `background` | `#121212` | `#F5F5F3` (warm off-white) |
| `surface` | `#1E1E1E` | `#FFFFFF` (white cards) |
| `surfaceElevated` | `#252525` | `#FFFFFF` |
| `surfaceHighlight` | `#2C2C2C` | `#EBEBEA` (warm gray) |
| `textPrimary` | `#FFFFFF` | `#1A1A1A` (near-black) |
| `textSecondary` | 70% white | 70% `#1A1A1A` |
| `textTertiary` | 50% white | 45% `#1A1A1A` |
| `textDisabled` | 30% white | 30% `#1A1A1A` |
| `accent` | `#A8E6CF` | `#2E9E6B` (darker for contrast) |
| `accentMuted` | 15% accent | 12% accent |
| `negative` | `#FF6B6B` | `#DC4444` (darker for contrast) |
| `divider` | 10% white | 8% `#1A1A1A` |

## Settings Screen

### Structure
```
AppBar: "Settings" (left-aligned, back arrow)

Section: Appearance
├── Theme → System default (tap opens bottom sheet)

Section: About  
├── Version → 1.0.0
```

### Theme Bottom Sheet
```
┌─────────────────────────────────────┐
│  ─────  (drag handle)               │
│  Theme (headlineSmall)              │
│                                     │
│  ○  System default                  │
│  ○  Light                           │
│  ●  Dark                            │
└─────────────────────────────────────┘
```

## Implementation

### Files to create:
- `lib/screens/settings_screen.dart`
- `lib/services/theme_service.dart`

### Files to modify:
- `lib/theme/colors.dart` - Add light colors
- `lib/theme/theme.dart` - Add lightTheme
- `lib/main.dart` - Theme switching
- `lib/screens/home_screen.dart` - Settings icon

### Theme Mode Enum
```dart
enum AppThemeMode { system, light, dark }
```

### State Management
- `ThemeService` with `ValueNotifier<ThemeMode>`
- Persist in Hive box
- `ValueListenableBuilder` in main.dart

### Flow
1. App starts → Load saved preference
2. Settings → Theme → Bottom sheet
3. Select option → Save & notify
4. MaterialApp rebuilds

## Implementation Order

1. Update `colors.dart` with light palette
2. Update `theme.dart` with `lightTheme`
3. Create `theme_service.dart`
4. Update `main.dart` for theme switching
5. Create `settings_screen.dart`
6. Update `home_screen.dart` with settings icon
