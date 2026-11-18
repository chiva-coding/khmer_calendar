import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:khmer_lunar_chhankitek/khmer_lunar_chhankitek.dart';
import 'package:table_calendar/table_calendar.dart';

import 'khmer_calendar_theme.dart';
import 'khmer_calendar_utils.dart';
import 'khmer_holiday.dart';

/// Embeddable Khmer Lunar & Public Holiday Calendar widget.
///
/// Automatically inherits colors and light/dark mode from `Theme.of(context)`,
/// with optional per-property overrides via [theme].
class KhmerCalendarView extends StatefulWidget {
  final KhmerCalendarTheme? theme;
  final DateTime? initialFocusedDay;
  final DateTime? firstDay;
  final DateTime? lastDay;
  final bool showHolidays;
  final bool showScrollToBottomButton;
  final List<KhmerHoliday>? customHolidays;
  final void Function(DateTime selectedDay, LunarDay? lunarDay)? onDaySelected;
  final Widget Function(BuildContext context, KhmerHoliday holiday)?
      holidayItemBuilder;
  final void Function(KhmerHoliday holiday)? onHolidayTap;
  final Widget? customLoading;

  const KhmerCalendarView({
    super.key,
    this.theme,
    this.initialFocusedDay,
    this.firstDay,
    this.lastDay,
    this.showHolidays = true,
    this.showScrollToBottomButton = true,
    this.customHolidays,
    this.onDaySelected,
    this.holidayItemBuilder,
    this.onHolidayTap,
    this.customLoading,
  });

  @override
  State<KhmerCalendarView> createState() => _KhmerCalendarViewState();
}

