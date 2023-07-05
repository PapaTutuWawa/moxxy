import 'package:get_it/get_it.dart';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';

/// Service responsible for handling storage related queries, like how much storage
/// are we currently using.
class StorageService {
  /// Compute the amount of storage all FileMetadata objects take, that both have
  /// their file size and path set to something other than null.
  Future<int> computeUsedStorage() async {
    final db = GetIt.I.get<DatabaseService>().database;
    final result = await db.rawQuery(
      'SELECT SUM(size) AS size FROM $fileMetadataTable WHERE path IS NOT NULL AND size IS NOT NULL',
    );

    return result.first['size']! as int;
  }
}
