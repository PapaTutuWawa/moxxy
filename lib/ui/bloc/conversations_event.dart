part of "conversations_bloc.dart";

abstract class ConversationsEvent {}

class ConversationsInitEvent extends ConversationsEvent {
  final String displayName;

  ConversationsInitEvent(this.displayName);
}
