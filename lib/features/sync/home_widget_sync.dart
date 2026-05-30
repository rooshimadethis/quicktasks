import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:quicktasks/app/router.dart';
import 'package:quicktasks/domain/models/calendar_item.dart';
import 'package:quicktasks/domain/repositories/calendar_item_repository.dart';

/// A provider that listens to today's tasks and synchronizes them to the
/// Android home screen widget via SharedPreferences, and also handles
/// widget click events to deep link to task editing.
final homeWidgetSyncProvider = Provider<void>((ref) {
  final repo = ref.watch(calendarItemRepositoryProvider);

  // Listen to widget click URIs and route to the edit sheet
  Future<void> handleWidgetUri(Uri? uri) async {
    if (uri != null && uri.scheme == 'quicktasks') {
      final isTask = uri.host == 'task' || uri.path == '/task';
      if (isTask) {
        final taskId = uri.queryParameters['id'];
        if (taskId != null) {
          developer.log('Received widget click for task: $taskId. Redirecting to edit...');
          final router = ref.read(routerProvider);
          router.go('/day?edit=$taskId');
        }
      }
    }
  }

  // Check if app was initially launched from a widget click
  HomeWidget.initiallyLaunchedFromHomeWidget().then(handleWidgetUri);

  // Listen to widget click stream while app is running/in background
  final clickSubscription = HomeWidget.widgetClicked.listen(handleWidgetUri);

  // Calculate today's bounds (00:00:00 to 23:59:59)
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));

  // Watch the items for today
  final todayItemsStream = repo.watchItemsInWindow(todayStart, todayEnd);

  // Listen to the stream and update HomeWidget when it emits new data
  final subscription = todayItemsStream.listen((items) async {
    // Filter to only tasks (type == CalendarItemType.task) and not deleted
    final todayTasks = items
        .where((item) =>
            item.type == CalendarItemType.task &&
            item.syncStatus != SyncStatus.pendingDelete)
        .toList();

    // Sort tasks: incomplete first, then by scheduled time (startAt), then by title
    todayTasks.sort((a, b) {
      if (a.isComplete != b.isComplete) {
        return a.isComplete ? 1 : -1;
      }
      if (a.startAt != b.startAt) {
        if (a.startAt == null) return 1;
        if (b.startAt == null) return -1;
        return a.startAt!.compareTo(b.startAt!);
      }
      return a.title.compareTo(b.title);
    });

    final List<Map<String, dynamic>> jsonList = todayTasks.map((task) {
      String timeStr = '';
      if (task.isAllDay) {
        timeStr = 'All Day';
      } else if (task.startAt != null) {
        final start = task.startAt!;
        final hour = start.hour;
        final minute = start.minute.toString().padLeft(2, '0');
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        timeStr = '$displayHour:$minute $period';
      }

      return {
        'localId': task.localId,
        'title': task.title,
        'isComplete': task.isComplete,
        'category': task.category.name,
        'timeString': timeStr,
      };
    }).toList();

    try {
      final jsonStr = jsonEncode(jsonList);
      developer.log('Syncing ${jsonList.length} tasks to HomeWidget');

      await HomeWidget.saveWidgetData<String>('tasks_json', jsonStr);
      await HomeWidget.updateWidget(
        name: 'TaskListWidgetProvider',
        androidName: 'TaskListWidgetProvider',
      );
    } catch (e, stack) {
      developer.log('Error syncing to HomeWidget', error: e, stackTrace: stack);
    }
  });

  ref.onDispose(() {
    subscription.cancel();
    clickSubscription.cancel();
  });
});
