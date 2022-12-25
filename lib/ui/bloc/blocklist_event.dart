part of 'blocklist_bloc.dart';

abstract class BlocklistEvent {}

/// Triggered when the blocklist page has been requested
class BlocklistRequestedEvent extends BlocklistEvent {}

/// Triggered when a JID is unblocked
class UnblockedJidEvent extends BlocklistEvent {
  UnblockedJidEvent(this.jid);
  final String jid;
}

/// Triggered when all JID are unblocked
class UnblockedAllEvent extends BlocklistEvent {
  UnblockedAllEvent();
}

/// Triggered when we receive a blocklist push
class BlocklistPushedEvent extends BlocklistEvent {
  BlocklistPushedEvent(this.added, this.removed);
  final List<String> added;
  final List<String> removed;
}
