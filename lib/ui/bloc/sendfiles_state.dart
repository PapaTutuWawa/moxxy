part of 'sendfiles_bloc.dart';

@freezed
class SendFilesState with _$SendFilesState {
  factory SendFilesState({
    // List of file paths that the user wants to send
    @Default(<String>[]) List<String> files,
    // The currently selected path
    @Default(0) int index,
    // The chat that is currently active
    @Default(null) String? conversationJid,
  }) = _SendFilesState;
}
