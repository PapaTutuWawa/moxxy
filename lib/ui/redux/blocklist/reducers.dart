import "package:moxxyv2/ui/redux/blocklist/actions.dart";

List<String> blocklistReducer(List<String> state, dynamic action) {
  if (action is BlocklistDiffAction) {
    return state.where((item) => !action.removedItems.contains(item)).toList()..addAll(action.newItems);
  } else if (action is BlockJidUIAction) {
    if (state.contains(action.jid)) return state;

    return state..add(action.jid);
  } else if (action is UnblockJidUIAction) {
    return state.where((i) => i != action.jid).toList();
  } else if (action is UnblockAllUIAction) {
    return [];
  }

  return state;
}
