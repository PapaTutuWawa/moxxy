import "dart:collection";

import "package:moxxyv2/models/roster.dart";

class AddRosterItemAction {
  final String avatarUrl;
  final String jid;
  final String title;
  final bool triggeredByDatabase;

  AddRosterItemAction({ required this.avatarUrl, required this.jid, required this.title, this.triggeredByDatabase = false });
}

class AddMultipleRosterItemsAction {
  final List<RosterItem> items;

  AddMultipleRosterItemsAction({ required this.items });
}

class SaveCurrentRosterVersionAction {
  final String ver;

  SaveCurrentRosterVersionAction({ required this.ver });
}
