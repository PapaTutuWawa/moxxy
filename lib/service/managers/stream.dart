import "dart:async";

import "package:moxxyv2/service/repositories/xmpp.dart";
import "package:moxxyv2/xmpp/xeps/xep_0198.dart";

import "package:get_it/get_it.dart";

class MoxxyStreamManagementManager extends StreamManagementManager {
  @override
  Future<void> commitState() async {
    await GetIt.I.get<XmppRepository>().modifyXmppState((state) => state.copyWith(
        c2sh: getC2SStanzaCount(),
        s2ch: getS2CStanzaCount()
    ));
  }

  @override
  Future<void> loadState() async {
    final state = await GetIt.I.get<XmppRepository>().getXmppState();
    setState(state.c2sh, state.s2ch);
  }

  @override
  Future<void> commitStreamResumptionId() async {
    final srid = getStreamResumptionId();
    if (srid !=  null) {
      logger.fine("Saving resumption token: $srid");
      await GetIt.I.get<XmppRepository>().modifyXmppState((state) => state.copyWith(
          srid: srid
      ));
    }
  }

  @override
  Future<void> loadStreamResumptionId() async {
    final id = (await GetIt.I.get<XmppRepository>().getXmppState()).srid;
    logger.fine("Setting resumption token: " + (id ?? ""));
    if (id != null) {
      setStreamResumptionId(id);
    }
  }
}
