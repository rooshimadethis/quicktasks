import 'package:flutter/material.dart';
import 'package:quicktasks/domain/models/calendar_item.dart';

class CalendarItemChip extends StatelessWidget {
  final CalendarItem item;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onReschedule;

  const CalendarItemChip({
    super.key,
    required this.item,
    this.onTap,
    this.onComplete,
    this.onReschedule,
  });

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
    final isTask = item.type == CalendarItemType.task;
    final categoryShape = isTask ? _getCategoryShape(item.category) : '';
    
    // Complete visual: strikethrough title
    final titleStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.bold,
      decoration: item.isComplete ? TextDecoration.lineThrough : null,
      decorationThickness: 2.0,
    );

    // Build the leading checkmark toggle for both tasks and events
    final leadingWidget = SizedBox(
      width: 32,
      height: 32,
      child: Checkbox(
        value: item.isComplete,
        onChanged: (_) => onComplete?.call(),
      ),
    );

    // Build external event indicator badge
    Widget? trailingWidget;
    if (item.isExternalEvent) {
      trailingWidget = const Padding(
        padding: EdgeInsets.only(left: 4.0),
        child: Text('📅', style: TextStyle(fontSize: 14)),
      );
    }

    final childWidget = InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor, // solid bg to prevent overlap transparency
          border: Border.all(color: theme.colorScheme.primary, width: 1.5),
        ),
        constraints: const BoxConstraints(minHeight: 56.0), // minimum tap target 56dp
        child: Row(
          children: [
            leadingWidget,
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$categoryShape${item.title}',
                style: titleStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailingWidget != null) trailingWidget,
          ],
        ),
      ),
    );

    // Wrap in Dismissible for swipe-left (complete) and swipe-right (reschedule)
    // If the item is already complete, we only allow swipe-right (reschedule)
    return Dismissible(
      key: Key(item.localId),
      direction: item.isComplete ? DismissDirection.startToEnd : DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Swipe left -> Complete
          if (onComplete != null) onComplete!();
        } else if (direction == DismissDirection.startToEnd) {
          // Swipe right -> Reschedule
          if (onReschedule != null) onReschedule!();
        }
        return false; // Return false to not remove from tree (the update handles redraw)
      },
      background: Container(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20.0),
        child: const Icon(Icons.access_time, size: 28),
      ),
      secondaryBackground: Container(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(Icons.check, size: 28),
      ),
      child: childWidget,
    );
  }
}
