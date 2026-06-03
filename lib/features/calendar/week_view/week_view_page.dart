import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quicktasks/app/theme/paper_decorations.dart';
import 'package:quicktasks/domain/models/calendar_item.dart';
import 'package:quicktasks/domain/repositories/calendar_item_repository.dart';
import 'package:quicktasks/features/backlog/backlog_tray_widget.dart';
import 'package:quicktasks/features/calendar/day_view/overdue_tray_widget.dart';
import 'package:quicktasks/features/items/item_bottom_sheet.dart';
import 'package:quicktasks/features/sync/google_calendar_service.dart';
import 'package:quicktasks/features/sync/google_auth_provider.dart';

class WeekViewPage extends ConsumerStatefulWidget {
  const WeekViewPage({super.key});

  @override
  ConsumerState<WeekViewPage> createState() => _WeekViewPageState();
}

class _WeekViewPageState extends ConsumerState<WeekViewPage> {
  late DateTime _centerDate;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _centerDate = DateTime(now.year, now.month, now.day);
  }

  void _shiftCenterDate(int days) {
    HapticFeedback.selectionClick();
    setState(() {
      _centerDate = _centerDate.add(Duration(days: days));
    });
  }

  void _goToToday() {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    setState(() {
      _centerDate = DateTime(now.year, now.month, now.day);
    });
  }

  void _showSyncingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('SYNCING CALENDAR', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _runSyncWithProgress(String message) async {
    if (!mounted) return;
    _showSyncingDialog(context, message);

    try {
      final success = await ref.read(googleCalendarServiceProvider).sync();

      if (mounted) {
        Navigator.pop(context); // Dismiss dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Sync completed successfully.' : 'Sync failed. Please try again.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _triggerManualSync() async {
    await _runSyncWithProgress('Refreshing calendar data. Please wait...');
  }

  String _getCategoryShape(TaskCategory category) {
    switch (category) {
      case TaskCategory.work:
        return '■ ';
      case TaskCategory.personal:
        return '● ';
      case TaskCategory.errand:
        return '▲ ';
      case TaskCategory.none:
        return '';
    }
  }

  String _formatItemTime(CalendarItem item) {
    if (item.isAllDay) {
      return 'All Day';
    }
    if (item.startAt == null) {
      return '';
    }
    final dt = item.startAt!;
    final hour = dt.hour;
    final minute = dt.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final formattedMinute = minute.toString().padLeft(2, '0');
    return '$formattedHour:$formattedMinute $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = ref.watch(calendarItemRepositoryProvider);
    final authState = ref.watch(googleAuthNotifierProvider);

    // Columns are defined as today - 2, today - 1, today, today + 1, today + 2
    final start = _centerDate.subtract(const Duration(days: 2));
    final end = _centerDate.add(const Duration(days: 3));
    final itemsStream = repo.watchItemsInWindow(start, end);

    final weekdaysShort = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    final months = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
    ];
    final endOfWeek = start.add(const Duration(days: 4));
    final String titleText;
    if (start.month == endOfWeek.month) {
      titleText = months[start.month - 1];
    } else {
      titleText = '${months[start.month - 1]}/${months[endOfWeek.month - 1]}';
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(titleText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _triggerManualSync,
            tooltip: 'Sync Google Calendar',
          ),
          OutlinedButton(
            onPressed: _goToToday,
            child: const Text('TODAY', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.calendar_view_day),
            onPressed: () => context.go('/day'),
            tooltip: 'Day View',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          // Detect horizontal swipes to shift days
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! < 0) {
            // Swipe Left -> Shift forward by 2 days
            _shiftCenterDate(2);
          } else if (details.primaryVelocity! > 0) {
            // Swipe Right -> Shift backward by 2 days
            _shiftCenterDate(-2);
          }
        },
        child: Column(
          children: [
            // 5-Column layout with floating trays on top
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: StreamBuilder<List<CalendarItem>>(
                      stream: itemsStream,
                      builder: (context, snapshot) {
                        final items = snapshot.data ?? [];

                  return CustomPaint(
                    painter: DotGridPainter(
                      color: theme.colorScheme.primary,
                      dotRadius: 0.8,
                      spacingX: 24.0,
                      spacingY: 24.0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: List.generate(5, (index) {
                      final dayDate = start.add(Duration(days: index));
                      final isToday = dayDate.year == DateTime.now().year &&
                          dayDate.month == DateTime.now().month &&
                          dayDate.day == DateTime.now().day;

                      // Filter items for this day
                      final dayItems = items.where((item) {
                        if (item.startAt == null) return false;
                        final startLocal = item.startAt!;
                        return startLocal.year == dayDate.year &&
                            startLocal.month == dayDate.month &&
                            startLocal.day == dayDate.day;
                      }).toList();

                      // Sort chronologically
                      dayItems.sort((a, b) {
                        if (a.isAllDay && !b.isAllDay) return -1;
                        if (!a.isAllDay && b.isAllDay) return 1;
                        if (a.startAt == null || b.startAt == null) return 0;
                        return a.startAt!.compareTo(b.startAt!);
                      });

                      final dayName = weekdaysShort[dayDate.weekday - 1];
                      final dayNum = dayDate.day.toString();

                      return Expanded(
                        child: Stack(
                          children: [
                            if (index < 4)
                              Positioned(
                                top: 0,
                                bottom: 0,
                                right: 0,
                                child: DashedDivider(
                                  axis: Axis.vertical,
                                  dashWidth: 4,
                                  dashSpace: 4,
                                  strokeWidth: 1.2,
                                  color: theme.colorScheme.primary.withValues(alpha: 0.6),
                                ),
                              ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                 Material(
                                   color: theme.colorScheme.primary,
                                   child: InkWell(
                                     onTap: () {
                                       HapticFeedback.selectionClick();
                                       context.go('/day');
                                     },
                                     child: Row(
                                       children: [
                                         Expanded(
                                           child: Padding(
                                             padding: const EdgeInsets.symmetric(vertical: 8.0),
                                             child: Column(
                                               children: [
                                                 Text(
                                                   dayName,
                                                   style: TextStyle(
                                                     fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                                     fontSize: 11,
                                                     color: theme.scaffoldBackgroundColor,
                                                   ),
                                                 ),
                                                 const SizedBox(height: 2),
                                                 Text(
                                                   dayNum,
                                                   style: TextStyle(
                                                     fontWeight: FontWeight.bold,
                                                     fontSize: 17,
                                                     color: theme.scaffoldBackgroundColor,
                                                     decoration: isToday ? TextDecoration.underline : null,
                                                     decorationColor: theme.scaffoldBackgroundColor,
                                                     decorationThickness: isToday ? 2.0 : null,
                                                   ),
                                                 ),
                                               ],
                                             ),
                                           ),
                                         ),
                                          if (index < 4)
                                            Container(
                                              width: 0.8,
                                              height: 40,
                                              color: theme.scaffoldBackgroundColor,
                                            ),
                                       ],
                                     ),
                                   ),
                                 ),

                                // Items list for this day
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      final now = DateTime.now();
                                      final prefilledTime = DateTime(
                                        dayDate.year,
                                        dayDate.month,
                                        dayDate.day,
                                        now.hour,
                                        now.minute,
                                      );
                                      ItemBottomSheet.show(
                                        context,
                                        prefilledStart: prefilledTime,
                                      );
                                    },
                                    child: ListView.separated(
                                      padding: const EdgeInsets.only(
                                        left: 4.0,
                                        right: 6.0, // 4.0 visual padding + 2.0 shadow offset
                                        top: 4.0,
                                        bottom: 120.0, // 120.0 to scroll past overlay trays
                                      ),
                                      itemCount: dayItems.length,
                                      separatorBuilder: (context, idx) => const SizedBox(height: 6),
                                      itemBuilder: (context, idx) {
                                        final item = dayItems[idx];
                                        final shape = _getCategoryShape(item.category);

                                        return InkWell(
                                          onTap: () {
                                            HapticFeedback.lightImpact();
                                            ItemBottomSheet.show(context, initialItem: item);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(6.0),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: theme.colorScheme.primary, width: 1.0),
                                              borderRadius: BorderRadius.circular(4),
                                              color: theme.scaffoldBackgroundColor,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: theme.colorScheme.primary,
                                                  offset: const Offset(2.0, 2.0),
                                                  blurRadius: 0.0,
                                                  spreadRadius: 0.0,
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${item.isComplete ? '☒ ' : ''}$shape${item.title}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    decoration: item.isComplete ? TextDecoration.lineThrough : null,
                                                    decorationThickness: item.isComplete ? 1.5 : null,
                                                  ),
                                                  maxLines: 4,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  _formatItemTime(item),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: theme.colorScheme.primary.withValues(alpha: 0.85),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                );
                  },
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const OverdueTrayWidget(),
                    const BacklogTrayWidget(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
        ),
      ),
          if (!authState.isInitialized)
            Positioned.fill(
              child: Container(
                color: theme.scaffoldBackgroundColor,
                child: Center(
                  child: Container(
                    width: 280,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      border: Border.all(color: theme.colorScheme.primary, width: 2.0),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary,
                          offset: const Offset(3.0, 3.0),
                          blurRadius: 0.0,
                          spreadRadius: 0.0,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'CONNECTING TO GOOGLE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.colorScheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 1.5,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '[ PLEASE WAIT ]',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Checking sign-in status...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
