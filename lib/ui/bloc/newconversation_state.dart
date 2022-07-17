part of 'newconversation_bloc.dart';

@freezed
class NewConversationState with _$NewConversationState {
  factory NewConversationState({
    @Default(<RosterItem>[]) List<RosterItem> roster,
  }) = _NewConversationState;
}
