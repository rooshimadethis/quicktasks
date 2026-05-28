import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quicktasks/data/local/database.dart';

class CalendarItemDao {
  final AppDatabase _db;

  CalendarItemDao(this._db);

  /// Streams all calendar items, sorted by start time.
  Stream<List<CalendarItemEntity>> watchAllItems() {
    return (_db.select(_db.calendarItems)
          ..orderBy([
            (t) => OrderingTerm(expression: t.startAt, mode: OrderingMode.asc)
          ]))
        .watch();
  }

  /// Streams calendar items that overlap with the given window, sorted by start time.
  Stream<List<CalendarItemEntity>> watchItemsInWindow(DateTime start, DateTime end) {
    return (_db.select(_db.calendarItems)
          ..where((t) => t.startAt.isSmallerThanValue(end) & t.endAt.isBiggerThanValue(start))
          ..orderBy([
            (t) => OrderingTerm(expression: t.startAt, mode: OrderingMode.asc)
          ]))
        .watch();
  }

  /// Gets all calendar items that overlap with the given window as a Future.
  Future<List<CalendarItemEntity>> getItemsInWindow(DateTime start, DateTime end) {
    return (_db.select(_db.calendarItems)
          ..where((t) => t.startAt.isSmallerThanValue(end) & t.endAt.isBiggerThanValue(start))
          ..orderBy([
            (t) => OrderingTerm(expression: t.startAt, mode: OrderingMode.asc)
          ]))
        .get();
  }

  /// Finds a single item by its local UUID.
  Future<CalendarItemEntity?> getItemByLocalId(String localId) {
    return (_db.select(_db.calendarItems)
          ..where((t) => t.localId.equals(localId)))
        .getSingleOrNull();
  }

  /// Finds a single item by its Google Calendar Event ID.
  Future<CalendarItemEntity?> getItemByGoogleEventId(String googleEventId) {
    return (_db.select(_db.calendarItems)
          ..where((t) => t.googleEventId.equals(googleEventId)))
        .getSingleOrNull();
  }

  /// Retrieves all items that have local modifications pending sync.
  Future<List<CalendarItemEntity>> getPendingSyncItems() {
    return (_db.select(_db.calendarItems)
          ..where((t) => t.syncStatus.equals('synced').not()))
        .get();
  }

  /// Inserts a new local calendar item.
  Future<int> insertItem(CalendarItemEntity entity) {
    return _db.into(_db.calendarItems).insert(entity);
  }

  /// Updates an existing local calendar item.
  Future<bool> updateItem(CalendarItemEntity entity) {
    return _db.update(_db.calendarItems).replace(entity);
  }

  /// Inserts or updates a calendar item (upsert).
  Future<int> upsertItem(CalendarItemEntity entity) {
    return _db.into(_db.calendarItems).insertOnConflictUpdate(entity);
  }

  /// Deletes a calendar item from the local cache.
  Future<int> deleteItem(String localId) {
    return (_db.delete(_db.calendarItems)
          ..where((t) => t.localId.equals(localId)))
        .go();
  }

  /// Gets the synchronization state (like `syncToken`) for a specific calendar.
  Future<CalendarSyncStateEntity?> getSyncState(String calendarId) {
    return (_db.select(_db.calendarSyncStates)
          ..where((t) => t.calendarId.equals(calendarId)))
        .getSingleOrNull();
  }

  /// Upserts the synchronization state for a calendar.
  Future<int> upsertSyncState(CalendarSyncStateEntity entity) {
    return _db.into(_db.calendarSyncStates).insertOnConflictUpdate(entity);
  }

  /// Deletes the sync state of a calendar.
  Future<int> deleteSyncState(String calendarId) {
    return (_db.delete(_db.calendarSyncStates)
          ..where((t) => t.calendarId.equals(calendarId)))
        .go();
  }
}

final calendarItemDaoProvider = Provider<CalendarItemDao>((ref) {
  final db = ref.watch(databaseProvider);
  return CalendarItemDao(db);
});
