import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quicktasks/domain/models/calendar_item.dart';
import 'package:quicktasks/domain/repositories/calendar_item_repository.dart';
import 'package:quicktasks/features/backlog/backlog_drawer.dart';
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
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialSync();
    });
  }

  Future<void> _checkInitialSync() async {
    final dao = ref.read(calendarItemDaoProvider);
    final hasSynced = await dao.hasAnySyncToken();
    if (!hasSynced) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const PopScope(
            canPop: false,
            child: AlertDialog(
              title: Text('INITIAL SYNC', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Syncing your Google Calendar events for the first time. Please wait...',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      );

      final success = await ref.read(googleCalendarServiceProvider).sync();

      if (mounted) {
        Navigator.pop(context); // Dismiss dialog
        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Initial sync failed. Please try triggering it manually.'),
            ),
          );
        }
      }
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
    setState(() {
      _isSyncing = true;
    });
    final success = await ref.read(googleCalendarServiceProvider).sync();
    if (mounted) {
      setState(() {
        _isSyncing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Sync completed successfully.' : 'Sync failed. Check logs.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
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

  void _showQuickRescheduleMenu(CalendarItem item) {
    final repo = ref.read(calendarItemRepositoryProvider);
    final syncService = ref.read(googleCalendarServiceProvider);

    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text('RESCHEDULE: ${item.title.toUpperCase()}'),
          children: [
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(context);
                if (item.startAt != null && item.endAt != null) {
                  final updated = item.copyWith(
                    startAt: item.startAt!.add(const Duration(minutes: 30)),
                    endAt: item.endAt!.add(const Duration(minutes: 30)),
                  );
                  await repo.updateItem(updated);
                  syncService.sync();
                }
              },
              child: const Text('+30 MINUTES'),
            ),
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(context);
                if (item.startAt != null && item.endAt != null) {
                  final updated = item.copyWith(
                    startAt: item.startAt!.add(const Duration(hours: 1)),
                    endAt: item.endAt!.add(const Duration(hours: 1)),
                  );
                  await repo.updateItem(updated);
                  syncService.sync();
                }
              },
              child: const Text('+1 HOUR'),
            ),
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(context);
                if (item.startAt != null && item.endAt != null) {
                  final updated = item.copyWith(
                    startAt: item.startAt!.add(const Duration(hours: 3)),
                    endAt: item.endAt!.add(const Duration(hours: 3)),
                  );
                  await repo.updateItem(updated);
                  syncService.sync();
                }
              },
              child: const Text('+3 HOURS'),
            ),
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(context);
                if (item.startAt != null && item.endAt != null) {
                  final updated = item.copyWith(
                    startAt: item.startAt!.add(const Duration(days: 1)),
                    endAt: item.endAt!.add(const Duration(days: 1)),
                  );
                  await repo.updateItem(updated);
                  syncService.sync();
                }
              },
              child: const Text('TOMORROW'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                ItemBottomSheet.show(context, initialItem: item);
              },
              child: const Text('PICK TIME...'),
            ),
          ],
        );
      },
    );
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
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: _isSyncing 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync),
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
      drawer: const BacklogDrawer(),
      body: StreamBuilder<List<CalendarItem>>(
        stream: itemsStream,
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          final allDayItems = items.where((i) => i.isAllDay).toList();
          final timelineItems = items.where((i) => !i.isAllDay).toList();
          final positionedItems = _layoutItems(timelineItems);

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
                              onWillAcceptWithDetails: (details) => details.data.type == CalendarItemType.task,
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
                                onReschedule: () => _showQuickRescheduleMenu(pi.item),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Overdue tray anchored at the bottom
              const OverdueTrayWidget(),
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
