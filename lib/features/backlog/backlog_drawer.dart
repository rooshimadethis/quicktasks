import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quicktasks/domain/models/calendar_item.dart';
import 'package:quicktasks/domain/repositories/calendar_item_repository.dart';
import 'package:quicktasks/features/items/item_bottom_sheet.dart';

class BacklogDrawer extends ConsumerWidget {
  const BacklogDrawer({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final backlogStream = ref.watch(calendarItemRepositoryProvider).watchBacklogItems();

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'BACKLOG',
                style: theme.textTheme.titleLarge?.copyWith(letterSpacing: 1.2),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<List<CalendarItem>>(
                stream: backlogStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final items = snapshot.data ?? [];

                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          'No unscheduled items.',
                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(12.0),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final categoryShape = _getCategoryShape(item.category);

                      return InkWell(
                        onTap: () {
                          // Tap opens the edit bottom sheet where the user can schedule it
                          Navigator.pop(context); // Close the drawer first
                          ItemBottomSheet.show(context, initialItem: item);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.primary, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '$categoryShape${item.title}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Icon(Icons.chevron_right, size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
