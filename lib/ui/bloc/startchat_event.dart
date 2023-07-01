part of 'startchat_bloc.dart';

abstract class StartChatEvent {}

/// Triggered when a new contact has been added by the UI
class AddedContactEvent extends StartChatEvent {}

/// Triggered by the UI when the JID input field is changed
class JidChangedEvent extends StartChatEvent {
  JidChangedEvent(this.jid);
  final String jid;
}

/// Triggered when the UI wants to reset its state
class PageResetEvent extends StartChatEvent {}
