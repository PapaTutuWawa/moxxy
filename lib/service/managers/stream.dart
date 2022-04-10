import "dart:async";

import "package:moxxyv2/service/xmpp.dart";
import "package:moxxyv2/xmpp/xeps/xep_0198/xep_0198.dart";

import "package:get_it/get_it.dart";

class MoxxyStreamManagementManager extends StreamManagementManager {
  @override
  Future<void> commitState() async {
    await GetIt.I.get<XmppService>().modifyXmppState((s) => s.copyWith(
        smState: state
    ));
  }

  @override
  Future<void> loadState() async {
    final state = await GetIt.I.get<XmppService>().getXmppState();
    if (state.smState != null) {
      setState(state.smState!);
    }
  }
}
