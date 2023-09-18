import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/shared/models/preference.dart';

Future<void> upgradeFromV2ToV3(DatabaseMigrationData data) async {
  final (db, _) = data;

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
