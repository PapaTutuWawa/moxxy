import "dart:collection";
import "package:moxxyv2/models/roster.dart";
import "package:moxxyv2/redux/roster/actions.dart";

List<RosterItem> rosterReducer(List<RosterItem> roster, dynamic action) {
  if (action is AddRosterItemAction) {
    return [
      ...roster,
      RosterItem(
          avatarUrl: action.avatarUrl,
          jid: action.jid,
          title: action.title
      )
    ];
  } else if (action is AddMultipleRosterItemsAction) {
    return roster..addAll(action.items);
  }

  return roster;
}
