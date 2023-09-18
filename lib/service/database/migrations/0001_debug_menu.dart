import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:moxxyv2/shared/models/preference.dart';

Future<void> upgradeFromV25ToV26(DatabaseMigrationData data) async {
  final (db, _) = data;

  await db.insert(
    preferenceTable,
    Preference(
      'showDebugMenu',
      typeBool,
      boolToString(false),
    ).toDatabaseJson(),
  );
}
