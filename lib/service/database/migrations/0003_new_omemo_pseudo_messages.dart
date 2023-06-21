import 'dart:convert';

import 'package:moxxyv2/service/database/constants.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV40ToV41(Database db) async {
  final messages = await db.query(
    messagesTable,
    where: 'pseudoMessageType IS NOT NULL',
  );

  for (final message in messages) {
    await db.insert(
      messagesTable,
      {
        ...message,
        'pseudoMessageData': jsonEncode({
          'ratchetsAdded': 1,
          'ratchetsReplaced': 0,
        }),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
