import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/shared/models/preference.dart';

Future<void> upgradeFromV24ToV25(DatabaseMigrationData data) async {
  final (db, _) = data;

  await db.insert(
    preferenceTable,
    Preference(
      'isStickersNodePublic',
      typeBool,
      'true',
    ).toDatabaseJson(),
  );
}
