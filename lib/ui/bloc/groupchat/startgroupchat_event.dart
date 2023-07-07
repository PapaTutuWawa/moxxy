part of 'startgroupchat_bloc.dart';

abstract class StartGroupchatEvent {}

/// Triggered by the UI when the JID input field is changed
class JidChangedEvent extends StartGroupchatEvent {
  JidChangedEvent(this.jid);
  final String jid;
}

/// Triggered by the UI when the Nick input field is changed
class NickChangedEvent extends StartGroupchatEvent {
  NickChangedEvent(this.nick);
  final String nick;
}

/// Triggered when the UI wants to reset its state
class PageResetEvent extends StartGroupchatEvent {}

/// Triggered when a new MUC joining has been attempted
class JoinGroupchatEvent extends StartGroupchatEvent {}