class _KhmerCalendarViewState extends State<KhmerCalendarView> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  Map<DateTime, List<KhmerHoliday>> _holidaysMap = {};
  bool _isLoading = false;
  String? _errorMessage;
  int? _fetchedYear;
  bool _khmerLocaleReady = false;

  final ScrollController _scrollController = ScrollController();
  bool _showScrollFab = false;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialFocusedDay ?? DateTime.now();
    _initKhmerLocale();

    if (widget.customHolidays != null) {
      _setHolidays(widget.customHolidays!, _focusedDay.year);
    } else if (widget.showHolidays) {
      _fetchHolidays(_focusedDay.year);
    }

    _scrollController.addListener(_checkScrollOverflow);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollOverflow());
  }

  @override
  void didUpdateWidget(covariant KhmerCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.customHolidays != oldWidget.customHolidays &&
        widget.customHolidays != null) {
      _setHolidays(widget.customHolidays!, _focusedDay.year);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initKhmerLocale() async {
    try {
      await initializeDateFormatting('km');
      if (mounted) {
        setState(() => _khmerLocaleReady = true);
      }
    } catch (_) {
      // Fallback to default locale if initialization fails
    }
  }

  void _checkScrollOverflow() {
    if (!mounted || !_scrollController.hasClients) return;
    final canScroll = _scrollController.position.maxScrollExtent > 0;
    final atBottom =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50;
    final shouldShow = canScroll && !atBottom;
    if (shouldShow != _showScrollFab) {
      setState(() => _showScrollFab = shouldShow);
    }
  }

  void _setHolidays(List<KhmerHoliday> holidays, int year) {
    final Map<DateTime, List<KhmerHoliday>> tempMap = {};
    for (final item in holidays) {
      final normalized = DateTime.utc(
        item.date.year,
        item.date.month,
        item.date.day,
      );
      tempMap[normalized] ??= [];
      tempMap[normalized]!.add(item);
    }
    setState(() {
      _holidaysMap = tempMap;
      _fetchedYear = year;
      _isLoading = false;
      _errorMessage = null;
    });
  }

  Future<void> _fetchHolidays(int year) async {
    if (!widget.showHolidays || widget.customHolidays != null) return;
    if (_fetchedYear == year) return;

    final cached = KhmerHolidayService.getCachedHolidays(year);
    if (cached != null) {
      _setHolidays(cached, year);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final holidays = await KhmerHolidayService.fetchPublicHolidays(year);
      if (!mounted) return;
      _setHolidays(holidays, year);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _checkScrollOverflow(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Failed to fetch holidays.\nPlease check your connection.';
      });
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _checkScrollOverflow(),
      );
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
    if (widget.onDaySelected != null) {
      final localDate = DateTime(
        selectedDay.year,
        selectedDay.month,
        selectedDay.day,
      );
      LunarDay? lunar;
      if (localDate.year >= KhmerLunar.minSupportedYear &&
          localDate.year <= KhmerLunar.maxSupportedYear) {
        lunar = KhmerLunar.day(localDate);
      }
      widget.onDaySelected!(selectedDay, lunar);
    }
  }

  void _changeMonth(int months) {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + months, 1);
    });
    _fetchHolidays(_focusedDay.year);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollOverflow());
  }

  String _formatKhmerMonth(DateTime date) {
    if (_khmerLocaleReady) {
      return DateFormat('MMMM', 'km').format(date);
    }
    return DateFormat('MMMM').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final resolvedTheme =
        (widget.theme ?? const KhmerCalendarTheme()).resolve(context);

    final holidaysInMonth = _holidaysMap.entries
        .where(
          (entry) =>
              entry.key.year == _focusedDay.year &&
              entry.key.month == _focusedDay.month,
        )
        .expand((entry) => entry.value)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Stack(
      children: [
        Column(
          children: [
            _buildCustomHeader(resolvedTheme),
            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      color: resolvedTheme.surfaceColor,
                      child: _buildTableCalendar(resolvedTheme),
                    ),
                  ),
                  if (widget.showHolidays) ...[
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverToBoxAdapter(
                      child: _buildHolidayList(holidaysInMonth, resolvedTheme),
                    ),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
          ],
        ),
        if (widget.showScrollToBottomButton && _showScrollFab)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.small(
              onPressed: () {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                );
              },
              backgroundColor: resolvedTheme.primaryColor,
              foregroundColor: resolvedTheme.todayTextColor,
              child: const Icon(Icons.keyboard_arrow_down),
            ),
          ),
      ],
    );
  }

  Widget _buildHolidayList(
    List<KhmerHoliday> holidays,
    ResolvedKhmerCalendarTheme theme,
  ) {
    if (_isLoading && holidays.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: widget.customLoading ??
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
        ),
      );
    }

    if (_errorMessage != null && holidays.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: theme.holidayColor, size: 40),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: theme.secondaryTextColor, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _fetchHolidays(_focusedDay.year),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: theme.todayTextColor,
                ),
                child: const Text('ព្យាយាមម្ដងទៀត'),
              ),
            ],
          ),
        ),
      );
    }

    if (holidays.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                color: theme.secondaryTextColor.withValues(alpha: 0.5),
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'មិនមានបុណ្យក្នុងខែនេះទេ',
                style: TextStyle(
                  color: theme.secondaryTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: holidays.length,
      itemBuilder: (context, index) {
        final holiday = holidays[index];
        if (widget.holidayItemBuilder != null) {
          return widget.holidayItemBuilder!(context, holiday);
        }

        final dayStr = DateFormat('dd').format(holiday.date);
        final monthStr = _formatKhmerMonth(holiday.date);

        final card = Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: BorderRadius.zero,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: theme.isDark ? 0.2 : 0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
            border: Border.all(color: theme.borderColor, width: 1),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                SizedBox(
                  width: 66,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayStr,
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          monthStr,
                          style: TextStyle(
                            color: theme.secondaryTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: theme.borderColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 10.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          holiday.name,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          holiday.localName,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: theme.secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        if (widget.onHolidayTap != null) {
          return GestureDetector(
            onTap: () => widget.onHolidayTap!(holiday),
            child: card,
          );
        }
        return card;
      },
    );
  }

  Widget _buildCustomHeader(ResolvedKhmerCalendarTheme theme) {
    final month = _formatKhmerMonth(_focusedDay);
    final monthYear = DateFormat('MMMM yyyy').format(_focusedDay);
    final buddhistYear = getKhmerBuddhistYear(_focusedDay);
    final khmerYear = 'ព.ស. ${convertToKhmerNumber(buddhistYear)}';

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      color: theme.surfaceColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: Icon(
              Icons.chevron_left,
              color: theme.primaryColor,
              size: 28,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                month,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    monthYear,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    khmerYear,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: Icon(
              Icons.chevron_right,
              color: theme.primaryColor,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCalendar(ResolvedKhmerCalendarTheme theme) {
    return TableCalendar(
      focusedDay: _focusedDay,
      firstDay: widget.firstDay ?? DateTime.utc(2020, 1, 1),
      lastDay: widget.lastDay ?? DateTime.utc(2060, 12, 31),
      startingDayOfWeek: StartingDayOfWeek.sunday,
      calendarFormat: CalendarFormat.month,
      availableGestures: AvailableGestures.horizontalSwipe,
      selectedDayPredicate: null,
      onDaySelected: _onDaySelected,
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
        _fetchHolidays(focusedDay.year);
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _checkScrollOverflow(),
        );
      },
      headerVisible: false,
      daysOfWeekHeight: 32.0,
      rowHeight: 48.0,
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          color: theme.todayTextColor,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        weekendStyle: TextStyle(
          color: theme.todayTextColor,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        decoration: BoxDecoration(color: theme.primaryColor),
      ),
      calendarStyle: const CalendarStyle(
        cellMargin: EdgeInsets.zero,
        cellPadding: EdgeInsets.zero,
        outsideDaysVisible: true,
      ),
      calendarBuilders: CalendarBuilders(
        dowBuilder: (context, day) {
          final index = day.weekday % 7;
          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(color: theme.primaryColor),
            child: Text(
              khmerWeekdays[index],
              style: TextStyle(
                color: theme.todayTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          );
        },
        todayBuilder: (context, day, focusedDay) =>
            _buildDayCell(day, theme, isToday: true),
        outsideBuilder: (context, day, focusedDay) =>
            _buildDayCell(day, theme, isOutside: true),
        defaultBuilder: (context, day, focusedDay) => _buildDayCell(day, theme),
      ),
    );
  }

  Widget _buildDayCell(
    DateTime day,
    ResolvedKhmerCalendarTheme theme, {
    bool isToday = false,
    bool isOutside = false,
  }) {
    final isSunday = day.weekday == DateTime.sunday;
    final normalized = DateTime.utc(day.year, day.month, day.day);
    final isHoliday = _holidaysMap.containsKey(normalized);

    final localDate = DateTime(day.year, day.month, day.day);
    LunarDay? lunar;
    if (localDate.year >= KhmerLunar.minSupportedYear &&
        localDate.year <= KhmerLunar.maxSupportedYear) {
      lunar = KhmerLunar.day(localDate);
    }

    final isSilDay = lunar?.isUposatha ?? false;
    final displayLunarDay = lunar == null
        ? 0
        : (lunar.phase == LunarPhase.waning && lunar.lunarDay > 15
            ? lunar.lunarDay - 15
            : lunar.lunarDay);
    final lunarLabel = lunar == null
        ? ''
        : (displayLunarDay == 1 && lunar.phase == LunarPhase.waxing
            ? lunar.khmerMonth
            : '${convertToKhmerNumber(displayLunarDay)} ${lunar.phase == LunarPhase.waxing ? 'កើត' : 'រោច'}');

    Color dayTextColor;
    if (isToday) {
      dayTextColor = theme.todayTextColor;
    } else if (isOutside) {
      dayTextColor = theme.secondaryTextColor.withValues(alpha: 0.45);
    } else {
      dayTextColor = isHoliday ? theme.holidayColor : theme.textColor;
    }

    Color lunarTextColor;
    if (isToday) {
      lunarTextColor = theme.todayTextColor.withValues(alpha: 0.9);
    } else if (isOutside) {
      lunarTextColor = theme.secondaryTextColor.withValues(alpha: 0.4);
    } else if (isHoliday) {
      lunarTextColor = theme.holidayColor;
    } else if (isSilDay) {
      lunarTextColor = theme.buddhaDayColor;
    } else {
      lunarTextColor = theme.textColor.withValues(alpha: 0.85);
    }

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        color: isToday
            ? theme.primaryColor
            : (isSunday ? theme.sundayBackgroundColor : theme.surfaceColor),
        border: Border.all(color: theme.borderColor, width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSilDay) ...[
                Opacity(
                  opacity: isOutside ? 0.45 : 1.0,
                  child: Image.asset(
                    'assets/icons/buddha_khmer.png',
                    package: 'khmer_calendar',
                    height: 15,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 2),
              ],
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: dayTextColor,
                  height: 1.1,
                ),
              ),
            ],
          ),
          if (lunarLabel.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(
              lunarLabel,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: isSilDay || isHoliday
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: lunarTextColor,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
