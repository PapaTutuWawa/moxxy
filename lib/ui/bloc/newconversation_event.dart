part of 'newconversation_bloc.dart';

abstract class NewConversationEvent {}

/// Triggered after login or prestart to initialize the state.
// TODO(Unknown): Trigger after login
class NewConversationInitEvent extends NewConversationEvent {
  NewConversationInitEvent(this.roster);
  final List<RosterItem> roster;
}

/// Triggered when a new conversation has been added by the UI
class NewConversationAddedEvent extends NewConversationEvent {
  NewConversationAddedEvent(this.jid, this.title, this.avatarUrl, this.type);
  final String jid;
  final String title;
  final String? avatarUrl;
  final ConversationType type;
}

/// Triggered when a roster item has been removed by the UI
class NewConversationRosterItemRemovedEvent extends NewConversationEvent {
  NewConversationRosterItemRemovedEvent(this.jid);
  final String jid;
}

/// Triggered when a roster push has been received
class RosterPushedEvent extends NewConversationEvent {
  RosterPushedEvent(this.added, this.modified, this.removed);
  final List<RosterItem> added;
  final List<RosterItem> modified;
  final List<String> removed;
}
