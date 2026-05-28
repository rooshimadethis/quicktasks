import 'dart:developer' as developer;
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/calendar/v3.dart' as cal;
import 'package:quicktasks/data/local/database.dart';
import 'package:quicktasks/data/local/calendar_item_dao.dart';
import 'package:quicktasks/data/remote/gcal_api_client.dart';
import 'package:quicktasks/domain/models/calendar_item.dart';

class CalendarItemRepository {
  final CalendarItemDao _dao;
  final _uuid = const Uuid();

  CalendarItemRepository(this._dao);

  /// Helper to convert DB entities to Domain Models.
  CalendarItem _mapEntityToModel(CalendarItemEntity entity) {
    return CalendarItem(
      localId: entity.localId,
      title: entity.title,
      description: entity.description,
      type: CalendarItemType.values.firstWhere(
        (e) => e.name == entity.type,
        orElse: () => CalendarItemType.task,
      ),
      googleEventId: entity.googleEventId,
      googleCalendarId: entity.googleCalendarId,
      isExternalEvent: entity.isExternalEvent,
      startAt: entity.startAt,
      endAt: entity.endAt,
      isAllDay: entity.isAllDay,
      isComplete: entity.isComplete,
      completedAt: entity.completedAt,
      category: TaskCategory.values.firstWhere(
        (e) => e.name == entity.category,
        orElse: () => TaskCategory.none,
      ),
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == entity.syncStatus,
        orElse: () => SyncStatus.synced,
      ),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Helper to convert Domain Models to DB entities.
  CalendarItemEntity _mapModelToEntity(CalendarItem item) {
    return CalendarItemEntity(
      localId: item.localId,
      title: item.title,
      description: item.description,
      type: item.type.name,
      googleEventId: item.googleEventId,
      googleCalendarId: item.googleCalendarId,
      isExternalEvent: item.isExternalEvent,
      startAt: item.startAt,
      endAt: item.endAt,
      isAllDay: item.isAllDay,
      isComplete: item.isComplete,
      completedAt: item.completedAt,
      category: item.category.name,
      syncStatus: item.syncStatus.name,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    );
  }

  /// Streams active (non-deleted) items within a date range, sorted by start time.
  Stream<List<CalendarItem>> watchItemsInWindow(DateTime start, DateTime end) {
    return _dao.watchItemsInWindow(start, end).map((entities) => entities
        .map(_mapEntityToModel)
        .where((item) => item.syncStatus != SyncStatus.pendingDelete)
        .toList());
  }

  /// Streams all active (non-deleted) items, sorted by start time.
  Stream<List<CalendarItem>> watchAllItems() {
    return _dao.watchAllItems().map((entities) => entities
        .map(_mapEntityToModel)
        .where((item) => item.syncStatus != SyncStatus.pendingDelete)
        .toList());
  }

  /// Streams all active backlog (unscheduled) items.
  Stream<List<CalendarItem>> watchBacklogItems() {
    return _dao.watchBacklogItems().map((entities) => entities
        .map(_mapEntityToModel)
        .where((item) => item.syncStatus != SyncStatus.pendingDelete)
        .toList());
  }

  /// Gets all active backlog (unscheduled) items.
  Future<List<CalendarItem>> getBacklogItems() async {
    final entities = await _dao.getBacklogItems();
    return entities
        .map(_mapEntityToModel)
        .where((item) => item.syncStatus != SyncStatus.pendingDelete)
        .toList();
  }

  /// Streams all incomplete tasks with a start time in the past.
  Stream<List<CalendarItem>> watchOverdueItems(DateTime now) {
    return _dao.watchOverdueItems(now).map((entities) => entities
        .map(_mapEntityToModel)
        .where((item) => item.syncStatus != SyncStatus.pendingDelete)
        .toList());
  }

  /// Retrieves active items in a date range.
  Future<List<CalendarItem>> getItemsInWindow(DateTime start, DateTime end) async {
    final entities = await _dao.getItemsInWindow(start, end);
    return entities
        .map(_mapEntityToModel)
        .where((item) => item.syncStatus != SyncStatus.pendingDelete)
        .toList();
  }

  /// Retrieves a calendar item by its local UUID.
  Future<CalendarItem?> getItemByLocalId(String localId) async {
    final entity = await _dao.getItemByLocalId(localId);
    if (entity == null) return null;
    final item = _mapEntityToModel(entity);
    return item.syncStatus == SyncStatus.pendingDelete ? null : item;
  }

  /// Creates a new item locally, setting its status to pending sync.
  Future<CalendarItem> createItem(CalendarItem item) async {
    final localId = item.localId.isEmpty ? _uuid.v4() : item.localId;
    final newItem = item.copyWith(
      localId: localId,
      syncStatus: SyncStatus.pendingCreate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _dao.insertItem(_mapModelToEntity(newItem));
    return newItem;
  }

  /// Updates an item locally, setting its status to pending update.
  Future<void> updateItem(CalendarItem item) async {
    final existing = await _dao.getItemByLocalId(item.localId);
    if (existing == null) {
      throw Exception('Cannot update item ${item.localId}; not found locally.');
    }

    final currentSyncStatus = SyncStatus.values.firstWhere(
      (e) => e.name == existing.syncStatus,
      orElse: () => SyncStatus.synced,
    );

    // If it's already pending create, keep it as pending create. Otherwise it's a pending update.
    final newSyncStatus = currentSyncStatus == SyncStatus.pendingCreate
        ? SyncStatus.pendingCreate
        : SyncStatus.pendingUpdate;

    final updated = item.copyWith(
      syncStatus: newSyncStatus,
      updatedAt: DateTime.now(),
    );

    await _dao.updateItem(_mapModelToEntity(updated));
  }

  /// Marks an item as pending deletion locally (soft-delete).
  /// If it hasn't been synced to GCal yet, deletes it immediately.
  Future<void> deleteItem(String localId) async {
    final existing = await _dao.getItemByLocalId(localId);
    if (existing == null) return;

    if (existing.syncStatus == SyncStatus.pendingCreate.name) {
      await _dao.deleteItem(localId);
    } else {
      final item = _mapEntityToModel(existing).copyWith(
        syncStatus: SyncStatus.pendingDelete,
        updatedAt: DateTime.now(),
      );
      await _dao.updateItem(_mapModelToEntity(item));
    }
  }

  /// Retries an asynchronous GCal API action in case of transient network/auth failures.
  Future<T> _retry<T>(
    Future<T> Function() action, {
    int retries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    while (true) {
      try {
        return await action();
      } catch (e) {
        attempts++;
        if (attempts >= retries) {
          rethrow;
        }
        developer.log('Sync action failed (attempt $attempts/$retries). Retrying...', error: e);
        await Future.delayed(delay * attempts);
      }
    }
  }

  /// Synchronizes local SQLite cache with remote Google Calendar API.
  /// This pushes local changes and pulls new events/updates.
  Future<void> sync(GCalApiClient apiClient) async {
    // 1. Fetch Calendar List from Google Calendar
    final calendarList = await _retry(() => apiClient.listCalendars());
    final calendars = calendarList.items ?? [];

    // 2. Identify or create the dedicated "QuickTasks" calendar
    String? quicktasksCalId;
    final quicktasksEntry = calendars.firstWhere(
      (c) => c.summary == 'QuickTasks',
      orElse: () => cal.CalendarListEntry(), // returns an empty entry instead of null
    );

    if (quicktasksEntry.id != null) {
      quicktasksCalId = quicktasksEntry.id;
    } else {
      final newCal = await _retry(() => apiClient.createCalendar('QuickTasks'));
      quicktasksCalId = newCal.id;
    }

    if (quicktasksCalId == null) {
      throw Exception('Failed to resolve or create QuickTasks calendar ID.');
    }

    // 3. Collect active calendars (QuickTasks + other selected calendars)
    final syncCalendarIds = <String>{quicktasksCalId};
    for (final entry in calendars) {
      if (entry.id != null && entry.selected == true) {
        syncCalendarIds.add(entry.id!);
      }
    }

    // 4. Push local changes (pendingCreate, pendingUpdate, pendingDelete)
    await _pushPendingChanges(apiClient, quicktasksCalId);

    // 5. Pull changes for each selected calendar (incremental / full window sync)
    for (final calendarId in syncCalendarIds) {
      final isQuickTasks = calendarId == quicktasksCalId;
      await _syncCalendar(apiClient, calendarId, isExternal: !isQuickTasks);
    }
  }

  /// Pushes all locally pending creations, updates, and deletions to Google Calendar.
  Future<void> _pushPendingChanges(GCalApiClient apiClient, String quicktasksCalId) async {
    final pendingEntities = await _dao.getPendingSyncItems();

    for (final entity in pendingEntities) {
      final item = _mapEntityToModel(entity);
      // Resolve "quicktasks" placeholder to the actual Google Calendar ID
      final calendarId = item.googleCalendarId == 'quicktasks'
          ? quicktasksCalId
          : item.googleCalendarId;

      try {
        if (item.syncStatus == SyncStatus.pendingCreate) {
          final responseEvent = await _retry(() => apiClient.insertEvent(calendarId, item.toGCalEvent()));
          final syncedItem = item.copyWith(
            googleEventId: responseEvent.id,
            googleCalendarId: calendarId,
            syncStatus: SyncStatus.synced,
            updatedAt: responseEvent.updated?.toLocal() ?? DateTime.now(),
          );
          await _dao.upsertItem(_mapModelToEntity(syncedItem));
        } else if (item.syncStatus == SyncStatus.pendingUpdate) {
          if (item.googleEventId != null) {
            final responseEvent = await _retry(() => apiClient.updateEvent(
              calendarId,
              item.googleEventId!,
              item.toGCalEvent(),
            ));
            final syncedItem = item.copyWith(
              syncStatus: SyncStatus.synced,
              updatedAt: responseEvent.updated?.toLocal() ?? DateTime.now(),
            );
            await _dao.upsertItem(_mapModelToEntity(syncedItem));
          }
        } else if (item.syncStatus == SyncStatus.pendingDelete) {
          if (item.googleEventId != null) {
            await _retry(() => apiClient.deleteEvent(calendarId, item.googleEventId!));
          }
          await _dao.deleteItem(item.localId);
        }
      } catch (e, stack) {
        developer.log('Error pushing pending sync item ${item.localId} to GCal', error: e, stackTrace: stack);
      }
    }
  }

  /// Syncs a single calendar by pulling changes from Google Calendar.
  Future<void> _syncCalendar(
    GCalApiClient apiClient,
    String calendarId, {
    required bool isExternal,
  }) async {
    final syncState = await _dao.getSyncState(calendarId);
    final storedToken = syncState?.syncToken;

    try {
      cal.Events eventsResponse;

      if (storedToken != null) {
        try {
          eventsResponse = await _retry(() => apiClient.listEvents(calendarId, syncToken: storedToken));
        } catch (e) {
          // GCal returns 410 Gone if a syncToken has expired or is invalid.
          if (e.toString().contains('410') || e.toString().contains('gone')) {
            eventsResponse = await _fetchFullWindow(apiClient, calendarId);
          } else {
            rethrow;
          }
        }
      } else {
        eventsResponse = await _fetchFullWindow(apiClient, calendarId);
      }

      final events = eventsResponse.items ?? [];
      final seenGoogleEventIds = <String>{};

      for (final event in events) {
        if (event.id == null) continue;

        if (event.status == 'cancelled') {
          // Remote deletion
          final existing = await _dao.getItemByGoogleEventId(event.id!);
          if (existing != null) {
            await _dao.deleteItem(existing.localId);
          }
        } else {
          seenGoogleEventIds.add(event.id!);
          final existingEntity = await _dao.getItemByGoogleEventId(event.id!);

          if (existingEntity != null) {
            final existing = _mapEntityToModel(existingEntity);
            final remoteUpdated = event.updated ?? DateTime.now();

            // Merge using last-write-wins
            if (remoteUpdated.isAfter(existing.updatedAt)) {
              // Only pull updates if local is not currently pending modifications
              if (existing.syncStatus == SyncStatus.synced) {
                final updatedItem = CalendarItem.fromGCalEvent(
                  event,
                  calendarId,
                  isExternal: isExternal,
                  fallbackLocalId: existing.localId,
                );
                await _dao.upsertItem(_mapModelToEntity(updatedItem));
              }
            }
          } else {
            // New remote event
            final newItem = CalendarItem.fromGCalEvent(
              event,
              calendarId,
              isExternal: isExternal,
              fallbackLocalId: _uuid.v4(),
            );
            await _dao.upsertItem(_mapModelToEntity(newItem));
          }
        }
      }

      // If we performed a full sync, purge any local synced items inside the window
      // that were deleted remotely and therefore not present in the GCal response.
      if (storedToken == null) {
        final now = DateTime.now();
        final windowStart = now.subtract(const Duration(days: 14));
        final windowEnd = now.add(const Duration(days: 56));
        final localItems = await _dao.getItemsInWindow(windowStart, windowEnd);

        for (final local in localItems) {
          if (local.googleCalendarId == calendarId &&
              local.googleEventId != null &&
              local.syncStatus == SyncStatus.synced.name &&
              !seenGoogleEventIds.contains(local.googleEventId)) {
            await _dao.deleteItem(local.localId);
          }
        }
      }

      // Save the updated sync token
      if (eventsResponse.nextSyncToken != null) {
        await _dao.upsertSyncState(CalendarSyncStateEntity(
          calendarId: calendarId,
          syncToken: eventsResponse.nextSyncToken!,
          lastSyncedAt: DateTime.now(),
        ));
      }
    } catch (e, stack) {
      developer.log('Error pulling events for calendar $calendarId', error: e, stackTrace: stack);
    }
  }

  /// Fetches events within the standard sliding window (past 2 weeks to next 8 weeks).
  Future<cal.Events> _fetchFullWindow(GCalApiClient apiClient, String calendarId) async {
    final now = DateTime.now();
    final timeMin = now.subtract(const Duration(days: 14)); // -2 weeks
    final timeMax = now.add(const Duration(days: 56));      // +8 weeks
    return await _retry(() => apiClient.listEvents(calendarId, timeMin: timeMin, timeMax: timeMax));
  }
}

final calendarItemRepositoryProvider = Provider<CalendarItemRepository>((ref) {
  final dao = ref.watch(calendarItemDaoProvider);
  return CalendarItemRepository(dao);
});
