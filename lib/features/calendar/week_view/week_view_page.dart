import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quicktasks/domain/models/calendar_item.dart';
import 'package:quicktasks/domain/repositories/calendar_item_repository.dart';
import 'package:quicktasks/features/backlog/backlog_tray_widget.dart';
import 'package:quicktasks/features/calendar/day_view/overdue_tray_widget.dart';
import 'package:quicktasks/features/items/item_bottom_sheet.dart';
import 'package:quicktasks/features/sync/google_calendar_service.dart';

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
    setState(() {
      _centerDate = _centerDate.add(Duration(days: days));
    });
  }

  void _goToToday() {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = ref.watch(calendarItemRepositoryProvider);

    // Columns are defined as today - 2, today - 1, today, today + 1, today + 2
    final start = _centerDate.subtract(const Duration(days: 2));
    final end = _centerDate.add(const Duration(days: 3));
    final itemsStream = repo.watchItemsInWindow(start, end);

    final weekdaysShort = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('WEEK VIEW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
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
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          // Detect horizontal swipes to shift days
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! < 0) {
            // Swipe Left -> Shift forward by 1 day
            _shiftCenterDate(1);
          } else if (details.primaryVelocity! > 0) {
            // Swipe Right -> Shift backward by 1 day
            _shiftCenterDate(-1);
          }
        },
        child: Column(
          children: [
            // 5-Column layout
            Expanded(
              child: StreamBuilder<List<CalendarItem>>(
                stream: itemsStream,
                builder: (context, snapshot) {
                  final items = snapshot.data ?? [];

                  return Row(
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
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: index < 4 
                                  ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
                                  : BorderSide.none,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Column Header
                              InkWell(
                                onTap: () {
                                  // Navigate to Day View for this date
                                  // Since DayViewPage displays the day, we need to pass the date or update its state
                                  // We can push to DayViewPage and pass date parameters if needed, or simply pass the date
                                  // Let's implement dynamic day selection on routing or pass via router if supported.
                                  // For simplicity, we can let user click and navigate. Since GoRouter does '/day', we can pass date parameter or let routing handle it.
                                  // Actually, we can use a shared state provider for the active day!
                                  // Let's keep it simple: go to '/day' and we can pass query parameters if needed. Or we can just go back.
                                  // Let's pass the date as a query parameter '/day?date=2026-05-28' in the future, but for now we can just navigate.
                                  context.go('/day');
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  color: isToday 
                                      ? theme.colorScheme.primary.withValues(alpha: 0.08) 
                                      : Colors.transparent,
                                  child: Column(
                                    children: [
                                      Text(
                                        dayName,
                                        style: TextStyle(
                                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 10,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dayNum,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          decoration: isToday ? TextDecoration.underline : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Divider(height: 1),

                              // Items list for this day
                              Expanded(
                                child: ListView.separated(
                                  padding: const EdgeInsets.all(4.0),
                                  itemCount: dayItems.length,
                                  separatorBuilder: (context, idx) => const SizedBox(height: 4),
                                  itemBuilder: (context, idx) {
                                    final item = dayItems[idx];
                                    final shape = _getCategoryShape(item.category);

                                    return InkWell(
                                      onTap: () => ItemBottomSheet.show(context, initialItem: item),
                                      child: Container(
                                        padding: const EdgeInsets.all(6.0),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: theme.colorScheme.primary, width: 1.5),
                                          color: theme.scaffoldBackgroundColor,
                                        ),
                                        child: Text(
                                          '${item.isComplete ? '☒ ' : ''}$shape${item.title}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            decoration: item.isComplete ? TextDecoration.lineThrough : null,
                                            decorationThickness: 1.5,
                                          ),
                                          maxLines: 4,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),

            // Overdue and Backlog Trays at the bottom
            const OverdueTrayWidget(),
            const BacklogTrayWidget(),
          ],
        ),
      ),
    );
  }
}
