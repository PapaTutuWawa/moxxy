import "package:moxxyv2/ui/redux/debug/state.dart";
import "package:moxxyv2/ui/redux/debug/actions.dart";

DebugState debugReducer(DebugState state, dynamic action) {
  if (action is DebugSetEnabledAction) {
    return state.copyWith(enabled: action.enabled);
  } else if (action is DebugSetIpAction) {
    return state.copyWith(ip: action.ip);
  } else if (action is DebugSetPortAction) {
    return state.copyWith(port: action.port);
  } else if (action is DebugSetPassphraseAction) {
    return state.copyWith(passphrase: action.passphrase);
  }

  return state;
}
