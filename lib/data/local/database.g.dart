// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CalendarItemsTable extends CalendarItems
    with TableInfo<$CalendarItemsTable, CalendarItemEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalendarItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _googleEventIdMeta = const VerificationMeta(
    'googleEventId',
  );
  @override
  late final GeneratedColumn<String> googleEventId = GeneratedColumn<String>(
    'google_event_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _googleCalendarIdMeta = const VerificationMeta(
    'googleCalendarId',
  );
  @override
  late final GeneratedColumn<String> googleCalendarId = GeneratedColumn<String>(
    'google_calendar_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isExternalEventMeta = const VerificationMeta(
    'isExternalEvent',
  );
  @override
  late final GeneratedColumn<bool> isExternalEvent = GeneratedColumn<bool>(
    'is_external_event',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_external_event" IN (0, 1))',
    ),
  );
  static const VerificationMeta _startAtMeta = const VerificationMeta(
    'startAt',
  );
  @override
  late final GeneratedColumn<DateTime> startAt = GeneratedColumn<DateTime>(
    'start_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endAtMeta = const VerificationMeta('endAt');
  @override
  late final GeneratedColumn<DateTime> endAt = GeneratedColumn<DateTime>(
    'end_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isAllDayMeta = const VerificationMeta(
    'isAllDay',
  );
  @override
  late final GeneratedColumn<bool> isAllDay = GeneratedColumn<bool>(
    'is_all_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_all_day" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isCompleteMeta = const VerificationMeta(
    'isComplete',
  );
  @override
  late final GeneratedColumn<bool> isComplete = GeneratedColumn<bool>(
    'is_complete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_complete" IN (0, 1))',
    ),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    title,
    description,
    type,
    googleEventId,
    googleCalendarId,
    isExternalEvent,
    startAt,
    endAt,
    isAllDay,
    isComplete,
    completedAt,
    category,
    syncStatus,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calendar_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<CalendarItemEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('google_event_id')) {
      context.handle(
        _googleEventIdMeta,
        googleEventId.isAcceptableOrUnknown(
          data['google_event_id']!,
          _googleEventIdMeta,
        ),
      );
    }
    if (data.containsKey('google_calendar_id')) {
      context.handle(
        _googleCalendarIdMeta,
        googleCalendarId.isAcceptableOrUnknown(
          data['google_calendar_id']!,
          _googleCalendarIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_googleCalendarIdMeta);
    }
    if (data.containsKey('is_external_event')) {
      context.handle(
        _isExternalEventMeta,
        isExternalEvent.isAcceptableOrUnknown(
          data['is_external_event']!,
          _isExternalEventMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isExternalEventMeta);
    }
    if (data.containsKey('start_at')) {
      context.handle(
        _startAtMeta,
        startAt.isAcceptableOrUnknown(data['start_at']!, _startAtMeta),
      );
    }
    if (data.containsKey('end_at')) {
      context.handle(
        _endAtMeta,
        endAt.isAcceptableOrUnknown(data['end_at']!, _endAtMeta),
      );
    }
    if (data.containsKey('is_all_day')) {
      context.handle(
        _isAllDayMeta,
        isAllDay.isAcceptableOrUnknown(data['is_all_day']!, _isAllDayMeta),
      );
    } else if (isInserting) {
      context.missing(_isAllDayMeta);
    }
    if (data.containsKey('is_complete')) {
      context.handle(
        _isCompleteMeta,
        isComplete.isAcceptableOrUnknown(data['is_complete']!, _isCompleteMeta),
      );
    } else if (isInserting) {
      context.missing(_isCompleteMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  CalendarItemEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalendarItemEntity(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      googleEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}google_event_id'],
      ),
      googleCalendarId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}google_calendar_id'],
      )!,
      isExternalEvent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_external_event'],
      )!,
      startAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_at'],
      ),
      endAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_at'],
      ),
      isAllDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_all_day'],
      )!,
      isComplete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_complete'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CalendarItemsTable createAlias(String alias) {
    return $CalendarItemsTable(attachedDatabase, alias);
  }
}

