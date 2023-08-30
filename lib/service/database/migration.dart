import 'package:logging/logging.dart';

/// A function to be called when a migration should be performed.
typedef MigrationCallback<T> = Future<void> Function(T);

/// This class represents a single database migration.
class Migration<T> {
  const Migration(this.version, this.migration);

  /// The version this migration upgrades the database to.
  final int version;

  /// The migration callback. Called the the database version is less than [version].
  final MigrationCallback<T> migration;
}

/// Given the migration [param], which is passed to every migration, with the current version
/// [version], goes through the list of
/// migrations [migrations] and applies all migrations with a version greater than
/// [version]. [migrations] is sorted before usage.
///
/// NOTE: This entire setup is written as a generic to make testing easier. We cannot easily
///       mock, or better "instantiate", a Database object. Thus, to avoid having nullable
///       database argument, just pass in whatever (the tests use an integer).
Future<void> runMigrations<T>(
  Logger log,
  T param,
  List<Migration<T>> migrations,
  int version,
  String typeName, {
  Future<void> Function(int)? commitVersion,
}) async {
  final sortedMigrations = List<Migration<T>>.from(migrations)
    ..sort(
      (a, b) => a.version.compareTo(b.version),
    );
  var currentVersion = version;
  var hasRunMigration = false;
  for (final migration in sortedMigrations) {
    if (version < migration.version) {
      log.info(
        'Running $typeName migration $currentVersion -> ${migration.version}',
      );
      await migration.migration(param);
      currentVersion = migration.version;
      hasRunMigration = true;
    }
  }

  // Commit the version, if specified.
  if (commitVersion != null && hasRunMigration) {
    log.info('Committing migration version $currentVersion');
    await commitVersion(currentVersion);
  }
}
