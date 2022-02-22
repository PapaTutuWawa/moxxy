import "package:moxxyv2/shared/models/roster.dart";
import "package:moxxyv2/ui/redux/roster/actions.dart";

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
  } else if (action is ModifyRosterItemAction) {
    final index = roster.lastIndexWhere((item) => item.jid == action.item.jid);
    if (index > -1) {
      roster[index] = action.item;
    } else {
      roster.add(action.item);
    }

    return roster;
  } else if (action is RemoveRosterItemUIAction) {
    return roster.where((item) => item.jid != action.jid).toList();
  } else if (action is RemoveMultipleRosterItemsAction) {
    return roster.where((item) => !action.items.contains(item.jid)).toList();
  }

  return roster;
}
