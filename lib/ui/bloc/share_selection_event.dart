part of 'share_selection_bloc.dart';

abstract class ShareSelectionEvent {}

/// Triggered when we receive the initial data, i.e. open conversations and the roster
class ShareSelectionInitEvent extends ShareSelectionEvent {
  ShareSelectionInitEvent(this.conversations, this.rosterItems);
  final List<Conversation> conversations;
  final List<RosterItem> rosterItems;
}

/// Triggered when the share page has been requested. [paths] refers to the paths that
/// we want to share with the JID or the JIDs.
class ShareSelectionRequestedEvent extends ShareSelectionEvent {
  ShareSelectionRequestedEvent(this.paths, this.text, this.type);
  final List<String> paths;
  final String? text;
  final ShareSelectionType type;
}

/// Triggered when we want to toggle the selection of a list item
class SelectionToggledEvent extends ShareSelectionEvent {
  SelectionToggledEvent(this.index);
  final int index;
}

/// Triggered when the user confirms their selection.
class SubmittedEvent extends ShareSelectionEvent {}

/// Triggered when we should reset the paths and the selection
class ResetEvent extends ShareSelectionEvent {}
