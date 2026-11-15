# khmer_calendar

Reusable Flutter package for Khmer Lunar Calendar (Chhankitek), Buddha Day (ថ្ងៃសីល) icon, Buddhist Era year (ព.ស.), and Cambodia Public Holidays.

Automatically adapts to your app's `ThemeData` (`colorScheme: ColorScheme.fromSeed(...)`) and **Light / Dark mode**, with optional overrides via `KhmerCalendarTheme`.

## Installation

Add `khmer_calendar` to your `pubspec.yaml`:

```yaml
dependencies:
  khmer_calendar:
    path: ../../khmer_calendar
```

## Usage

### Automatic Theme (Light & Dark Mode from `MaterialApp`)

```dart
MaterialApp(
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF08246E),
      brightness: Brightness.light,
    ),
  ),
  darkTheme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF08246E),
      brightness: Brightness.dark,
    ),
  ),
  home: const KhmerCalendarPage(title: 'ប្រតិទិន'),
);
```

### Custom Theme Overrides (Optional)

```dart
const KhmerCalendarPage(
  title: 'ប្រតិទិន',
  theme: KhmerCalendarTheme(
    primaryColor: Color(0xFF08246E),
    buddhaDayColor: Colors.amber,
  ),
);
```

### Embedded Widget

```dart
KhmerCalendarView(
  onDaySelected: (day, lunar) {
    // Handle selected date and Khmer lunar info
  },
)
```
