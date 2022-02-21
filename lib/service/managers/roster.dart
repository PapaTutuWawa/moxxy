import "dart:async";

import "package:moxxyv2/service/repositories/xmpp.dart";
import "package:moxxyv2/xmpp/roster.dart";

import "package:get_it/get_it.dart";

class MoxxyRosterManger extends RosterManager {
  @override
  Future<void> commitLastRosterVersion(String version) async {
    await GetIt.I.get<XmppRepository>().modifyXmppState((state) => state.copyWith(
        lastRosterVersion: version
    ));
  }

  @override
  Future<void> loadLastRosterVersion() async {
    final ver = (await GetIt.I.get<XmppRepository>().getXmppState()).lastRosterVersion;
    if (ver != null) {
      setRosterVersion(ver);
    }
  }
}
