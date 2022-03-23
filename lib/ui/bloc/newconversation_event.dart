part of "newconversation_bloc.dart";

abstract class NewConversationEvent {}

/// Triggered after login or prestart to initialize the state.
// TODO: Trigger after login
class NewConversationInitEvent extends NewConversationEvent {
  final List<RosterItem> roster;

  NewConversationInitEvent(this.roster);
}

/// Triggered when a new conversation has been added by the UI
class NewConversationAddedEvent extends NewConversationEvent {
  final String jid;
  final String title;
  final String avatarUrl;

  NewConversationAddedEvent(this.jid, this.title, this.avatarUrl);
}

/// Triggered when a roster item has been removed by the UI
class NewConversationRosterItemRemovedEvent extends NewConversationEvent {
  final String jid;

  NewConversationRosterItemRemovedEvent(this.jid);
}
