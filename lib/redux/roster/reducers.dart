import "dart:collection";
import "package:moxxyv2/models/roster.dart";
import "package:moxxyv2/redux/roster/actions.dart";

List<RosterItem> rosterReducer(List<RosterItem> roster, dynamic action) {
  if (action is AddRosterItemAction) {
    return [
      ...roster,
      action.item
    ];
  } else if (action is AddMultipleRosterItemsAction) {
    return roster..addAll(action.items);
  } else if (action is RosterItemRemovedAction) {
    return roster.where((item) => item.jid != action.jid).toList();
  }

  return roster;
}
