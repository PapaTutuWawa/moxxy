class Migration<T> {

  Migration(this.version, this.migrationFunction);
  final int version;
  /// Return a version that is upgraded to the newest version.
  final T Function(Map<String, dynamic>) migrationFunction;

  bool canMigrate(int version) => version <= this.version;  
}

abstract class Migrator<T> {

  Migrator(this.latestVersion, this.migrations) {
    migrations.sort((a, b) => -1 * a.version.compareTo(b.version));
  }
  final int latestVersion;
  final List<Migration<T>> migrations;

  /// Override: Return the raw data or null if not set yet.
  Future<Map<String, dynamic>?> loadRawData();

  /// Override: Return the version or null if not set yet.
  Future<int?> loadVersion();
  
  /// Override: Return [T] from [data] if the data is already at the newest version.
  T fromData(Map<String, dynamic> data);

  /// Override: If no data is available
  T fromDefault();

  /// Override: Commit the latest version and data back to the store.
  Future<void> commit(int version, T data);
  
  Future<T> load() async {
    final version = await loadVersion();
    final data = await loadRawData();
    if (version == null || data == null) {
      final ret = fromDefault();
      await commit(latestVersion, ret);
      return ret;
    }
    
    if (version == latestVersion) return fromData(data);

    for (final migration in migrations) {
      if (migration.canMigrate(version)) {
        final ret = migration.migrationFunction(data);
        await commit(latestVersion, ret);
        return ret;
      }
    }

    final ret = fromDefault();
    await commit(latestVersion, ret);
    return ret;
  }
}
