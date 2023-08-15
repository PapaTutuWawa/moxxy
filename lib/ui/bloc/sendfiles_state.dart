part of 'sendfiles_bloc.dart';

class SendFilesRecipient {
  const SendFilesRecipient(
    this.jid,
    this.title,
    this.avatar,
    this.avatarHash,
    this.hasContactId,
  );

  final String jid;

  final String title;

  final String? avatar;

  final String? avatarHash;

  final bool hasContactId;
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
  }) = _SendFilesState;
}
