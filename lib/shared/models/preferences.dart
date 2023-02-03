import 'package:freezed_annotation/freezed_annotation.dart';

part 'preferences.freezed.dart';
part 'preferences.g.dart';

@freezed
class PreferencesState with _$PreferencesState {
  factory PreferencesState({
    @Default(true) bool sendChatMarkers,
    @Default(true) bool sendChatStates,
    @Default(true) bool showSubscriptionRequests,
    @Default(true) bool autoDownloadWifi,
    @Default(false) bool autoDownloadMobile,
    @Default(15) int maximumAutoDownloadSize,
    @Default('') String backgroundPath,
    @Default(true) bool isAvatarPublic,
    @Default(false) bool debugEnabled,
    @Default('') String debugPassphrase,
    @Default('') String debugIp,
    @Default(-1) int debugPort,
    @Default('') String twitterRedirect,
    @Default('') String youtubeRedirect,
    @Default(false) bool enableTwitterRedirect,
    @Default(false) bool enableYoutubeRedirect,
    @Default(false) bool defaultMuteState,
    @Default(false) bool enableOmemoByDefault,
    // NOTE: A value of 'default' means that the system's configured language should
    //       be used
    @Default('default') String languageLocaleCode,
    @Default(false) bool enableContactIntegration,
    @Default(true) bool enableStickers,
    @Default(true) bool autoDownloadStickersFromContacts,
    @Default(true) bool isStickersNodePublic,
    @Default(false) bool showDebugMenu,
  }) = _PreferencesState;
  
  // JSON serialization
  factory PreferencesState.fromJson(Map<String, dynamic> json) => _$PreferencesStateFromJson(json);
}
