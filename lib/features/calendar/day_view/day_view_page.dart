import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quicktasks/domain/models/calendar_item.dart';
import 'package:quicktasks/domain/repositories/calendar_item_repository.dart';
import 'package:quicktasks/features/backlog/backlog_tray_widget.dart';
import 'package:quicktasks/features/calendar/day_view/overdue_tray_widget.dart';
import 'package:quicktasks/features/items/calendar_item_chip.dart';
import 'package:quicktasks/features/items/item_bottom_sheet.dart';
import 'package:quicktasks/data/local/calendar_item_dao.dart';
import 'package:quicktasks/features/sync/google_calendar_service.dart';

class PositionedItem {
  final CalendarItem item;
  final double left;
  final double width;
  final int rowIndex;

  PositionedItem({
    required this.item,
    required this.left,
    required this.width,
    required this.rowIndex,
  });
}

class DayViewPage extends ConsumerStatefulWidget {
  const DayViewPage({super.key});

  @override
  ConsumerState<DayViewPage> createState() => _DayViewPageState();
}

class _DayViewPageState extends ConsumerState<DayViewPage> {
  late DateTime _selectedDay;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final double _hourWidth = 180.0;
  final double _rowHeight = 64.0;
  final double _headerHeight = 40.0;

  late ScrollController _scrollController;
  DateTime? _lastAutoScrolledDay;

  // Timer for drag auto scrolling
  Timer? _autoScrollTimer;

  Timer? _timeIndicatorTimer;

  final ValueNotifier<DateTime?> _draggedSlotTimeNotifier =
      ValueNotifier<DateTime?>(null);
  final ValueNotifier<CalendarItem?> _draggedItemNotifier =
      ValueNotifier<CalendarItem?>(null);

