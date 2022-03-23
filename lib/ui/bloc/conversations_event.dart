part of "conversations_bloc.dart";

abstract class ConversationsEvent {}

class ConversationsInitEvent extends ConversationsEvent {
  final String displayName;
  final List<Conversation> conversations;

  ConversationsInitEvent(this.displayName, this.conversations);
}
