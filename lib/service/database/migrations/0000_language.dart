import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/shared/models/preference.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV2ToV3(Database db) async {
  // Set a default locale
  await db.insert(
    preferenceTable,
    Preference(
      'languageLocaleCode',
      typeString,
      'default',
    ).toDatabaseJson(),
  );
}
