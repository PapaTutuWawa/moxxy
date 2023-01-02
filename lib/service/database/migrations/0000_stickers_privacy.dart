import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/shared/models/preference.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV24ToV25(Database db) async {
  await db.insert(
    preferenceTable,
    Preference(
      'isStickersNodePublic',
      typeBool,
      'true',
    ).toDatabaseJson(),
  );
}
