import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quicktasks/app/theme/paper_decorations.dart';
import 'package:quicktasks/domain/models/calendar_item.dart';
import 'package:quicktasks/domain/repositories/calendar_item_repository.dart';
import 'package:quicktasks/features/backlog/backlog_tray_widget.dart';
import 'package:quicktasks/features/calendar/day_view/overdue_tray_widget.dart';
import 'package:quicktasks/features/items/calendar_item_chip.dart';
import 'package:quicktasks/features/items/item_bottom_sheet.dart';
import 'package:quicktasks/data/local/calendar_item_dao.dart';
import 'package:quicktasks/features/sync/google_calendar_service.dart';
import 'package:quicktasks/features/sync/google_auth_provider.dart';

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
  final String? editId;
  const DayViewPage({super.key, this.editId});

  @override
  ConsumerState<DayViewPage> createState() => _DayViewPageState();
}

class _DayViewPageState extends ConsumerState<DayViewPage> {
  late DateTime _selectedDay;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _timelineViewportKey = GlobalKey();

  final double _hourWidth = 180.0;
  final double _rowHeight = 64.0;
  final double _headerHeight = 40.0;

  late ScrollController _scrollController;
  DateTime? _lastAutoScrolledDay;

  // Timer for drag auto scrolling
  Timer? _autoScrollTimer;
  double? _dragPointerX; // true finger X, tracked via Listener

  Timer? _timeIndicatorTimer;

