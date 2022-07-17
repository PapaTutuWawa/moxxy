part of "profile_bloc.dart";

@freezed
class ProfileState with _$ProfileState {
  factory ProfileState({
      @Default(false) bool isSelfProfile,
      @Default(null) Conversation? conversation,
      @Default("") String jid,
      @Default("") String avatarUrl,
      @Default("") String displayName,
      @Default([]) List<String> serverFeatures,
      @Default(false) bool streamManagementSupported,
  }) = _ProfileState;
}
