import 'package:googleapis/calendar/v3.dart' as cal;

enum CalendarItemType { task, event }

enum TaskCategory { work, personal, errand, none }

enum SyncStatus { synced, pendingCreate, pendingUpdate, pendingDelete }

class CalendarItem {
  final String localId;              // Local UUID (always exists)
  final String title;
  final String? description;         // Stored in GCal event description field
  final CalendarItemType type;       // task | event
  final String? googleEventId;       // GCal event ID (null while pending sync)
  final String googleCalendarId;     // "quicktasks" | external calendar ID
  final bool isExternalEvent;        // true = from another calendar, not QuickTasks
  final DateTime? startAt;
  final DateTime? endAt;              // For tasks: startAt + 30min default
  final bool isAllDay;
  final bool isComplete;             // Stored in extendedProperties + local SQLite
  final DateTime? completedAt;
  final TaskCategory category;       // Stored in extendedProperties + local SQLite
  final SyncStatus syncStatus;       // synced | pendingCreate | pendingUpdate | pendingDelete
  final DateTime createdAt;
  final DateTime updatedAt;

  CalendarItem({
    required this.localId,
    required this.title,
    this.description,
    required this.type,
    this.googleEventId,
    required this.googleCalendarId,
    required this.isExternalEvent,
    this.startAt,
    this.endAt,
    required this.isAllDay,
    required this.isComplete,
    this.completedAt,
    required this.category,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  CalendarItem copyWith({
    String? localId,
    String? title,
    String? description,
    CalendarItemType? type,
    String? googleEventId,
    String? googleCalendarId,
    bool? isExternalEvent,
    DateTime? startAt,
    DateTime? endAt,
    bool? isAllDay,
    bool? isComplete,
    DateTime? completedAt,
    TaskCategory? category,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarItem(
      localId: localId ?? this.localId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      googleEventId: googleEventId ?? this.googleEventId,
      googleCalendarId: googleCalendarId ?? this.googleCalendarId,
      isExternalEvent: isExternalEvent ?? this.isExternalEvent,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      isAllDay: isAllDay ?? this.isAllDay,
      isComplete: isComplete ?? this.isComplete,
      completedAt: completedAt ?? this.completedAt,
      category: category ?? this.category,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Returns a new `CalendarItem` with its schedule cleared (unscheduled backlog item).
  CalendarItem toUnscheduled() {
    return CalendarItem(
      localId: localId,
      title: title,
      description: description,
      type: type,
      googleEventId: googleEventId,
      googleCalendarId: googleCalendarId,
      isExternalEvent: isExternalEvent,
      startAt: null,
      endAt: null,
      isAllDay: isAllDay,
      isComplete: isComplete,
      completedAt: completedAt,
      category: category,
      syncStatus: syncStatus,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Converts a Google Calendar API `Event` into a `CalendarItem`.
  factory CalendarItem.fromGCalEvent(
    cal.Event event,
    String calendarId, {
    required bool isExternal,
    required String fallbackLocalId,
    SyncStatus? forceSyncStatus,
  }) {
    final privateProps = event.extendedProperties?.private ?? {};

    // Read the task/event flag
    final isTaskProp = privateProps['isTask'] ?? 'false';
    final type = isTaskProp == 'true' ? CalendarItemType.task : CalendarItemType.event;

    // Read completion properties
    var isComplete = privateProps['isComplete'] == 'true';
    final completedAtStr = privateProps['completedAt'];
    final completedAt = completedAtStr != null ? DateTime.tryParse(completedAtStr) : null;

    final summary = event.summary ?? '(Untitled)';
    String cleanTitle = summary;
    if (summary.toLowerCase().endsWith(' (done)')) {
      cleanTitle = summary.substring(0, summary.length - 7);
      isComplete = true;
      if (cleanTitle.trim().isEmpty) {
        cleanTitle = '(Untitled)';
      }
    }

    // Read category
    final categoryStr = privateProps['category'] ?? 'none';
    final category = TaskCategory.values.firstWhere(
      (e) => e.name == categoryStr,
      orElse: () => TaskCategory.none,
    );

    // Check if it is a backlog/unscheduled task
    final isBacklogProp = privateProps['isBacklog'] ?? 'false';

    // DateTimes
    DateTime? start;
    DateTime? end;
    bool isAllDay = false;

    if (isBacklogProp != 'true') {
      if (event.start?.dateTime != null) {
        start = event.start!.dateTime!.toLocal();
      } else if (event.start?.date != null) {
        start = event.start!.date!.toLocal();
        isAllDay = true;
      }

      if (event.end?.dateTime != null) {
        end = event.end!.dateTime!.toLocal();
      } else if (event.end?.date != null) {
        end = event.end!.date!.toLocal();
        isAllDay = true;
      }
    }

    final created = event.created ?? DateTime.now();
    final updated = event.updated ?? DateTime.now();

    return CalendarItem(
      localId: fallbackLocalId,
      title: cleanTitle,
      description: event.description,
      type: type,
      googleEventId: event.id,
      googleCalendarId: calendarId,
      isExternalEvent: isExternal,
      startAt: start,
      endAt: end,
      isAllDay: isAllDay,
      isComplete: isComplete,
      completedAt: completedAt,
      category: category,
      syncStatus: forceSyncStatus ?? SyncStatus.synced,
      createdAt: created.toLocal(),
      updatedAt: updated.toLocal(),
    );
  }

  /// Converts this `CalendarItem` into a Google Calendar API `Event`.
  cal.Event toGCalEvent() {
    final event = cal.Event();
    event.id = googleEventId;
    event.summary = isComplete ? '$title (done)' : title;
    event.description = description;

    final isBacklog = startAt == null || endAt == null;

    if (isBacklog) {
      // Dummy date-time for GCal API (which requires start/end)
      final dummyStart = DateTime.utc(1970, 1, 1, 0, 0, 0);
      final dummyEnd = DateTime.utc(1970, 1, 1, 0, 30, 0);
      event.start = cal.EventDateTime(dateTime: dummyStart);
      event.end = cal.EventDateTime(dateTime: dummyEnd);
    } else {
      if (isAllDay) {
        // For all-day events, GCal expects date strings 'YYYY-MM-DD'
        event.start = cal.EventDateTime(
          date: DateTime(startAt!.year, startAt!.month, startAt!.day),
        );
        event.end = cal.EventDateTime(
          date: DateTime(endAt!.year, endAt!.month, endAt!.day),
        );
      } else {
        event.start = cal.EventDateTime(dateTime: startAt!.toUtc());
        event.end = cal.EventDateTime(dateTime: endAt!.toUtc());
      }

      // Set a popup notification at the exact start time of the event
      event.reminders = cal.EventReminders(
        useDefault: false,
        overrides: [
          cal.EventReminder(
            method: 'popup',
            minutes: 0,
          ),
        ],
      );
    }

    // Set private properties for completion & task metadata
    event.extendedProperties = cal.EventExtendedProperties(
      private: {
        'isTask': type == CalendarItemType.task ? 'true' : 'false',
        'isComplete': isComplete ? 'true' : 'false',
        if (completedAt != null) 'completedAt': completedAt!.toUtc().toIso8601String(),
        'category': category.name,
        'isBacklog': isBacklog ? 'true' : 'false',
      },
    );

    return event;
  }
}
