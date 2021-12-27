import "package:moxxyv2/redux/account/state.dart";
import "package:moxxyv2/redux/account/actions.dart";

AccountState accountReducer(AccountState state, dynamic action) {
  if (action is SetDisplayNameAction) {
    return state.copyWith(displayName: action.displayName);
  } else if (action is SetAvatarAction) {
    return state.copyWith(avatarUrl: action.avatarUrl);
  } else if (action is SetJidAction) {
    return state.copyWith(jid: action.jid);
  }

  return state;
}
