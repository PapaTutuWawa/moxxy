part of 'joingroupchat_bloc.dart';

abstract class JoinGroupchatEvent {}

/// Triggered by the UI when the JID input field is changed
class JidChangedEvent extends JoinGroupchatEvent {
  JidChangedEvent(this.jid);
  final String jid;
}

/// Triggered by the UI when the Nick input field is changed
class NickChangedEvent extends JoinGroupchatEvent {
  NickChangedEvent(this.nick);
  final String nick;
}

/// Triggered when the UI wants to reset its state
class PageResetEvent extends JoinGroupchatEvent {}

/// Triggered when a new MUC joining has been attempted
class StartGroupchatEvent extends JoinGroupchatEvent {}
