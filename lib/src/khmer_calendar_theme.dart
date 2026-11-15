import 'package:flutter/material.dart';

/// Optional theme overrides for [KhmerCalendarView] and [KhmerCalendarPage].
///
/// Any `null` property automatically inherits from `Theme.of(context).colorScheme`
/// and adapts to light/dark mode.
class KhmerCalendarTheme {
  final Color? primaryColor;
  final Color? backgroundColor;
  final Color? surfaceColor;
  final Color? textColor;
  final Color? secondaryTextColor;
  final Color? borderColor;
  final Color? holidayColor;
  final Color? buddhaDayColor;
  final Color? sundayBackgroundColor;
  final Color? todayTextColor;

  const KhmerCalendarTheme({
    this.primaryColor,
    this.backgroundColor,
    this.surfaceColor,
    this.textColor,
    this.secondaryTextColor,
    this.borderColor,
    this.holidayColor,
    this.buddhaDayColor,
    this.sundayBackgroundColor,
    this.todayTextColor,
  });

  /// Resolves effective colors using [Theme.of(context)] and any overrides.
  ResolvedKhmerCalendarTheme resolve(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final effectivePrimary = primaryColor ?? colorScheme.primary;

    return ResolvedKhmerCalendarTheme(
      isDark: isDark,
      primaryColor: effectivePrimary,
      backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
      surfaceColor:
          surfaceColor ??
          (isDark ? colorScheme.surfaceContainerLow : colorScheme.surface),
      textColor: textColor ?? colorScheme.onSurface,
      secondaryTextColor: secondaryTextColor ?? colorScheme.onSurfaceVariant,
      borderColor:
          borderColor ??
          (isDark ? colorScheme.outlineVariant : Colors.grey.shade300),
      holidayColor: holidayColor ?? colorScheme.error,
      buddhaDayColor:
          buddhaDayColor ??
          (isDark ? Colors.amber.shade300 : Colors.amber.shade800),
      sundayBackgroundColor:
          sundayBackgroundColor ??
          effectivePrimary.withValues(alpha: isDark ? 0.28 : 0.22),
      todayTextColor: todayTextColor ?? colorScheme.onPrimary,
    );
  }
}

/// Concrete resolved colors used internally by [KhmerCalendarView].
class ResolvedKhmerCalendarTheme {
  final bool isDark;
  final Color primaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textColor;
  final Color secondaryTextColor;
  final Color borderColor;
  final Color holidayColor;
  final Color buddhaDayColor;
  final Color sundayBackgroundColor;
  final Color todayTextColor;

  const ResolvedKhmerCalendarTheme({
    required this.isDark,
    required this.primaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.borderColor,
    required this.holidayColor,
    required this.buddhaDayColor,
    required this.sundayBackgroundColor,
    required this.todayTextColor,
  });
}
