import "package:moxxyv2/shared/models/roster.dart";

class RemoveRosterItemUIAction {
  final String jid;

  RemoveRosterItemUIAction({ required this.jid });
}

class RosterDiffAction {
  final List<RosterItem> newItems;
  final List<RosterItem> changedItems;
  final List<String> removedItems;

  RosterDiffAction({ required this.newItems, required this.changedItems, required this.removedItems });
}
