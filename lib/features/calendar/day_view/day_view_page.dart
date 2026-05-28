import 'dart:math';
import 'package:flutter/material.dart';
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
  final double top;
  final double height;
  double left = 0.0;
  double width = 1.0;

  PositionedItem({
    required this.item,
    required this.top,
    required this.height,
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
  final double _slotHeight = 70.0;
  final double _timelineHourHeight = 140.0; // 2 slots * 70dp

  // State for hold + drag gesture creation
  int? _dragStartSlot;
  int? _dragCurrentSlot;
  
  late ScrollController _scrollController;
  DateTime? _lastAutoScrolledDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _scrollController = ScrollController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialSync();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

    final targetOffset = earliestHour * _timelineHourHeight;
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

  Future<void> _checkInitialSync() async {
    final dao = ref.read(calendarItemDaoProvider);
    final hasSynced = await dao.hasAnySyncToken();
    if (!hasSynced) {
      await _runSyncWithProgress('Syncing your Google Calendar events for the first time. Please wait...');
    }
  }

  void _changeDay(int days) {
    setState(() {
      _selectedDay = _selectedDay.add(Duration(days: days));
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _selectedDay = DateTime(now.year, now.month, now.day);
    });
  }

  int _getSlotIndexFromOffset(double localY) {
    return (localY / _slotHeight).floor().clamp(0, 47);
  }

  Future<void> _triggerManualSync() async {
    await _runSyncWithProgress('Refreshing calendar data. Please wait...');
  }

  List<PositionedItem> _layoutItems(List<CalendarItem> items) {
    final list = <PositionedItem>[];
    for (final item in items) {
      if (item.startAt == null || item.endAt == null || item.isAllDay) continue;

      final start = item.startAt!;
      final end = item.endAt!;
      
      // Calculate top and height relative to the 24 hour timeline
      final startDec = start.hour + start.minute / 60.0;
      final endDec = end.hour + end.minute / 60.0;
      
      final top = startDec * _timelineHourHeight;
      // Ensure minimum height of 56.0 for readability/tap targets
      final height = max((endDec - startDec) * _timelineHourHeight, 56.0);

      list.add(PositionedItem(item: item, top: top, height: height));
    }

    // Sort by top (start time), then height descending
    list.sort((a, b) {
      if (a.top != b.top) return a.top.compareTo(b.top);
      return b.height.compareTo(a.height);
    });

    // Simple overlapping columns grouping
    final groups = <List<PositionedItem>>[];
    for (final pi in list) {
      List<PositionedItem>? targetGroup;
      for (final group in groups) {
        final overlaps = group.any((other) {
          final aStart = pi.top;
          final aEnd = pi.top + pi.height;
          final bStart = other.top;
          final bEnd = other.top + other.height;
          return aStart < bEnd && bStart < aEnd;
        });
        if (overlaps) {
          targetGroup = group;
          break;
        }
      }

      if (targetGroup == null) {
        targetGroup = [];
        groups.add(targetGroup);
      }
      targetGroup.add(pi);
    }

    for (final group in groups) {
      final columns = <List<PositionedItem>>[];
      for (final pi in group) {
        int colIndex = 0;
        while (colIndex < columns.length) {
          final col = columns[colIndex];
          final overlaps = col.any((other) {
            final aStart = pi.top;
            final aEnd = pi.top + pi.height;
            final bStart = other.top;
            final bEnd = other.top + other.height;
            return aStart < bEnd && bStart < aEnd;
          });
          if (!overlaps) {
            break;
          }
          colIndex++;
        }

        if (colIndex >= columns.length) {
          columns.add([]);
        }
        columns[colIndex].add(pi);
      }

      final totalCols = columns.length;
      for (int i = 0; i < totalCols; i++) {
        for (final pi in columns[i]) {
          pi.left = i / totalCols;
          pi.width = 1.0 / totalCols;
        }
      }
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
    final weekdays = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
    final months = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', 
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
    ];
    final dateStr = '${weekdays[_selectedDay.weekday - 1]}, ${months[_selectedDay.month - 1]} ${_selectedDay.day}';

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          final positionedItems = _layoutItems(timelineItems);

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
                  border: Border(bottom: BorderSide(color: theme.colorScheme.primary, width: 1.5)),
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
                    border: Border(bottom: BorderSide(color: theme.colorScheme.primary, width: 1.5)),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allDayItems.map((item) {
                      return InkWell(
                        onTap: () => ItemBottomSheet.show(context, initialItem: item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.primary, width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('📅 ', style: TextStyle(fontSize: 12)),
                              Text(
                                item.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
                  child: GestureDetector(
                    onLongPressStart: (details) {
                      setState(() {
                        _dragStartSlot = _getSlotIndexFromOffset(details.localPosition.dy);
                        _dragCurrentSlot = _dragStartSlot;
                      });
                    },
                    onLongPressMoveUpdate: (details) {
                      setState(() {
                        _dragCurrentSlot = _getSlotIndexFromOffset(details.localPosition.dy);
                      });
                    },
                    onLongPressEnd: (details) {
                      if (_dragStartSlot != null && _dragCurrentSlot != null) {
                        final startSlot = min(_dragStartSlot!, _dragCurrentSlot!);
                        final endSlot = max(_dragStartSlot!, _dragCurrentSlot!);
                        
                        final startHour = startSlot ~/ 2;
                        final startMin = (startSlot % 2) * 30;
                        final endHour = (endSlot + 1) ~/ 2;
                        final endMin = ((endSlot + 1) % 2) * 30;

                        final startPrefill = DateTime(
                          _selectedDay.year, _selectedDay.month, _selectedDay.day, 
                          startHour, startMin
                        );
                        final endPrefill = DateTime(
                          _selectedDay.year, _selectedDay.month, _selectedDay.day, 
                          endHour, endMin
                        );

                        // Trigger sheet with Event prefilled duration
                        ItemBottomSheet.show(
                          context, 
                          prefilledStart: startPrefill,
                          prefilledEnd: endPrefill,
                        );
                      }
                      setState(() {
                        _dragStartSlot = null;
                        _dragCurrentSlot = null;
                      });
                    },
                    child: Stack(
                      children: [
                        // Background Slots & Gridlines
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 48,
                          itemBuilder: (context, index) {
                            final hour = index ~/ 2;
                            final minute = (index % 2) * 30;
                            final slotTime = DateTime(
                              _selectedDay.year, _selectedDay.month, _selectedDay.day,
                              hour, minute
                            );

                            return DragTarget<CalendarItem>(
                              onWillAcceptWithDetails: (details) => true,
                              onAcceptWithDetails: (details) async {
                                final item = details.data;
                                final duration = item.endAt != null && item.startAt != null
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
                                final isOver = candidateData.isNotEmpty;
                                final isHourHeader = index % 2 == 0;
                                final timeLabel = isHourHeader 
                                    ? '${hour == 0 || hour == 12 ? 12 : hour % 12}:${minute.toString().padLeft(2, '0')} ${hour < 12 ? 'AM' : 'PM'}'
                                    : '';

                                return Container(
                                  height: _slotHeight,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: theme.colorScheme.primary.withValues(alpha: isHourHeader ? 0.3 : 0.1),
                                        width: isHourHeader ? 1.2 : 0.8,
                                      ),
                                    ),
                                    color: isOver ? theme.colorScheme.primary.withValues(alpha: 0.05) : Colors.transparent,
                                  ),
                                  child: Row(
                                    children: [
                                      // Time Slot Column
                                      Container(
                                        width: 75,
                                        padding: const EdgeInsets.only(left: 8.0),
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          timeLabel,
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const VerticalDivider(width: 1, thickness: 1.2),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            ItemBottomSheet.show(context, prefilledStart: slotTime);
                                          },
                                          child: const SizedBox.expand(),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),

                        // Hold-Drag visual highlight
                        if (_dragStartSlot != null && _dragCurrentSlot != null)
                          Positioned(
                            left: 76,
                            right: 0,
                            top: min(_dragStartSlot!, _dragCurrentSlot!) * _slotHeight,
                            height: (max(_dragStartSlot!, _dragCurrentSlot!) - min(_dragStartSlot!, _dragCurrentSlot!) + 1) * _slotHeight,
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                border: Border.all(color: theme.colorScheme.primary, width: 2.0),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'CREATING EVENT...',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),

                        // Positioned Foreground Event/Task Chips
                        ...positionedItems.map((pi) {
                          // Left margin offsets from time column (76dp)
                          const leftOffset = 76.0;
                          return Positioned(
                            left: leftOffset + pi.left * (MediaQuery.of(context).size.width - leftOffset),
                            width: pi.width * (MediaQuery.of(context).size.width - leftOffset) - 4, // 4px padding
                            top: pi.top,
                            height: pi.height,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 2.0),
                              child: CalendarItemChip(
                                item: pi.item,
                                onTap: () => ItemBottomSheet.show(context, initialItem: pi.item),
                                onComplete: () async {
                                  final updated = pi.item.copyWith(
                                    isComplete: !pi.item.isComplete,
                                    completedAt: !pi.item.isComplete ? DateTime.now() : null,
                                  );
                                  await repo.updateItem(updated);
                                  ref.read(googleCalendarServiceProvider).sync();
                                },
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
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
