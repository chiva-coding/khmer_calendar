import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:khmer_lunar_chhankitek/khmer_lunar_chhankitek.dart';

import 'khmer_calendar_theme.dart';
import 'khmer_calendar_view.dart';
import 'khmer_holiday.dart';

/// Full-screen Khmer Calendar page that automatically inherits `Theme.of(context)`
/// (including light/dark mode and `colorScheme`), with optional [theme] overrides.
class KhmerCalendarPage extends StatefulWidget {
  final String title;
  final PreferredSizeWidget? appBar;
  final KhmerCalendarTheme? theme;
  final bool lockPortrait;
  final bool showHolidays;
  final List<KhmerHoliday>? customHolidays;
  final void Function(DateTime selectedDay, LunarDay? lunarDay)? onDaySelected;

  const KhmerCalendarPage({
    super.key,
    this.title = 'ប្រតិទិន',
    this.appBar,
    this.theme,
    this.lockPortrait = true,
    this.showHolidays = true,
    this.customHolidays,
    this.onDaySelected,
  });

  @override
  State<KhmerCalendarPage> createState() => _KhmerCalendarPageState();
}

class _KhmerCalendarPageState extends State<KhmerCalendarPage> {
  @override
  void initState() {
    super.initState();
    if (widget.lockPortrait) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  @override
  void dispose() {
    if (widget.lockPortrait) {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved =
        (widget.theme ?? const KhmerCalendarTheme()).resolve(context);

    return Scaffold(
      extendBody: true,
      backgroundColor: resolved.backgroundColor,
      appBar:
          widget.appBar ??
          AppBar(
            title: Text(widget.title),
            backgroundColor: resolved.primaryColor,
            foregroundColor: resolved.todayTextColor,
            centerTitle: true,
          ),
      body: KhmerCalendarView(
        theme: widget.theme,
        showHolidays: widget.showHolidays,
        customHolidays: widget.customHolidays,
        onDaySelected: widget.onDaySelected,
      ),
    );
  }
}
