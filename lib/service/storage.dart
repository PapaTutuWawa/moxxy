import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';

/// Service responsible for handling storage related queries, like how much storage
/// are we currently using.
class StorageService {
  /// Logger.
  final Logger _log = Logger('StorageService');

  /// Compute the amount of storage all FileMetadata objects take, that both have
  /// their file size and path set to something other than null.
  Future<int> computeUsedStorage() async {
    final db = GetIt.I.get<DatabaseService>().database;
    final result = await db.rawQuery(
      'SELECT SUM(size) AS size FROM $fileMetadataTable WHERE path IS NOT NULL AND size IS NOT NULL',
    );

    return result.first['size']! as int;
  }

  /// Deletes shared media files for which the age of the newest attached message
  /// is at least [timeOffsetMilliseconds] milliseconds in the past from the moment
  /// of calling.
  Future<void> deleteOldMediaFiles(int timeOffsetMilliseconds) async {
    // The timestamp of the newest message referencing this
    final maxAge =
        DateTime.now().millisecondsSinceEpoch - timeOffsetMilliseconds;
    // The database
    final db = GetIt.I.get<DatabaseService>().database;

    // The query is pretty complicated because:
    // - We deduplicate media files, meaning that there may be > 1 messages that use a given
    //   file metadata entry. To prevent deleting too many files, we have to find the newest
    //   message that references the file metadata item and check if that message's timestamp
    //   puts it in deletion range.
    // - We don't want to delete files that belong to a sticker pack because the storage of those
    //   is managed differently.
    final results = await db.rawQuery(
      '''
      SELECT path, id FROM $fileMetadataTable AS fmt
        WHERE (SELECT MAX(timestamp) FROM $messagesTable WHERE file_metadata_id = fmt.id) <= $maxAge
          AND NOT EXISTS (SELECT id from $stickersTable WHERE file_metadata_id = fmt.id)
      ''',
    );
    _log.finest('Found ${results.length} matching files for deletion');

    for (final result in results) {
      // TODO: Update the fmt entry
      // TODO: Delete the file
      // TODO: Check if we have to update a conversation
    }
  }
}
