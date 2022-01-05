import "dart:collection";

import "package:moxxyv2/models/roster.dart";

class AddRosterItemAction {
  final RosterItem item;

  AddRosterItemAction({ required this.item });
}

class AddMultipleRosterItemsAction {
  final List<RosterItem> items;

  AddMultipleRosterItemsAction({ required this.items });
}

class RemoveRosterItemUIAction {
  final String jid;

  RemoveRosterItemUIAction({ required this.jid });
}

class RemoveRosterItemAction {
  final String jid;

  RemoveRosterItemAction({ required this.jid });
}

class RosterItemRemovedAction {
  final String jid;

  RosterItemRemovedAction({ required this.jid });
}

class SaveCurrentRosterVersionAction {
  final String ver;

  SaveCurrentRosterVersionAction({ required this.ver });
}
