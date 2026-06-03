import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quicktasks/domain/models/calendar_item.dart';

class CalendarItemChip extends StatelessWidget {
  final CalendarItem item;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onComplete;

  const CalendarItemChip({
    super.key,
    required this.item,
    this.onTap,
    this.onDoubleTap,
    this.onComplete,
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
      fontSize: 14,
      decoration: item.isComplete ? TextDecoration.lineThrough : null,
      decorationThickness: item.isComplete ? 2.0 : null,
    );

    // Build the leading checkmark toggle for both tasks and events
    final leadingWidget = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {}, // Prevents tap propagation to the parent InkWell
      child: SizedBox(
        width: 32,
        height: 32,
        child: Checkbox(
          value: item.isComplete,
          onChanged: (_) {
            HapticFeedback.lightImpact();
            onComplete?.call();
          },
        ),
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

    return InkWell(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor, // solid bg to prevent overlap transparency
          border: Border.all(color: theme.colorScheme.primary, width: 1.0),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary,
              offset: const Offset(3.0, 3.0),
              blurRadius: 0.0,
              spreadRadius: 0.0,
            ),
          ],
        ),
        constraints: const BoxConstraints(minHeight: 56.0), // minimum tap target 56dp
        child: Row(
          children: [
            leadingWidget,
            const SizedBox(width: 4),
            Container(
              width: 1.0,
              height: 32,
              color: theme.colorScheme.secondary,
            ),
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
  }
}
