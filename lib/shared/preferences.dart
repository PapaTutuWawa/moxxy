import "package:freezed_annotation/freezed_annotation.dart";

part "preferences.freezed.dart";
part "preferences.g.dart";

@freezed
class PreferencesState with _$PreferencesState {
  factory PreferencesState({
      @Default(true) bool sendChatMarkers,
      @Default(true) bool sendChatStates,
      @Default(true) bool showSubscriptionRequests
  }) = _PreferencesState;
  
  // JSON serialization
  factory PreferencesState.fromJson(Map<String, dynamic> json) => _$PreferencesStateFromJson(json);
}
