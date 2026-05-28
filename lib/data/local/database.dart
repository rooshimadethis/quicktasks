import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

part 'database.g.dart';

@DataClassName('CalendarItemEntity')
class CalendarItems extends Table {
  TextColumn get localId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get type => text()(); // Store CalendarItemType enum name
  TextColumn get googleEventId => text().nullable()();
  TextColumn get googleCalendarId => text()();
  BoolColumn get isExternalEvent => boolean()();
  DateTimeColumn get startAt => dateTime().nullable()();
  DateTimeColumn get endAt => dateTime().nullable()();
  BoolColumn get isAllDay => boolean()();
  BoolColumn get isComplete => boolean()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get category => text()(); // Store TaskCategory enum name
  TextColumn get syncStatus => text()(); // Store SyncStatus enum name
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {localId};
}

@DataClassName('CalendarSyncStateEntity')
class CalendarSyncStates extends Table {
  TextColumn get calendarId => text()();
  TextColumn get syncToken => text()();
  DateTimeColumn get lastSyncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {calendarId};
}

@DriftDatabase(tables: [CalendarItems, CalendarSyncStates])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          await m.drop(calendarItems);
          await m.drop(calendarSyncStates);
          await m.createAll();
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'quicktasks.db'));

    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    final cachebase = await getTemporaryDirectory();
    sqlite3.tempDirectory = cachebase.path;

    return NativeDatabase.createInBackground(file);
  });
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
