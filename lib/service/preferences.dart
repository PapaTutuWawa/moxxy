import 'package:get_it/get_it.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/shared/models/preferences.dart';

class PreferencesService {
  PreferencesState? _preferences;

  Future<void> _loadPreferences() async {
    _preferences = await GetIt.I.get<DatabaseService>().getPreferences();
  }

  Future<PreferencesState> getPreferences() async {
    if (_preferences == null) await _loadPreferences();

    return _preferences!;
  }

  Future<void> modifyPreferences(
      PreferencesState Function(PreferencesState) func) async {
    if (_preferences == null) await _loadPreferences();

    _preferences = func(_preferences!);
    await GetIt.I.get<DatabaseService>().savePreferences(_preferences!);
  }
}