class CalendarItemEntity extends DataClass
    implements Insertable<CalendarItemEntity> {
  final String localId;
  final String title;
  final String? description;
  final String type;
  final String? googleEventId;
  final String googleCalendarId;
  final bool isExternalEvent;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool isAllDay;
  final bool isComplete;
  final DateTime? completedAt;
  final String category;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CalendarItemEntity({
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
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || googleEventId != null) {
      map['google_event_id'] = Variable<String>(googleEventId);
    }
    map['google_calendar_id'] = Variable<String>(googleCalendarId);
    map['is_external_event'] = Variable<bool>(isExternalEvent);
    if (!nullToAbsent || startAt != null) {
      map['start_at'] = Variable<DateTime>(startAt);
    }
    if (!nullToAbsent || endAt != null) {
      map['end_at'] = Variable<DateTime>(endAt);
    }
    map['is_all_day'] = Variable<bool>(isAllDay);
    map['is_complete'] = Variable<bool>(isComplete);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['category'] = Variable<String>(category);
    map['sync_status'] = Variable<String>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CalendarItemsCompanion toCompanion(bool nullToAbsent) {
    return CalendarItemsCompanion(
      localId: Value(localId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      type: Value(type),
      googleEventId: googleEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(googleEventId),
      googleCalendarId: Value(googleCalendarId),
      isExternalEvent: Value(isExternalEvent),
      startAt: startAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startAt),
      endAt: endAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endAt),
      isAllDay: Value(isAllDay),
      isComplete: Value(isComplete),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      category: Value(category),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CalendarItemEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalendarItemEntity(
      localId: serializer.fromJson<String>(json['localId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      type: serializer.fromJson<String>(json['type']),
      googleEventId: serializer.fromJson<String?>(json['googleEventId']),
      googleCalendarId: serializer.fromJson<String>(json['googleCalendarId']),
      isExternalEvent: serializer.fromJson<bool>(json['isExternalEvent']),
      startAt: serializer.fromJson<DateTime?>(json['startAt']),
      endAt: serializer.fromJson<DateTime?>(json['endAt']),
      isAllDay: serializer.fromJson<bool>(json['isAllDay']),
      isComplete: serializer.fromJson<bool>(json['isComplete']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      category: serializer.fromJson<String>(json['category']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'type': serializer.toJson<String>(type),
      'googleEventId': serializer.toJson<String?>(googleEventId),
      'googleCalendarId': serializer.toJson<String>(googleCalendarId),
      'isExternalEvent': serializer.toJson<bool>(isExternalEvent),
      'startAt': serializer.toJson<DateTime?>(startAt),
      'endAt': serializer.toJson<DateTime?>(endAt),
      'isAllDay': serializer.toJson<bool>(isAllDay),
      'isComplete': serializer.toJson<bool>(isComplete),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'category': serializer.toJson<String>(category),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CalendarItemEntity copyWith({
    String? localId,
    String? title,
    Value<String?> description = const Value.absent(),
    String? type,
    Value<String?> googleEventId = const Value.absent(),
    String? googleCalendarId,
    bool? isExternalEvent,
    Value<DateTime?> startAt = const Value.absent(),
    Value<DateTime?> endAt = const Value.absent(),
    bool? isAllDay,
    bool? isComplete,
    Value<DateTime?> completedAt = const Value.absent(),
    String? category,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CalendarItemEntity(
    localId: localId ?? this.localId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    type: type ?? this.type,
    googleEventId: googleEventId.present
        ? googleEventId.value
        : this.googleEventId,
    googleCalendarId: googleCalendarId ?? this.googleCalendarId,
    isExternalEvent: isExternalEvent ?? this.isExternalEvent,
    startAt: startAt.present ? startAt.value : this.startAt,
    endAt: endAt.present ? endAt.value : this.endAt,
    isAllDay: isAllDay ?? this.isAllDay,
    isComplete: isComplete ?? this.isComplete,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    category: category ?? this.category,
    syncStatus: syncStatus ?? this.syncStatus,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CalendarItemEntity copyWithCompanion(CalendarItemsCompanion data) {
    return CalendarItemEntity(
      localId: data.localId.present ? data.localId.value : this.localId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      type: data.type.present ? data.type.value : this.type,
      googleEventId: data.googleEventId.present
          ? data.googleEventId.value
          : this.googleEventId,
      googleCalendarId: data.googleCalendarId.present
          ? data.googleCalendarId.value
          : this.googleCalendarId,
      isExternalEvent: data.isExternalEvent.present
          ? data.isExternalEvent.value
          : this.isExternalEvent,
      startAt: data.startAt.present ? data.startAt.value : this.startAt,
      endAt: data.endAt.present ? data.endAt.value : this.endAt,
      isAllDay: data.isAllDay.present ? data.isAllDay.value : this.isAllDay,
      isComplete: data.isComplete.present
          ? data.isComplete.value
          : this.isComplete,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      category: data.category.present ? data.category.value : this.category,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalendarItemEntity(')
          ..write('localId: $localId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('googleEventId: $googleEventId, ')
          ..write('googleCalendarId: $googleCalendarId, ')
          ..write('isExternalEvent: $isExternalEvent, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('isAllDay: $isAllDay, ')
          ..write('isComplete: $isComplete, ')
          ..write('completedAt: $completedAt, ')
          ..write('category: $category, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    title,
    description,
    type,
    googleEventId,
    googleCalendarId,
    isExternalEvent,
    startAt,
    endAt,
    isAllDay,
    isComplete,
    completedAt,
    category,
    syncStatus,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalendarItemEntity &&
          other.localId == this.localId &&
          other.title == this.title &&
          other.description == this.description &&
          other.type == this.type &&
          other.googleEventId == this.googleEventId &&
          other.googleCalendarId == this.googleCalendarId &&
          other.isExternalEvent == this.isExternalEvent &&
          other.startAt == this.startAt &&
          other.endAt == this.endAt &&
          other.isAllDay == this.isAllDay &&
          other.isComplete == this.isComplete &&
          other.completedAt == this.completedAt &&
          other.category == this.category &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CalendarItemsCompanion extends UpdateCompanion<CalendarItemEntity> {
  final Value<String> localId;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> type;
  final Value<String?> googleEventId;
  final Value<String> googleCalendarId;
  final Value<bool> isExternalEvent;
  final Value<DateTime?> startAt;
  final Value<DateTime?> endAt;
  final Value<bool> isAllDay;
  final Value<bool> isComplete;
  final Value<DateTime?> completedAt;
  final Value<String> category;
  final Value<String> syncStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CalendarItemsCompanion({
    this.localId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.type = const Value.absent(),
    this.googleEventId = const Value.absent(),
    this.googleCalendarId = const Value.absent(),
    this.isExternalEvent = const Value.absent(),
    this.startAt = const Value.absent(),
    this.endAt = const Value.absent(),
    this.isAllDay = const Value.absent(),
    this.isComplete = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.category = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CalendarItemsCompanion.insert({
    required String localId,
    required String title,
    this.description = const Value.absent(),
    required String type,
    this.googleEventId = const Value.absent(),
    required String googleCalendarId,
    required bool isExternalEvent,
    this.startAt = const Value.absent(),
    this.endAt = const Value.absent(),
    required bool isAllDay,
    required bool isComplete,
    this.completedAt = const Value.absent(),
    required String category,
    required String syncStatus,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : localId = Value(localId),
       title = Value(title),
       type = Value(type),
       googleCalendarId = Value(googleCalendarId),
       isExternalEvent = Value(isExternalEvent),
       isAllDay = Value(isAllDay),
       isComplete = Value(isComplete),
       category = Value(category),
       syncStatus = Value(syncStatus),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CalendarItemEntity> custom({
    Expression<String>? localId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? type,
    Expression<String>? googleEventId,
    Expression<String>? googleCalendarId,
    Expression<bool>? isExternalEvent,
    Expression<DateTime>? startAt,
    Expression<DateTime>? endAt,
    Expression<bool>? isAllDay,
    Expression<bool>? isComplete,
    Expression<DateTime>? completedAt,
    Expression<String>? category,
    Expression<String>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (type != null) 'type': type,
      if (googleEventId != null) 'google_event_id': googleEventId,
      if (googleCalendarId != null) 'google_calendar_id': googleCalendarId,
      if (isExternalEvent != null) 'is_external_event': isExternalEvent,
      if (startAt != null) 'start_at': startAt,
      if (endAt != null) 'end_at': endAt,
      if (isAllDay != null) 'is_all_day': isAllDay,
      if (isComplete != null) 'is_complete': isComplete,
      if (completedAt != null) 'completed_at': completedAt,
      if (category != null) 'category': category,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CalendarItemsCompanion copyWith({
    Value<String>? localId,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? type,
    Value<String?>? googleEventId,
    Value<String>? googleCalendarId,
    Value<bool>? isExternalEvent,
    Value<DateTime?>? startAt,
    Value<DateTime?>? endAt,
    Value<bool>? isAllDay,
    Value<bool>? isComplete,
    Value<DateTime?>? completedAt,
    Value<String>? category,
    Value<String>? syncStatus,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CalendarItemsCompanion(
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
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (googleEventId.present) {
      map['google_event_id'] = Variable<String>(googleEventId.value);
    }
    if (googleCalendarId.present) {
      map['google_calendar_id'] = Variable<String>(googleCalendarId.value);
    }
    if (isExternalEvent.present) {
      map['is_external_event'] = Variable<bool>(isExternalEvent.value);
    }
    if (startAt.present) {
      map['start_at'] = Variable<DateTime>(startAt.value);
    }
    if (endAt.present) {
      map['end_at'] = Variable<DateTime>(endAt.value);
    }
    if (isAllDay.present) {
      map['is_all_day'] = Variable<bool>(isAllDay.value);
    }
    if (isComplete.present) {
      map['is_complete'] = Variable<bool>(isComplete.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalendarItemsCompanion(')
          ..write('localId: $localId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('googleEventId: $googleEventId, ')
          ..write('googleCalendarId: $googleCalendarId, ')
          ..write('isExternalEvent: $isExternalEvent, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('isAllDay: $isAllDay, ')
          ..write('isComplete: $isComplete, ')
          ..write('completedAt: $completedAt, ')
          ..write('category: $category, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CalendarSyncStatesTable extends CalendarSyncStates
    with TableInfo<$CalendarSyncStatesTable, CalendarSyncStateEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalendarSyncStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _calendarIdMeta = const VerificationMeta(
    'calendarId',
  );
  @override
  late final GeneratedColumn<String> calendarId = GeneratedColumn<String>(
    'calendar_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncTokenMeta = const VerificationMeta(
    'syncToken',
  );
  @override
  late final GeneratedColumn<String> syncToken = GeneratedColumn<String>(
    'sync_token',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [calendarId, syncToken, lastSyncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calendar_sync_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<CalendarSyncStateEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('calendar_id')) {
      context.handle(
        _calendarIdMeta,
        calendarId.isAcceptableOrUnknown(data['calendar_id']!, _calendarIdMeta),
      );
    } else if (isInserting) {
      context.missing(_calendarIdMeta);
    }
    if (data.containsKey('sync_token')) {
      context.handle(
        _syncTokenMeta,
        syncToken.isAcceptableOrUnknown(data['sync_token']!, _syncTokenMeta),
      );
    } else if (isInserting) {
      context.missing(_syncTokenMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSyncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {calendarId};
  @override
  CalendarSyncStateEntity map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalendarSyncStateEntity(
      calendarId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}calendar_id'],
      )!,
      syncToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_token'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      )!,
    );
  }

  @override
  $CalendarSyncStatesTable createAlias(String alias) {
    return $CalendarSyncStatesTable(attachedDatabase, alias);
  }
}

class CalendarSyncStateEntity extends DataClass
    implements Insertable<CalendarSyncStateEntity> {
  final String calendarId;
  final String syncToken;
  final DateTime lastSyncedAt;
  const CalendarSyncStateEntity({
    required this.calendarId,
    required this.syncToken,
    required this.lastSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['calendar_id'] = Variable<String>(calendarId);
    map['sync_token'] = Variable<String>(syncToken);
    map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    return map;
  }

  CalendarSyncStatesCompanion toCompanion(bool nullToAbsent) {
    return CalendarSyncStatesCompanion(
      calendarId: Value(calendarId),
      syncToken: Value(syncToken),
      lastSyncedAt: Value(lastSyncedAt),
    );
  }

  factory CalendarSyncStateEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalendarSyncStateEntity(
      calendarId: serializer.fromJson<String>(json['calendarId']),
      syncToken: serializer.fromJson<String>(json['syncToken']),
      lastSyncedAt: serializer.fromJson<DateTime>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'calendarId': serializer.toJson<String>(calendarId),
      'syncToken': serializer.toJson<String>(syncToken),
      'lastSyncedAt': serializer.toJson<DateTime>(lastSyncedAt),
    };
  }

  CalendarSyncStateEntity copyWith({
    String? calendarId,
    String? syncToken,
    DateTime? lastSyncedAt,
  }) => CalendarSyncStateEntity(
    calendarId: calendarId ?? this.calendarId,
    syncToken: syncToken ?? this.syncToken,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
  );
  CalendarSyncStateEntity copyWithCompanion(CalendarSyncStatesCompanion data) {
    return CalendarSyncStateEntity(
      calendarId: data.calendarId.present
          ? data.calendarId.value
          : this.calendarId,
      syncToken: data.syncToken.present ? data.syncToken.value : this.syncToken,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalendarSyncStateEntity(')
          ..write('calendarId: $calendarId, ')
          ..write('syncToken: $syncToken, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(calendarId, syncToken, lastSyncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalendarSyncStateEntity &&
          other.calendarId == this.calendarId &&
          other.syncToken == this.syncToken &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class CalendarSyncStatesCompanion
    extends UpdateCompanion<CalendarSyncStateEntity> {
  final Value<String> calendarId;
  final Value<String> syncToken;
  final Value<DateTime> lastSyncedAt;
  final Value<int> rowid;
  const CalendarSyncStatesCompanion({
    this.calendarId = const Value.absent(),
    this.syncToken = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CalendarSyncStatesCompanion.insert({
    required String calendarId,
    required String syncToken,
    required DateTime lastSyncedAt,
    this.rowid = const Value.absent(),
  }) : calendarId = Value(calendarId),
       syncToken = Value(syncToken),
       lastSyncedAt = Value(lastSyncedAt);
  static Insertable<CalendarSyncStateEntity> custom({
    Expression<String>? calendarId,
    Expression<String>? syncToken,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (calendarId != null) 'calendar_id': calendarId,
      if (syncToken != null) 'sync_token': syncToken,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CalendarSyncStatesCompanion copyWith({
    Value<String>? calendarId,
    Value<String>? syncToken,
    Value<DateTime>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return CalendarSyncStatesCompanion(
      calendarId: calendarId ?? this.calendarId,
      syncToken: syncToken ?? this.syncToken,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (calendarId.present) {
      map['calendar_id'] = Variable<String>(calendarId.value);
    }
    if (syncToken.present) {
      map['sync_token'] = Variable<String>(syncToken.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalendarSyncStatesCompanion(')
          ..write('calendarId: $calendarId, ')
          ..write('syncToken: $syncToken, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CalendarItemsTable calendarItems = $CalendarItemsTable(this);
  late final $CalendarSyncStatesTable calendarSyncStates =
      $CalendarSyncStatesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    calendarItems,
    calendarSyncStates,
  ];
}

typedef $$CalendarItemsTableCreateCompanionBuilder =
    CalendarItemsCompanion Function({
      required String localId,
      required String title,
      Value<String?> description,
      required String type,
      Value<String?> googleEventId,
      required String googleCalendarId,
      required bool isExternalEvent,
      Value<DateTime?> startAt,
      Value<DateTime?> endAt,
      required bool isAllDay,
      required bool isComplete,
      Value<DateTime?> completedAt,
      required String category,
      required String syncStatus,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CalendarItemsTableUpdateCompanionBuilder =
    CalendarItemsCompanion Function({
      Value<String> localId,
      Value<String> title,
      Value<String?> description,
      Value<String> type,
      Value<String?> googleEventId,
      Value<String> googleCalendarId,
      Value<bool> isExternalEvent,
      Value<DateTime?> startAt,
      Value<DateTime?> endAt,
      Value<bool> isAllDay,
      Value<bool> isComplete,
      Value<DateTime?> completedAt,
      Value<String> category,
      Value<String> syncStatus,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CalendarItemsTableFilterComposer
    extends Composer<_$AppDatabase, $CalendarItemsTable> {
  $$CalendarItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get googleEventId => $composableBuilder(
    column: $table.googleEventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get googleCalendarId => $composableBuilder(
    column: $table.googleCalendarId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isExternalEvent => $composableBuilder(
    column: $table.isExternalEvent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAllDay => $composableBuilder(
    column: $table.isAllDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isComplete => $composableBuilder(
    column: $table.isComplete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CalendarItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $CalendarItemsTable> {
  $$CalendarItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get googleEventId => $composableBuilder(
    column: $table.googleEventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get googleCalendarId => $composableBuilder(
    column: $table.googleCalendarId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isExternalEvent => $composableBuilder(
    column: $table.isExternalEvent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAllDay => $composableBuilder(
    column: $table.isAllDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isComplete => $composableBuilder(
    column: $table.isComplete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CalendarItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalendarItemsTable> {
  $$CalendarItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get googleEventId => $composableBuilder(
    column: $table.googleEventId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get googleCalendarId => $composableBuilder(
    column: $table.googleCalendarId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isExternalEvent => $composableBuilder(
    column: $table.isExternalEvent,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startAt =>
      $composableBuilder(column: $table.startAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endAt =>
      $composableBuilder(column: $table.endAt, builder: (column) => column);

  GeneratedColumn<bool> get isAllDay =>
      $composableBuilder(column: $table.isAllDay, builder: (column) => column);

  GeneratedColumn<bool> get isComplete => $composableBuilder(
    column: $table.isComplete,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CalendarItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CalendarItemsTable,
          CalendarItemEntity,
          $$CalendarItemsTableFilterComposer,
          $$CalendarItemsTableOrderingComposer,
          $$CalendarItemsTableAnnotationComposer,
          $$CalendarItemsTableCreateCompanionBuilder,
          $$CalendarItemsTableUpdateCompanionBuilder,
          (
            CalendarItemEntity,
            BaseReferences<
              _$AppDatabase,
              $CalendarItemsTable,
              CalendarItemEntity
            >,
          ),
          CalendarItemEntity,
          PrefetchHooks Function()
        > {
  $$CalendarItemsTableTableManager(_$AppDatabase db, $CalendarItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalendarItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalendarItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalendarItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> googleEventId = const Value.absent(),
                Value<String> googleCalendarId = const Value.absent(),
                Value<bool> isExternalEvent = const Value.absent(),
                Value<DateTime?> startAt = const Value.absent(),
                Value<DateTime?> endAt = const Value.absent(),
                Value<bool> isAllDay = const Value.absent(),
                Value<bool> isComplete = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalendarItemsCompanion(
                localId: localId,
                title: title,
                description: description,
                type: type,
                googleEventId: googleEventId,
                googleCalendarId: googleCalendarId,
                isExternalEvent: isExternalEvent,
                startAt: startAt,
                endAt: endAt,
                isAllDay: isAllDay,
                isComplete: isComplete,
                completedAt: completedAt,
                category: category,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localId,
                required String title,
                Value<String?> description = const Value.absent(),
                required String type,
                Value<String?> googleEventId = const Value.absent(),
                required String googleCalendarId,
                required bool isExternalEvent,
                Value<DateTime?> startAt = const Value.absent(),
                Value<DateTime?> endAt = const Value.absent(),
                required bool isAllDay,
                required bool isComplete,
                Value<DateTime?> completedAt = const Value.absent(),
                required String category,
                required String syncStatus,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CalendarItemsCompanion.insert(
                localId: localId,
                title: title,
                description: description,
                type: type,
                googleEventId: googleEventId,
                googleCalendarId: googleCalendarId,
                isExternalEvent: isExternalEvent,
                startAt: startAt,
                endAt: endAt,
                isAllDay: isAllDay,
                isComplete: isComplete,
                completedAt: completedAt,
                category: category,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CalendarItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CalendarItemsTable,
      CalendarItemEntity,
      $$CalendarItemsTableFilterComposer,
      $$CalendarItemsTableOrderingComposer,
      $$CalendarItemsTableAnnotationComposer,
      $$CalendarItemsTableCreateCompanionBuilder,
      $$CalendarItemsTableUpdateCompanionBuilder,
      (
        CalendarItemEntity,
        BaseReferences<_$AppDatabase, $CalendarItemsTable, CalendarItemEntity>,
      ),
      CalendarItemEntity,
      PrefetchHooks Function()
    >;
typedef $$CalendarSyncStatesTableCreateCompanionBuilder =
    CalendarSyncStatesCompanion Function({
      required String calendarId,
      required String syncToken,
      required DateTime lastSyncedAt,
      Value<int> rowid,
    });
typedef $$CalendarSyncStatesTableUpdateCompanionBuilder =
    CalendarSyncStatesCompanion Function({
      Value<String> calendarId,
      Value<String> syncToken,
      Value<DateTime> lastSyncedAt,
      Value<int> rowid,
    });

class $$CalendarSyncStatesTableFilterComposer
    extends Composer<_$AppDatabase, $CalendarSyncStatesTable> {
  $$CalendarSyncStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get calendarId => $composableBuilder(
    column: $table.calendarId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncToken => $composableBuilder(
    column: $table.syncToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CalendarSyncStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $CalendarSyncStatesTable> {
  $$CalendarSyncStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get calendarId => $composableBuilder(
    column: $table.calendarId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncToken => $composableBuilder(
    column: $table.syncToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CalendarSyncStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalendarSyncStatesTable> {
  $$CalendarSyncStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get calendarId => $composableBuilder(
    column: $table.calendarId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncToken =>
      $composableBuilder(column: $table.syncToken, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );
}

class $$CalendarSyncStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CalendarSyncStatesTable,
          CalendarSyncStateEntity,
          $$CalendarSyncStatesTableFilterComposer,
          $$CalendarSyncStatesTableOrderingComposer,
          $$CalendarSyncStatesTableAnnotationComposer,
          $$CalendarSyncStatesTableCreateCompanionBuilder,
          $$CalendarSyncStatesTableUpdateCompanionBuilder,
          (
            CalendarSyncStateEntity,
            BaseReferences<
              _$AppDatabase,
              $CalendarSyncStatesTable,
              CalendarSyncStateEntity
            >,
          ),
          CalendarSyncStateEntity,
          PrefetchHooks Function()
        > {
  $$CalendarSyncStatesTableTableManager(
    _$AppDatabase db,
    $CalendarSyncStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalendarSyncStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalendarSyncStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalendarSyncStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> calendarId = const Value.absent(),
                Value<String> syncToken = const Value.absent(),
                Value<DateTime> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalendarSyncStatesCompanion(
                calendarId: calendarId,
                syncToken: syncToken,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String calendarId,
                required String syncToken,
                required DateTime lastSyncedAt,
                Value<int> rowid = const Value.absent(),
              }) => CalendarSyncStatesCompanion.insert(
                calendarId: calendarId,
                syncToken: syncToken,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CalendarSyncStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CalendarSyncStatesTable,
      CalendarSyncStateEntity,
      $$CalendarSyncStatesTableFilterComposer,
      $$CalendarSyncStatesTableOrderingComposer,
      $$CalendarSyncStatesTableAnnotationComposer,
      $$CalendarSyncStatesTableCreateCompanionBuilder,
      $$CalendarSyncStatesTableUpdateCompanionBuilder,
      (
        CalendarSyncStateEntity,
        BaseReferences<
          _$AppDatabase,
          $CalendarSyncStatesTable,
          CalendarSyncStateEntity
        >,
      ),
      CalendarSyncStateEntity,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CalendarItemsTableTableManager get calendarItems =>
      $$CalendarItemsTableTableManager(_db, _db.calendarItems);
  $$CalendarSyncStatesTableTableManager get calendarSyncStates =>
      $$CalendarSyncStatesTableTableManager(_db, _db.calendarSyncStates);
}
