import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moxxyv2/shared/migrator.dart';
import 'package:moxxyv2/shared/preferences.dart';

const currentVersion = 7;
const preferencesVersionKey = 'prefs_version';
const preferencesDataKey = 'prefs_data';

class _PreferencesMigrator extends Migrator<PreferencesState> {

  _PreferencesMigrator() : super(
    currentVersion,
    [
      Migration<PreferencesState>(1, (data) => PreferencesState(
        sendChatMarkers: data['sendChatMarkers']! as bool,
        sendChatStates: data['sendChatStates']! as bool,
        showSubscriptionRequests: data['showSubscriptionRequests']! as bool,
      ),),
      Migration<PreferencesState>(2, (data) => PreferencesState(
        sendChatMarkers: data['sendChatMarkers']! as bool,
        sendChatStates: data['sendChatStates']! as bool,
        showSubscriptionRequests: data['showSubscriptionRequests']! as bool,
        autoDownloadWifi: data['autoDownloadWifi']! as bool,
        autoDownloadMobile: data['autoDownloadMobile']! as bool,
      ),),
      Migration<PreferencesState>(3, (data) => PreferencesState(
        sendChatMarkers: data['sendChatMarkers']! as bool,
        sendChatStates: data['sendChatStates']! as bool,
        showSubscriptionRequests: data['showSubscriptionRequests']! as bool,
        autoDownloadWifi: data['autoDownloadWifi']! as bool,
        autoDownloadMobile: data['autoDownloadMobile']! as bool,
        maximumAutoDownloadSize: data['maximumAutoDownloadSize']! as int,
      ),),
      Migration<PreferencesState>(4, (data) => PreferencesState(
        sendChatMarkers: data['sendChatMarkers']! as bool,
        sendChatStates: data['sendChatStates']! as bool,
        showSubscriptionRequests: data['showSubscriptionRequests']! as bool,
        autoDownloadWifi: data['autoDownloadWifi']! as bool,
        autoDownloadMobile: data['autoDownloadMobile']! as bool,
        maximumAutoDownloadSize: data['maximumAutoDownloadSize']! as int,
        backgroundPath: data['backgroundPath']! as String,
      ),),
      Migration<PreferencesState>(5, (data) => PreferencesState(
        sendChatMarkers: data['sendChatMarkers']! as bool,
        sendChatStates: data['sendChatStates']! as bool,
        showSubscriptionRequests: data['showSubscriptionRequests']! as bool,
        autoDownloadWifi: data['autoDownloadWifi']! as bool,
        autoDownloadMobile: data['autoDownloadMobile']! as bool,
        maximumAutoDownloadSize: data['maximumAutoDownloadSize']! as int,
        backgroundPath: data['backgroundPath']! as String,
        isAvatarPublic: data['isAvatarPublic']! as bool,
      ),),
      Migration<PreferencesState>(6, (data) => PreferencesState(
        sendChatMarkers: data['sendChatMarkers']! as bool,
        sendChatStates: data['sendChatStates']! as bool,
        showSubscriptionRequests: data['showSubscriptionRequests']! as bool,
        autoDownloadWifi: data['autoDownloadWifi']! as bool,
        autoDownloadMobile: data['autoDownloadMobile']! as bool,
        maximumAutoDownloadSize: data['maximumAutoDownloadSize']! as int,
        backgroundPath: data['backgroundPath']! as String,
        isAvatarPublic: data['isAvatarPublic']! as bool,
        autoAcceptSubscriptionRequests: data['autoAcceptSubscriptionRequests']! as bool,
      ),),
      Migration<PreferencesState>(7, (data) => PreferencesState(
        sendChatMarkers: data['sendChatMarkers']! as bool,
        sendChatStates: data['sendChatStates']! as bool,
        showSubscriptionRequests: data['showSubscriptionRequests']! as bool,
        autoDownloadWifi: data['autoDownloadWifi']! as bool,
        autoDownloadMobile: data['autoDownloadMobile']! as bool,
        maximumAutoDownloadSize: data['maximumAutoDownloadSize']! as int,
        backgroundPath: data['backgroundPath']! as String,
        isAvatarPublic: data['isAvatarPublic']! as bool,
        autoAcceptSubscriptionRequests: data['autoAcceptSubscriptionRequests']! as bool,
        twitterRedirect: data['twitterRedirect']! as String,
        youtubeRedirect: data['youtubeRedirect']! as String,
        enableTwitterRedirect: data['enableTwitterRedirect']! as bool,
        enableYoutubeRedirect: data['enableYoutubeRedirect']! as bool,
      ),)
    ]
  );
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // TODO(Unknown): Deduplicate with XmppService. Maybe a StorageService?
  Future<String?> _readKeyOrNull(String key) async {
    if (await _storage.containsKey(key: key)) {
      return _storage.read(key: key);
    } else {
      return null;
    }
  }
  
  @override
  Future<Map<String, dynamic>?> loadRawData() async {
    final raw = await _readKeyOrNull(preferencesDataKey);
    if (raw != null) return json.decode(raw) as Map<String, dynamic>;

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

  PreferencesService() : _migrator = _PreferencesMigrator();
  PreferencesState? _preferences;
  final _PreferencesMigrator _migrator;
  
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