  final ValueNotifier<DateTime?> _draggedSlotTimeNotifier =
      ValueNotifier<DateTime?>(null);
  final ValueNotifier<CalendarItem?> _draggedItemNotifier =
      ValueNotifier<CalendarItem?>(null);
  final ValueNotifier<double> _scrollOffsetNotifier = ValueNotifier<double>(0.0);

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

    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        _scrollOffsetNotifier.value = _scrollController.offset;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialSync();
      if (widget.editId != null) {
        _showEditSheet(widget.editId!);
      }
    });

    // Update time indicator periodically
    _timeIndicatorTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && _isToday(_selectedDay)) {
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(DayViewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editId != null && widget.editId != oldWidget.editId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showEditSheet(widget.editId!);
      });
    }
  }

  void _showEditSheet(String editId) async {
    final repo = ref.read(calendarItemRepositoryProvider);
    final item = await repo.getItemByLocalId(editId);
    if (item != null && mounted) {
      ItemBottomSheet.show(context, initialItem: item);
    }
  }

  void _scrollTimeline(
    bool left,
    double viewportWidth,
    List<PositionedItem> positionedItems,
  ) {
    if (!_scrollController.hasClients) return;
    final current = _scrollController.offset;

    if (left) {
      // Find all incomplete items hidden to the left
      final leftHidden = positionedItems.where((pi) {
        if (pi.item.isComplete) return false;
        return pi.left + pi.width < current;
      }).toList();

      if (leftHidden.isNotEmpty) {
        // Sort by pi.left descending (closest to the left edge of viewport first)
        leftHidden.sort((a, b) => b.left.compareTo(a.left));
        final targetItem = leftHidden.first;
        final targetCenter = targetItem.left + targetItem.width / 2;
        final targetOffset = targetCenter - viewportWidth / 2;
        _scrollController.jumpTo(
          targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        );
      } else {
        final target = current - (viewportWidth * 0.7);
        _scrollController.jumpTo(
          target.clamp(0.0, _scrollController.position.maxScrollExtent),
        );
      }
    } else {
      // Find all incomplete items hidden to the right
      final rightLimit = current + viewportWidth;
      final rightHidden = positionedItems.where((pi) {
        if (pi.item.isComplete) return false;
        return pi.left > rightLimit;
      }).toList();

      if (rightHidden.isNotEmpty) {
        // Sort by pi.left ascending (closest to the right edge of viewport first)
        rightHidden.sort((a, b) => a.left.compareTo(b.left));
        final targetItem = rightHidden.first;
        final targetCenter = targetItem.left + targetItem.width / 2;
        final targetOffset = targetCenter - viewportWidth / 2;
        _scrollController.jumpTo(
          targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        );
      } else {
        final target = current + (viewportWidth * 0.7);
        _scrollController.jumpTo(
          target.clamp(0.0, _scrollController.position.maxScrollExtent),
        );
      }
    }
  }

  @override
  void dispose() {
    _stopAutoScroll();
    _timeIndicatorTimer?.cancel();
    _draggedSlotTimeNotifier.dispose();
    _draggedItemNotifier.dispose();
    _scrollOffsetNotifier.dispose();
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

    double targetHour;
    bool shouldCenter = false;

    final startTimes = items
        .where((i) => !i.isComplete)
        .map((i) => i.startAt)
        .whereType<DateTime>()
        .toList();

    if (startTimes.isNotEmpty) {
      final earliest = startTimes.reduce((a, b) => a.isBefore(b) ? a : b);
      targetHour = earliest.hour + earliest.minute / 60.0;
      // Scroll 30 mins earlier to provide visual context
      targetHour = max(0.0, targetHour - 0.5);
    } else {
      // Default fallback: center on the current time of day
      final now = DateTime.now();
      targetHour = now.hour + now.minute / 60.0;
      shouldCenter = true;
    }

    final hourWidths = _calculateHourWidths(items);
    double targetOffset = _getCoordinateOfHour(targetHour, hourWidths);

    if (shouldCenter) {
      final viewportWidth = _scrollController.position.viewportDimension;
      targetOffset = targetOffset - viewportWidth / 2;
    }

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
    final authState = ref.read(googleAuthNotifierProvider);
    if (!authState.isInitialized || authState.account == null) {
      return;
    }
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

    // 3. Stacking row end coordinates
    final rowEndCoordinates = <double>[];

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

      // Enforce minimum width of 140dp for readability/tap targets
      final width = max(right - left, 140.0);
      final visualRight = left + width;

      int targetRowIndex = -1;
      for (int i = 0; i < rowEndCoordinates.length; i++) {
        // Add a small 4dp padding buffer to prevent cards from touching each other in the same row
        if (left >= rowEndCoordinates[i] + 4.0) {
          targetRowIndex = i;
          break;
        }
      }

      if (targetRowIndex == -1) {
        targetRowIndex = rowEndCoordinates.length;
        rowEndCoordinates.add(visualRight);
      } else {
        rowEndCoordinates[targetRowIndex] = visualRight;
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
    final authState = ref.watch(googleAuthNotifierProvider);

    ref.listen<GoogleAuthState>(googleAuthNotifierProvider, (previous, next) {
      if (next.isInitialized && next.account != null && (previous == null || !previous.isInitialized)) {
        _checkInitialSync();
      }
    });

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
      body: Stack(
        children: [
          StreamBuilder<List<CalendarItem>>(
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
                color: theme.colorScheme.primary,
                child: IconTheme(
                  data: IconThemeData(color: theme.scaffoldBackgroundColor),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => _changeDay(-1),
                      ),
                      Text(
                        '${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.scaffoldBackgroundColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () => _changeDay(1),
                      ),
                    ],
                  ),
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
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: theme.colorScheme.primary,
                              width: 1.0,
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final viewportWidth = constraints.maxWidth;
                    final viewportHeight = constraints.maxHeight;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Listener(
                          onPointerMove: (event) {
                            _dragPointerX = event.position.dx;
                          },
                          onPointerUp: (_) => _dragPointerX = null,
                          onPointerCancel: (_) => _dragPointerX = null,
                          child: SingleChildScrollView(
                            key: _timelineViewportKey,
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

                                // Use true finger position (from Listener) for accurate
                                // edge detection — details.offset is the widget top-left,
                                // not the pointer, causing asymmetric triggers.
                                final x = _dragPointerX ?? details.offset.dx;
                                final screenWidth = MediaQuery.of(context).size.width;
                                if (x < 90) {
                                  _startAutoScroll(left: true);
                                } else if (x > screenWidth - 90) {
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
                                final timelineHeight = max(
                                  _headerHeight + maxRow * _rowHeight,
                                  viewportHeight,
                                );

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
                                      // Dot grid — fills the body area below the header
                                      Positioned(
                                        top: _headerHeight,
                                        left: 0,
                                        right: 0,
                                        bottom: 0,
                                        child: CustomPaint(
                                          painter: DotGridPainter(
                                            color: theme.colorScheme.primary,
                                            dotRadius: 0.8,
                                            spacingX: 24.0,
                                            spacingY: 24.0,
                                          ),
                                        ),
                                      ),

                                      // Grid lines
                                      Row(
                                        children: List.generate(24, (hour) {
                                          return SizedBox(
                                            width: hourWidths[hour],
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: DashedDivider(
                                                axis: Axis.vertical,
                                                dashWidth: 4,
                                                dashSpace: 4,
                                                strokeWidth: 1.2,
                                                color: theme.colorScheme.primary.withValues(alpha: 0.6),
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

                                      // Header line (Solid and thick)
                                      Positioned(
                                        top: _headerHeight - 2,
                                        left: 0,
                                        right: 0,
                                        child: Divider(
                                          height: 2,
                                          thickness: 2.0,
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
                                                140.0,
                                              );

                                              return Positioned(
                                                left: highlightLeft,
                                                width: highlightWidth,
                                                top: _headerHeight,
                                                bottom: 0,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: theme.colorScheme.primary
                                                        .withValues(alpha: 0.1),
                                                    border: Border.symmetric(
                                                      vertical: BorderSide(
                                                        color: theme.colorScheme.primary,
                                                        width: 1.0,
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

                        // Left & Right Overflow Badges
                        ValueListenableBuilder<double>(
                          valueListenable: _scrollOffsetNotifier,
                          builder: (context, scrollOffset, child) {
                            int leftCount = 0;
                            int rightCount = 0;
                            for (final pi in positionedItems) {
                              if (pi.item.isComplete) continue;
                              if (pi.left + pi.width < scrollOffset) {
                                leftCount++;
                              } else if (pi.left > scrollOffset + viewportWidth) {
                                rightCount++;
                              }
                            }

                            return Stack(
                              children: [
                                if (leftCount > 0)
                                  Positioned(
                                    left: 8,
                                    top: _headerHeight + 8,
                                    child: GestureDetector(
                                      onTap: () => _scrollTimeline(true, viewportWidth, positionedItems),
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
                                        alignment: Alignment.center,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: theme.scaffoldBackgroundColor,
                                            border: Border.all(color: theme.colorScheme.primary, width: 1.5),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text('← ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                              Text(
                                                '$leftCount',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (rightCount > 0)
                                  Positioned(
                                    right: 8,
                                    top: _headerHeight + 8,
                                    child: GestureDetector(
                                      onTap: () => _scrollTimeline(false, viewportWidth, positionedItems),
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
                                        alignment: Alignment.center,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: theme.scaffoldBackgroundColor,
                                            border: Border.all(color: theme.colorScheme.primary, width: 1.5),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '$rightCount',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const Text(' →', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),

              // 4. Overdue and Backlog trays anchored at the bottom
              const OverdueTrayWidget(),
              const BacklogTrayWidget(),
            ],
          );
        },
      ),
          if (!authState.isInitialized)
            Positioned.fill(
              child: Container(
                color: theme.scaffoldBackgroundColor,
                child: Center(
                  child: AlertDialog(
                    title: const Text(
                      'CONNECTING TO GOOGLE',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    content: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('[ PLEASE WAIT ]', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 16),
                        Text(
                          'Checking sign-in status...',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: authState.isInitialized
          ? FloatingActionButton(
              onPressed: () {
                // FAB creates a new task (no pre-filled time)
                ItemBottomSheet.show(context);
              },
              child: const Icon(Icons.add, size: 28),
            )
          : null,
    );
  }
}