  final GlobalKey _timelineGridKey = GlobalKey();

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialSync();
    });

    // Update time indicator periodically
    _timeIndicatorTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && _isToday(_selectedDay)) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _stopAutoScroll();
    _timeIndicatorTimer?.cancel();
    _draggedSlotTimeNotifier.dispose();
    _draggedItemNotifier.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll({required bool left}) {
    if (_autoScrollTimer != null) return; // already running
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 50), (
      timer,
    ) {
      if (!_scrollController.hasClients) {
        _stopAutoScroll();
        return;
      }
      final currentScroll = _scrollController.offset;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final step = left ? -15.0 : 15.0;
      final target = (currentScroll + step).clamp(0.0, maxScroll);

      _scrollController.jumpTo(target);
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  List<double> _calculateHourWidths(List<CalendarItem> timelineItems) {
    final widths = List<double>.filled(24, _hourWidth * 0.5);
    final dayStart = _selectedDay;
    final dayEnd = _selectedDay.add(const Duration(days: 1));

    for (int h = 0; h < 24; h++) {
      final startOfHour = h.toDouble();
      final endOfHour = (h + 1).toDouble();

      final hasOverlap = timelineItems.any((item) {
        if (item.startAt == null || item.endAt == null) return false;

        final itemStart = item.startAt!;
        final itemEnd = item.endAt!;

        // Clamp start/end times to day boundaries
        final startCalculated = itemStart.isBefore(dayStart)
            ? dayStart
            : itemStart;
        final endCalculated = itemEnd.isAfter(dayEnd) ? dayEnd : itemEnd;

        final startDec = startCalculated.hour + startCalculated.minute / 60.0;
        final endDec =
            endCalculated.year > dayStart.year ||
                endCalculated.month > dayStart.month ||
                endCalculated.day > dayStart.day
            ? 24.0
            : (endCalculated.hour + endCalculated.minute / 60.0);

        return startDec < endOfHour && endDec > startOfHour;
      });

      if (hasOverlap) {
        widths[h] = _hourWidth;
      }
    }
    return widths;
  }

  double _getLeftOfHour(int h, List<double> hourWidths) {
    double sum = 0.0;
    for (int i = 0; i < h; i++) {
      sum += hourWidths[i];
    }
    return sum;
  }

  double _getCoordinateOfHour(double dec, List<double> hourWidths) {
    final h = dec.floor().clamp(0, 23);
    final frac = dec - h;
    final leftOfHour = _getLeftOfHour(h, hourWidths);
    final widthOfHour = hourWidths[h];
    return leftOfHour + frac * widthOfHour;
  }

  double _getHourDecOfCoordinate(double x, List<double> hourWidths) {
    double sum = 0.0;
    for (int h = 0; h < 24; h++) {
      final w = hourWidths[h];
      if (x >= sum && x < sum + w) {
        final frac = (x - sum) / w;
        return h + frac;
      }
      sum += w;
    }
    return 24.0;
  }

  DateTime _calculateSlotTimeFromLocalX(
    double x,
    List<CalendarItem> timelineItems,
  ) {
    final hourWidths = _calculateHourWidths(timelineItems);
    final hourDec = _getHourDecOfCoordinate(x, hourWidths);
    final hour = hourDec.floor().clamp(0, 23);
    final fracOfHour = hourDec - hour;
    final minute = ((fracOfHour * 60) / 30).round() * 30;
    final finalHour = minute == 60 ? (hour + 1).clamp(0, 23) : hour;
    final finalMinute = minute == 60 ? 0 : minute;

    return DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      finalHour,
      finalMinute,
    );
  }

  DateTime? _calculateSlotTime(
    Offset globalOffset,
    List<CalendarItem> timelineItems,
  ) {
    final renderBox =
        _timelineGridKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    final localOffset = renderBox.globalToLocal(globalOffset);
    return _calculateSlotTimeFromLocalX(localOffset.dx, timelineItems);
  }

  void _autoScrollToFirstEvent(List<CalendarItem> items) {
    if (!_scrollController.hasClients) return;

    double earliestHour = 8.0; // Default fallback to 8:00 AM
    if (items.isNotEmpty) {
      final startTimes = items
          .map((i) => i.startAt)
          .whereType<DateTime>()
          .toList();
      if (startTimes.isNotEmpty) {
        final earliest = startTimes.reduce((a, b) => a.isBefore(b) ? a : b);
        earliestHour = earliest.hour + earliest.minute / 60.0;
        // Scroll 30 mins earlier to provide visual context
        earliestHour = max(0.0, earliestHour - 0.5);
      }
    }

    final hourWidths = _calculateHourWidths(items);
    final targetOffset = _getCoordinateOfHour(earliestHour, hourWidths);
    final maxScroll = _scrollController.position.maxScrollExtent;
    _scrollController.jumpTo(targetOffset.clamp(0.0, maxScroll));
    _lastAutoScrolledDay = _selectedDay;
  }

  void _showSyncingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text(
              'SYNCING CALENDAR',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
            content: Text(
              success
                  ? 'Sync completed successfully.'
                  : 'Sync failed. Please try again.',
            ),
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

  Future<void> _checkInitialSync() async {
    final dao = ref.read(calendarItemDaoProvider);
    final hasSynced = await dao.hasAnySyncToken();
    if (!hasSynced) {
      await _runSyncWithProgress(
        'Syncing your Google Calendar events for the first time. Please wait...',
      );
    }
  }

  void _changeDay(int days) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDay = _selectedDay.add(Duration(days: days));
    });
  }

  void _goToToday() {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    setState(() {
      _selectedDay = DateTime(now.year, now.month, now.day);
    });
  }

  Future<void> _triggerManualSync() async {
    await _runSyncWithProgress('Refreshing calendar data. Please wait...');
  }

  List<PositionedItem> _layoutItems(
    List<CalendarItem> items,
    List<double> hourWidths,
  ) {
    final list = <PositionedItem>[];
    final dayStart = _selectedDay;
    final dayEnd = _selectedDay.add(const Duration(days: 1));

    // 1. Filter out unscheduled backlog items and all-day items
    final timelineItems = items
        .where((i) => i.startAt != null && i.endAt != null && !i.isAllDay)
        .toList();

    // 2. Sort chronologically by start time, and then by end time descending
    timelineItems.sort((a, b) {
      final comp = a.startAt!.compareTo(b.startAt!);
      if (comp != 0) return comp;
      return b.endAt!.compareTo(a.endAt!);
    });

    // 3. Stacking row end times
    final rowEndTimes = <DateTime>[];

    for (final item in timelineItems) {
      final start = item.startAt!;
      final end = item.endAt!;

      // Clamp start/end times to day boundaries for horizontal positioning
      final startCalculated = start.isBefore(dayStart) ? dayStart : start;
      final endCalculated = end.isAfter(dayEnd) ? dayEnd : end;

      final startDec = startCalculated.hour + startCalculated.minute / 60.0;
      final endDec =
          endCalculated.year > dayStart.year ||
              endCalculated.month > dayStart.month ||
              endCalculated.day > dayStart.day
          ? 24.0
          : (endCalculated.hour + endCalculated.minute / 60.0);

      final left = _getCoordinateOfHour(startDec, hourWidths);
      final right = _getCoordinateOfHour(endDec, hourWidths);

      // Enforce minimum width of 80dp for readability/tap targets
      final width = max(right - left, 80.0);

      int targetRowIndex = -1;
      for (int i = 0; i < rowEndTimes.length; i++) {
        if (start.isAtSameMomentAs(rowEndTimes[i]) ||
            start.isAfter(rowEndTimes[i])) {
          targetRowIndex = i;
          break;
        }
      }

      if (targetRowIndex == -1) {
        targetRowIndex = rowEndTimes.length;
        rowEndTimes.add(end);
      } else {
        rowEndTimes[targetRowIndex] = end;
      }

      list.add(
        PositionedItem(
          item: item,
          left: left,
          width: width,
          rowIndex: targetRowIndex,
        ),
      );
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = ref.watch(calendarItemRepositoryProvider);

    final dayStart = _selectedDay;
    final dayEnd = _selectedDay.add(const Duration(days: 1));
    final itemsStream = repo.watchItemsInWindow(dayStart, dayEnd);

    // Weekdays list for descriptive header
    final weekdays = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];
    final months = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER',
    ];
    final dateStr =
        '${weekdays[_selectedDay.weekday - 1]}, ${months[_selectedDay.month - 1]} ${_selectedDay.day}';

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          dateStr,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
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
            icon: const Icon(Icons.calendar_view_week),
            onPressed: () => context.go('/week'),
            tooltip: 'Week View',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<CalendarItem>>(
        stream: itemsStream,
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          final allDayItems = items.where((i) => i.isAllDay).toList();
          final timelineItems = items.where((i) => !i.isAllDay).toList();
          final hourWidths = _calculateHourWidths(timelineItems);
          final positionedItems = _layoutItems(timelineItems, hourWidths);

          final isToday = _isToday(_selectedDay);
          double? currentX;
          if (isToday) {
            final now = DateTime.now();
            final nowDec = now.hour + now.minute / 60.0 + now.second / 3600.0;
            currentX = _getCoordinateOfHour(nowDec, hourWidths);
          }

          // Schedule auto-scroll on next frame if date changed
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_lastAutoScrolledDay != _selectedDay) {
              _autoScrollToFirstEvent(timelineItems);
            }
          });

          return Column(
            children: [
              // 1. Navigation controls
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => _changeDay(-1),
                    ),
                    Text(
                      '${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () => _changeDay(1),
                    ),
                  ],
                ),
              ),

              // 2. All-day events strip
              if (allDayItems.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allDayItems.map((item) {
                      return InkWell(
                        onTap: () =>
                            ItemBottomSheet.show(context, initialItem: item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('📅 ', style: TextStyle(fontSize: 12)),
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // 3. Scrollable Timeline
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: DragTarget<CalendarItem>(
                    onMove: (details) {
                      final slotTime = _calculateSlotTime(
                        details.offset,
                        timelineItems,
                      );
                      if (slotTime != null) {
                        if (slotTime != _draggedSlotTimeNotifier.value ||
                            _draggedItemNotifier.value != details.data) {
                          _draggedSlotTimeNotifier.value = slotTime;
                          _draggedItemNotifier.value = details.data;
                        }
                      }

                      final x = details.offset.dx;
                      final screenWidth = MediaQuery.of(context).size.width;
                      if (x < 60) {
                        _startAutoScroll(left: true);
                      } else if (x > screenWidth - 60) {
                        _startAutoScroll(left: false);
                      } else {
                        _stopAutoScroll();
                      }
                    },
                    onLeave: (_) {
                      _stopAutoScroll();
                      _draggedSlotTimeNotifier.value = null;
                      _draggedItemNotifier.value = null;
                    },
                    onWillAcceptWithDetails: (details) => true,
                    onAcceptWithDetails: (details) async {
                      HapticFeedback.heavyImpact();
                      _stopAutoScroll();
                      _draggedSlotTimeNotifier.value = null;
                      _draggedItemNotifier.value = null;
                      final slotTime = _calculateSlotTime(
                        details.offset,
                        timelineItems,
                      );
                      if (slotTime == null) return;

                      final item = details.data;
                      final duration =
                          item.endAt != null && item.startAt != null
                          ? item.endAt!.difference(item.startAt!)
                          : const Duration(minutes: 30);

                      final updated = item.copyWith(
                        startAt: slotTime,
                        endAt: slotTime.add(duration),
                      );
                      await repo.updateItem(updated);
                      ref.read(googleCalendarServiceProvider).sync();
                    },
                    builder: (context, candidateData, rejectedData) {
                      final maxRow = positionedItems.isNotEmpty
                          ? (positionedItems
                                    .map((pi) => pi.rowIndex)
                                    .reduce(max) +
                                1)
                          : 1;
                      final timelineHeight =
                          _headerHeight + maxRow * _rowHeight;

                      final totalTimelineWidth = hourWidths.reduce(
                        (a, b) => a + b,
                      );
                      return Container(
                        key: _timelineGridKey,
                        width: totalTimelineWidth,
                        height: timelineHeight,
                        color: Colors.transparent,
                        child: Stack(
                          children: [
                            // Grid lines
                            Row(
                              children: List.generate(24, (hour) {
                                return Container(
                                  width: hourWidths[hour],
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.15),
                                        width: 1.0,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),

                            // Hour Labels
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: _headerHeight,
                              child: Row(
                                children: List.generate(24, (hour) {
                                  final is12 = hour == 0 || hour == 12;
                                  final label =
                                      '${is12 ? 12 : hour % 12}:00 ${hour < 12 ? 'AM' : 'PM'}';
                                  return Container(
                                    width: hourWidths[hour],
                                    padding: const EdgeInsets.only(
                                      left: 6.0,
                                      top: 8.0,
                                    ),
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      label,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),

                            // Header line
                            Positioned(
                              top: _headerHeight - 1,
                              left: 0,
                              right: 0,
                              child: Divider(
                                height: 1,
                                thickness: 1.2,
                                color: theme.colorScheme.primary,
                              ),
                            ),

                            // Highlight slot on hover during drag
                            ValueListenableBuilder<DateTime?>(
                              valueListenable: _draggedSlotTimeNotifier,
                              builder: (context, slotTime, child) {
                                if (slotTime == null) {
                                  return const SizedBox.shrink();
                                }
                                return ValueListenableBuilder<CalendarItem?>(
                                  valueListenable: _draggedItemNotifier,
                                  builder: (context, draggedItem, child) {
                                    if (draggedItem == null) {
                                      return const SizedBox.shrink();
                                    }

                                    final slotStartDec =
                                        slotTime.hour + slotTime.minute / 60.0;
                                    final duration =
                                        draggedItem.endAt != null &&
                                            draggedItem.startAt != null
                                        ? draggedItem.endAt!.difference(
                                            draggedItem.startAt!,
                                          )
                                        : const Duration(minutes: 30);

                                    final durationDec =
                                        duration.inMinutes / 60.0;
                                    final slotEndDec =
                                        (slotStartDec + durationDec).clamp(
                                          0.0,
                                          24.0,
                                        );

                                    final highlightLeft = _getCoordinateOfHour(
                                      slotStartDec,
                                      hourWidths,
                                    );
                                    final highlightRight = _getCoordinateOfHour(
                                      slotEndDec,
                                      hourWidths,
                                    );
                                    final highlightWidth = max(
                                      highlightRight - highlightLeft,
                                      80.0,
                                    );

                                    return Positioned(
                                      left: highlightLeft,
                                      width: highlightWidth,
                                      top: _headerHeight,
                                      bottom: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary
                                              .withValues(alpha: 0.15),
                                          border: Border.symmetric(
                                            vertical: BorderSide(
                                              color: theme.colorScheme.primary,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),

                            // Tap detector for slot creation
                            Positioned.fill(
                              top: _headerHeight,
                              child: GestureDetector(
                                onTapUp: (details) {
                                  final targetTime =
                                      _calculateSlotTimeFromLocalX(
                                        details.localPosition.dx,
                                        timelineItems,
                                      );

                                  ItemBottomSheet.show(
                                    context,
                                    prefilledStart: targetTime,
                                  );
                                },
                                child: Container(color: Colors.transparent),
                              ),
                            ),

                            // Positioned chips
                            ...positionedItems.map((pi) {
                              final top =
                                  _headerHeight + pi.rowIndex * _rowHeight;
                              return Positioned(
                                key: ValueKey('pos_${pi.item.localId}'),
                                left: pi.left,
                                width: pi.width,
                                top: top,
                                height: _rowHeight,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2.0,
                                    vertical: 3.0,
                                  ),
                                  child: LongPressDraggable<CalendarItem>(
                                    key: ValueKey('drag_${pi.item.localId}'),
                                    data: pi.item,
                                    maxSimultaneousDrags: 1,
                                    delay: const Duration(milliseconds: 300),
                                    onDragStarted: () {
                                      HapticFeedback.mediumImpact();
                                    },
                                    feedback: Material(
                                      color: Colors.transparent,
                                      child: SizedBox(
                                        width: pi.width,
                                        height: _rowHeight,
                                        child: Opacity(
                                          opacity: 0.85,
                                          child: CalendarItemChip(
                                            item: pi.item,
                                            onTap: null,
                                            onComplete: null,
                                          ),
                                        ),
                                      ),
                                    ),
                                    childWhenDragging: Opacity(
                                      opacity: 0.3,
                                      child: CalendarItemChip(
                                        item: pi.item,
                                        onTap: null,
                                        onComplete: null,
                                      ),
                                    ),
                                    child: CalendarItemChip(
                                      item: pi.item,
                                      onTap: () => ItemBottomSheet.show(
                                        context,
                                        initialItem: pi.item,
                                      ),
                                      onComplete: () async {
                                        final updated = pi.item.copyWith(
                                          isComplete: !pi.item.isComplete,
                                          completedAt: !pi.item.isComplete
                                              ? DateTime.now()
                                              : null,
                                        );
                                        await repo.updateItem(updated);
                                        ref
                                            .read(googleCalendarServiceProvider)
                                            .sync();
                                      },
                                    ),
                                  ),
                                ),
                              );
                            }),

                            if (isToday && currentX != null) ...[
                              Positioned(
                                left: currentX - 0.75,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 1.5,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Positioned(
                                left: currentX - 4.0,
                                top: _headerHeight - 4.0,
                                child: Container(
                                  width: 8.0,
                                  height: 8.0,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 4. Overdue and Backlog trays anchored at the bottom
              const OverdueTrayWidget(),
              const BacklogTrayWidget(),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // FAB creates a new task (no pre-filled time)
          ItemBottomSheet.show(context);
        },
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
