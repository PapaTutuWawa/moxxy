import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:moxxyv2/service/xmpp.dart';
import 'package:moxxyv2/xmpp/roster.dart';

class MoxxyRosterManager extends RosterManager {
  @override
  Future<void> commitLastRosterVersion(String version) async {
    await GetIt.I.get<XmppService>().modifyXmppState((state) => state.copyWith(
        lastRosterVersion: version,
    ),);
  }

  @override
  Future<void> loadLastRosterVersion() async {
    final ver = (await GetIt.I.get<XmppService>().getXmppState()).lastRosterVersion;
    if (ver != null) {
      setRosterVersion(ver);
    }
  }
}
