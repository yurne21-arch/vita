import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

part 'app_database.g.dart';

/// Caché local del perfil. La fuente de verdad es Supabase; esto es solo caché.
@DataClassName('CachedProfile')
class CachedProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text().nullable()();
  TextColumn get locale => text().nullable()();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cola de escrituras pendientes (patrón outbox). Esqueleto en el Sprint 0.
@DataClassName('OutboxEntry')
class OutboxEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entity => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
}

@DriftDatabase(tables: [CachedProfiles, OutboxEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'vita'));

  @override
  int get schemaVersion => 1;
}

/// Abre la base local SOLO en plataformas nativas (Android/iOS). En Web
/// devuelve null: el caché local queda deshabilitado y la app usa Supabase
/// como fuente de verdad. Así la versión web nunca se cae al iniciar.
AppDatabase? openLocalDatabaseOrNull() {
  if (kIsWeb) return null;
  try {
    return AppDatabase();
  } catch (_) {
    return null;
  }
}
