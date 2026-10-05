import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

class PendingOps extends Table {
  TextColumn get clientOpId => text()();
  TextColumn get deviceId => text()();
  IntColumn get clientSeq => integer()();
  TextColumn get clientTs => text()();
  TextColumn get opType => text()();
  TextColumn get payload => text()();
  IntColumn get planVersion => integer()();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, syncing, applied, applied_with_conflict, rejected
  TextColumn get reason => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {clientOpId};
}

class CachedTrips extends Table {
  TextColumn get id => text()();
  TextColumn get role => text()(); // 'driver' or 'loader'
  TextColumn get depotId => text().nullable()();
  TextColumn get jsonData => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedStops extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text()();
  IntColumn get seq => integer()();
  TextColumn get jsonData => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [PendingOps, CachedTrips, CachedStops])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'waypoint_offline');
  }
}
