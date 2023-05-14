import 'package:get_it/get_it.dart';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:moxxyv2/shared/models/preferences.dart';

class PreferencesService {
  PreferencesState? _preferences;

  Future<void> _loadPreferences() async {
    final db = GetIt.I.get<DatabaseService>().database;
    final preferencesRaw = (await db.query(preferenceTable)).map((preference) {
      switch (preference['type']! as int) {
        case typeInt:
          return {
            ...preference,
            'value': stringToInt(preference['value']! as String),
          };
        case typeBool:
          return {
            ...preference,
            'value': stringToBool(preference['value']! as String),
          };
        case typeString:
        default:
          return preference;
      }
    }).toList();
    final json = <String, dynamic>{};
    for (final preference in preferencesRaw) {
      json[preference['key']! as String] = preference['value'];
    }

    _preferences = PreferencesState.fromJson(json);
  }

  Future<PreferencesState> getPreferences() async {
    if (_preferences == null) await _loadPreferences();

    return _preferences!;
  }

  Future<void> modifyPreferences(
    PreferencesState Function(PreferencesState) func,
  ) async {
    if (_preferences == null) await _loadPreferences();

    _preferences = func(_preferences!);

    final stateJson = _preferences!.toJson();
    final preferences = stateJson.keys.map((key) {
      int type;
      String value;
      if (stateJson[key] is int) {
        type = typeInt;
        value = intToString(stateJson[key]! as int);
      } else if (stateJson[key] is bool) {
        type = typeBool;
        value = boolToString(stateJson[key]! as bool);
      } else {
        type = typeString;
        value = stateJson[key]! as String;
      }

      return {
        'key': key,
        'type': type,
        'value': value,
      };
    });

    final batch = GetIt.I.get<DatabaseService>().database.batch();
    for (final preference in preferences) {
      batch.update(
        preferenceTable,
        preference,
        where: 'key = ?',
        whereArgs: [preference['key']],
      );
    }
    await batch.commit();
  }
}
