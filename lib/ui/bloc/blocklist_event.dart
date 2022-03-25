part of "blocklist_bloc.dart";

abstract class BlocklistEvent {}

/// Triggered when a JID is unblocked
class UnblockedJidEvent extends BlocklistEvent {
  final String jid;

  UnblockedJidEvent(this.jid);
}

/// Triggered when all JID are unblocked
class UnblockedAllEvent extends BlocklistEvent {
  UnblockedAllEvent();
}

/// Triggered when we receive a blocklist push
class BlocklistPushedEvent extends BlocklistEvent {
  final List<String> added;
  final List<String> removed;

  BlocklistPushedEvent(this.added, this.removed);
}
