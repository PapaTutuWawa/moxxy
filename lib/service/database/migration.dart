import 'package:logging/logging.dart';

/// A function to be called when a migration should be performed.
typedef DatabaseMigrationCallback<T> = Future<void> Function(T);

/// This class represents a single database migration.
class DatabaseMigration<T> {
  const DatabaseMigration(this.version, this.migration);

  /// The version this migration upgrades the database to.
  final int version;

  /// The migration callback. Called the the database version is less than [version].
  final DatabaseMigrationCallback<T> migration;
}

/// Given the database [db] with the current version [version], goes through the list of
/// migrations [migrations] and applies all migrations with a version greater than
/// [version]. [migrations] is sorted before usage.
///
/// NOTE: This entire setup is written as a generic to make testing easier. We cannot easily
///       mock, or better "instantiate", a Database object. Thus, to avoid having nullable
///       database argument, just pass in whatever (the tests use an integer).
Future<void> runMigrations<T>(
  Logger log,
  T db,
  List<DatabaseMigration<T>> migrations,
  int version,
) async {
  final sortedMigrations = List<DatabaseMigration<T>>.from(migrations)
    ..sort(
      (a, b) => a.version.compareTo(b.version),
    );
  var currentVersion = version;
  for (final migration in sortedMigrations) {
    if (version < migration.version) {
      log.info(
        'Running database migration $currentVersion -> ${migration.version}',
      );
      await migration.migration(db);
      currentVersion = migration.version;
    }
  }
}
