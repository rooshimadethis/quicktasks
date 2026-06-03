import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quicktasks/domain/models/calendar_item.dart';
import 'package:quicktasks/domain/repositories/calendar_item_repository.dart';
import 'package:quicktasks/features/items/item_bottom_sheet.dart';
import 'package:quicktasks/features/sync/google_calendar_service.dart';

class OverdueTrayWidget extends ConsumerStatefulWidget {
  const OverdueTrayWidget({super.key});

  @override
  ConsumerState<OverdueTrayWidget> createState() => _OverdueTrayWidgetState();
}

class _OverdueTrayWidgetState extends ConsumerState<OverdueTrayWidget> {
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

  void _showFullOverdueSheet(
    BuildContext context,
    List<CalendarItem> items,
    ThemeData theme,
    CalendarItemRepository repo,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Consumer(
              builder: (context, ref, child) {
                final now = DateTime.now();
                final startOfToday = DateTime(now.year, now.month, now.day);
                final overdueStream = ref.watch(calendarItemRepositoryProvider).watchOverdueItems(startOfToday);

                return StreamBuilder<List<CalendarItem>>(
                  stream: overdueStream,
                  builder: (context, snapshot) {
                    final currentItems = snapshot.data ?? items;

                    return Container(
                      padding: const EdgeInsets.all(16.0),
                      color: theme.scaffoldBackgroundColor,
                      child: Column(
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '⚠️ ALL OVERDUE ITEMS (${currentItems.length})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.pop(context);
                                },
                                child: const Text('CLOSE'),
                              ),
                            ],
                          ),
                          const Divider(height: 2.0, thickness: 2.0),
                          const SizedBox(height: 16),

                          // List
                          Expanded(
                            child: currentItems.isEmpty
                                ? const Center(
                                    child: Text(
                                      'NO OVERDUE ITEMS',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  )
                                : ListView.separated(
                                    controller: scrollController,
                                    itemCount: currentItems.length,
                                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final item = currentItems[index];
                                      final categoryShape = _getCategoryShape(item.category);

                                      return Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: theme.colorScheme.primary, width: 1.0),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.pop(context); // Close before showing details
                                            ItemBottomSheet.show(context, initialItem: item);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Row(
                                              children: [
                                                GestureDetector(
                                                  behavior: HitTestBehavior.opaque,
                                                  onTap: () {}, // Prevent propagation
                                                  child: Checkbox(
                                                    value: item.isComplete,
                                                    onChanged: (val) async {
                                                      if (val != null) {
                                                        HapticFeedback.lightImpact();
                                                        final updated = item.copyWith(
                                                          isComplete: val,
                                                          completedAt: val ? DateTime.now() : null,
                                                        );
                                                        await repo.updateItem(updated);
                                                        ref.read(googleCalendarServiceProvider).sync();
                                                      }
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    '$categoryShape${item.title}',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                      decoration: null,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = ref.watch(calendarItemRepositoryProvider);
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final overdueStream = repo.watchOverdueItems(startOfToday);

    return StreamBuilder<List<CalendarItem>>(
      stream: overdueStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(color: theme.colorScheme.primary, width: 2.0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _showFullOverdueSheet(context, items, theme, repo);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    border: Border.all(color: theme.colorScheme.primary, width: 1.0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '⚠️ OVERDUE ITEMS',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${items.length} items)',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.keyboard_arrow_up,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 192),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  scrollDirection: Axis.vertical,
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final categoryShape = _getCategoryShape(item.category);

                    return LongPressDraggable<CalendarItem>(
                      data: item,
                      maxSimultaneousDrags: 1,
                      delay: const Duration(milliseconds: 300), // ~300ms hold threshold
                      onDragStarted: () {
                        HapticFeedback.mediumImpact();
                      },
                      feedback: Material(
                        color: Colors.transparent,
                        child: Opacity(
                          opacity: 0.85,
                          child: Container(
                            width: MediaQuery.of(context).size.width - 32,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.scaffoldBackgroundColor,
                              border: Border.all(color: theme.colorScheme.primary, width: 1.0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: item.isComplete,
                                  onChanged: null,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '$categoryShape${item.title}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: Container(
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.primary, width: 1.0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: item.isComplete,
                                onChanged: null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$categoryShape${item.title}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          // Tap opens the quick reschedule sheet / full edit sheet
                          ItemBottomSheet.show(context, initialItem: item);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.primary, width: 1.0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {}, // Prevents tap propagation to the parent InkWell
                                child: SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: Checkbox(
                                    value: item.isComplete,
                                    onChanged: (val) async {
                                      if (val != null) {
                                        HapticFeedback.lightImpact();
                                        final updated = item.copyWith(
                                          isComplete: val,
                                          completedAt: val ? DateTime.now() : null,
                                        );
                                        await repo.updateItem(updated);
                                        ref.read(googleCalendarServiceProvider).sync();
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$categoryShape${item.title}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
