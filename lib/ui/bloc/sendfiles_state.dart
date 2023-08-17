part of 'sendfiles_bloc.dart';

@freezed
class SendFilesRecipient with _$SendFilesRecipient {
  factory SendFilesRecipient(
    String jid,
    String title,
    String? avatar,
    String? avatarHash,
    bool hasContactId,
  ) = _SendFilesRecipient;

  /// JSON
  factory SendFilesRecipient.fromJson(Map<String, dynamic> json) =>
      _$SendFilesRecipientFromJson(json);
}

@freezed
class SendFilesState with _$SendFilesState {
  factory SendFilesState({
    // List of file paths that the user wants to send
    @Default(<String>[]) List<String> files,

    // The currently selected path
    @Default(0) int index,

    // The chat that is currently active
    @Default(<SendFilesRecipient>[]) List<SendFilesRecipient> recipients,

    // Flag indicating whether we can immediately display the conversation indicator (true)
    // or have to first fetch that data from the service (false).
    @Default(false) bool hasRecipientData,
  }) = _SendFilesState;
}
