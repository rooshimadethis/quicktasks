import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quicktasks/domain/models/calendar_item.dart';
import 'package:quicktasks/domain/repositories/calendar_item_repository.dart';
import 'package:quicktasks/features/items/item_bottom_sheet.dart';

class OverdueTrayWidget extends ConsumerStatefulWidget {
  const OverdueTrayWidget({super.key});

  @override
  ConsumerState<OverdueTrayWidget> createState() => _OverdueTrayWidgetState();
}

class _OverdueTrayWidgetState extends ConsumerState<OverdueTrayWidget> {
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
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
    final overdueStream = repo.watchOverdueItems(_now);

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
              top: BorderSide(color: theme.colorScheme.primary, width: 1.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '⚠️ OVERDUE TASKS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${items.length} items)',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final categoryShape = _getCategoryShape(item.category);

                    return LongPressDraggable<CalendarItem>(
                      data: item,
                      maxSimultaneousDrags: 1,
                      delay: const Duration(milliseconds: 300), // ~300ms hold threshold
                      feedback: Material(
                        color: Colors.transparent,
                        child: Opacity(
                          opacity: 0.85,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.scaffoldBackgroundColor,
                              border: Border.all(color: theme.colorScheme.primary, width: 1.5),
                            ),
                            child: Text(
                              '$categoryShape${item.title}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.primary, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$categoryShape${item.title}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          // Tap opens the quick reschedule sheet / full edit sheet
                          ItemBottomSheet.show(context, initialItem: item);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.primary, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$categoryShape${item.title}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
