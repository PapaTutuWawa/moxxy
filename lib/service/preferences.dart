import "dart:convert";

import "package:moxxyv2/shared/preferences.dart";

import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:logging/logging.dart";

const currentVersion = 3;
const preferencesVersionKey = "prefs_version";
const preferencesDataKey = "prefs_data";

class PreferencesService {
  int _version = -1;
  PreferencesState? _preferences;
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true)
  );
  final Logger _log;

  PreferencesService() : _log = Logger("PreferencesService");
  
  // TODO: Deduplicate with XmppService. Maybe a StorageService?
  Future<String?> _readKeyOrNull(String key) async {
    if (await _storage.containsKey(key: key)) {
      return await _storage.read(key: key);
    } else {
      return null;
    }
  }
 
  Future<void> _commitPreferences() async {
    await _storage.write(key: preferencesVersionKey, value: _version.toString());
    await _storage.write(key: preferencesDataKey, value: json.encode(_preferences!.toJson()));
  }
  
  Future<void> _loadPreferences() async {
    final version = int.parse((await _readKeyOrNull(preferencesVersionKey)) ?? "-1");
    final dataRaw = await _readKeyOrNull(preferencesDataKey);

    if (version < 1 || dataRaw == null) {
      _log.finest("Creating preferences...");
      _preferences = PreferencesState();
      _version = currentVersion;
      await _commitPreferences();
    } else if(version < 2) {
      final data = json.decode(dataRaw);

      _log.finest("Upgrading from a 0 < version < 2 to version 2");
      _preferences = PreferencesState(
        sendChatMarkers: data["sendChatMarkers"]!,
        sendChatStates: data["sendChatStates"]!,
        showSubscriptionRequests: data["showSubscriptionRequests"]!,
        autoDownloadWifi: true,
        autoDownloadMobile: false,
        maximumAutoDownloadSize: 15
      );
      _version = currentVersion;
      await _commitPreferences();
    } else if (version < 3) {
      final data = json.decode(dataRaw);

      _log.finest("Upgrading from a 0 < version < 2 to version 2");
      _preferences = PreferencesState(
        sendChatMarkers: data["sendChatMarkers"]!,
        sendChatStates: data["sendChatStates"]!,
        showSubscriptionRequests: data["showSubscriptionRequests"]!,
        autoDownloadWifi: data["autoDownloadWifi"]!,
        autoDownloadMobile: data["autoDownloadMobile"]!,
        maximumAutoDownloadSize: 15
      );
      _version = currentVersion;
      await _commitPreferences();
    } else {
      _version = currentVersion;
      _preferences = PreferencesState.fromJson(json.decode(dataRaw));
    } 
  }

  Future<PreferencesState> getPreferences() async {
    if (_preferences == null) await _loadPreferences();

    return _preferences!;
  }

  Future<void> modifyPreferences(PreferencesState Function(PreferencesState) func) async {
    if (_preferences == null) await _loadPreferences();

    _preferences = func(_preferences!);
    await _commitPreferences();
  }
}
