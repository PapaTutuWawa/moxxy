import "dart:async";

import "package:moxxyv2/repositories/xmpp.dart";
import "package:moxxyv2/xmpp/roster.dart";

import "package:get_it/get_it.dart";

class MoxxyRosterManger extends RosterManager {
  @override
  Future<void> commitLastRosterVersion(String version) async {
    await GetIt.I.get<XmppRepository>().saveLastRosterVersion(version);
  }

  @override
  Future<void> loadLastRosterVersion() async {
    final ver = await GetIt.I.get<XmppRepository>().getLastRosterVersion();
    if (ver != null) {
      setRosterVersion(ver);
    }
  }
}
