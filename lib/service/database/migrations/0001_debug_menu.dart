import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:moxxyv2/shared/models/preference.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV25ToV26(Database db) async {
  await db.insert(
    preferenceTable,
    Preference(
      'showDebugMenu',
      typeBool,
      boolToString(false),
    ).toDatabaseJson(),
  );
}
