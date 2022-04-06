import "dart:convert";

import "package:moxxyv2/shared/preferences.dart";
import "package:moxxyv2/shared/migrator.dart";

import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:logging/logging.dart";

const currentVersion = 7;
const preferencesVersionKey = "prefs_version";
const preferencesDataKey = "prefs_data";

class _PreferencesMigrator extends Migrator<PreferencesState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true)
  );

  _PreferencesMigrator() : super(
    currentVersion,
    [
      Migration<PreferencesState>(1, (data) => PreferencesState(
          sendChatMarkers: data["sendChatMarkers"]!,
          sendChatStates: data["sendChatStates"]!,
          showSubscriptionRequests: data["showSubscriptionRequests"]!
      )),
      Migration<PreferencesState>(2, (data) => PreferencesState(
          sendChatMarkers: data["sendChatMarkers"]!,
          sendChatStates: data["sendChatStates"]!,
          showSubscriptionRequests: data["showSubscriptionRequests"]!,
          autoDownloadWifi: data["autoDownloadWifi"]!,
          autoDownloadMobile: data["autoDownloadMobile"]!
      )),
      Migration<PreferencesState>(3, (data) => PreferencesState(
          sendChatMarkers: data["sendChatMarkers"]!,
          sendChatStates: data["sendChatStates"]!,
          showSubscriptionRequests: data["showSubscriptionRequests"]!,
          autoDownloadWifi: data["autoDownloadWifi"]!,
          autoDownloadMobile: data["autoDownloadMobile"]!,
          maximumAutoDownloadSize: data["maximumAutoDownloadSize"]!
      )),
      Migration<PreferencesState>(4, (data) => PreferencesState(
          sendChatMarkers: data["sendChatMarkers"]!,
          sendChatStates: data["sendChatStates"]!,
          showSubscriptionRequests: data["showSubscriptionRequests"]!,
          autoDownloadWifi: data["autoDownloadWifi"]!,
          autoDownloadMobile: data["autoDownloadMobile"]!,
          maximumAutoDownloadSize: data["maximumAutoDownloadSize"]!,
          backgroundPath: data["backgroundPath"]!
      )),
      Migration<PreferencesState>(5, (data) => PreferencesState(
          sendChatMarkers: data["sendChatMarkers"]!,
          sendChatStates: data["sendChatStates"]!,
          showSubscriptionRequests: data["showSubscriptionRequests"]!,
          autoDownloadWifi: data["autoDownloadWifi"]!,
          autoDownloadMobile: data["autoDownloadMobile"]!,
          maximumAutoDownloadSize: data["maximumAutoDownloadSize"]!,
          backgroundPath: data["backgroundPath"]!,
          isAvatarPublic: data["isAvatarPublic"]!
      )),
      Migration<PreferencesState>(6, (data) => PreferencesState(
          sendChatMarkers: data["sendChatMarkers"]!,
          sendChatStates: data["sendChatStates"]!,
          showSubscriptionRequests: data["showSubscriptionRequests"]!,
          autoDownloadWifi: data["autoDownloadWifi"]!,
          autoDownloadMobile: data["autoDownloadMobile"]!,
          maximumAutoDownloadSize: data["maximumAutoDownloadSize"]!,
          backgroundPath: data["backgroundPath"]!,
          isAvatarPublic: data["isAvatarPublic"]!,
          autoAcceptSubscriptionRequests: data["autoAcceptSubscriptionRequests"]
      ))
    ]
  );

  // TODO: Deduplicate with XmppService. Maybe a StorageService?
  Future<String?> _readKeyOrNull(String key) async {
    if (await _storage.containsKey(key: key)) {
      return await _storage.read(key: key);
    } else {
      return null;
    }
  }
  
  @override
  Future<Map<String, dynamic>?> loadRawData() async {
    final raw = await _readKeyOrNull(preferencesDataKey);
    if (raw != null) return json.decode(raw);

    return null;
  }

  @override
  Future<int?> loadVersion() async {
    final raw = await _readKeyOrNull(preferencesVersionKey);
    if (raw != null) return int.parse(raw);

    return null;
  }

  @override
  PreferencesState fromData(Map<String, dynamic> data) => PreferencesState.fromJson(data);

  @override
  PreferencesState fromDefault() => PreferencesState();
  
  @override
  Future<void> commit(int version, PreferencesState data) async {
    await _storage.write(key: preferencesVersionKey, value: version.toString());
    await _storage.write(key: preferencesDataKey, value: json.encode(data.toJson()));
  }
}

class PreferencesService {
  PreferencesState? _preferences;
  final _PreferencesMigrator _migrator;
  final Logger _log;

  PreferencesService() : _migrator = _PreferencesMigrator(), _log = Logger("PreferencesService");
  
  Future<void> _loadPreferences() async {
    _preferences = await _migrator.load();
  }

  Future<PreferencesState> getPreferences() async {
    if (_preferences == null) await _loadPreferences();

    return _preferences!;
  }

  Future<void> modifyPreferences(PreferencesState Function(PreferencesState) func) async {
    if (_preferences == null) await _loadPreferences();

    _preferences = func(_preferences!);
    await _migrator.commit(currentVersion, _preferences!);
  }
}
