import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/shared/warning_types.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV44ToV45(Database db) async {
  await db.update(
    messagesTable,
    {
      'errorType': null,
      'warningType': MessageWarningType.chatEncryptedButFilePlaintext.value,
    },
    where: 'errorType = ?',
    // NOTE: 10 is the old id of this error
    whereArgs: [10],
  );
}
