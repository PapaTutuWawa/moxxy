part of "addcontact_bloc.dart";

abstract class AddContactEvent {}

/// Triggered when a new contact has been added by the UI
class AddedContactEvent extends AddContactEvent {}

/// Triggered by the UI when the JID input field is changed
class JidChangedEvent extends AddContactEvent {
  final String jid;

  JidChangedEvent(this.jid);
}
