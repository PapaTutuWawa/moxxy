import "package:moxxyv2/shared/models/roster.dart";
import "package:moxxyv2/ui/redux/roster/actions.dart";

List<RosterItem> rosterReducer(List<RosterItem> roster, dynamic action) {
  if (action is RemoveRosterItemUIAction) {
    return roster.where((item) => item.jid != action.jid).toList();
  } else if (action is RosterDiffAction) {
    final r = roster.where((item) => !action.removedItems.contains(item.jid)).toList();
    r.addAll(action.newItems);
    return r.map((item) {
        for (final i in action.changedItems) {
          if (i.id == item.id) {
            return i;
          }
        }

        return item;
    }).toList();
  }

  return roster;
}
