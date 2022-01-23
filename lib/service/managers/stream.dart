import "dart:async";

import "package:moxxyv2/repositories/xmpp.dart";
import "package:moxxyv2/xmpp/xeps/xep_0198.dart";

import "package:get_it/get_it.dart";

class MoxxyStreamManagementManager extends StreamManagementManager {
  @override
  Future<void> commitState() async {
    await Future.wait([
        GetIt.I.get<XmppRepository>().saveStreamManagementC2SH(getC2SStanzaCount()),
        GetIt.I.get<XmppRepository>().saveStreamManagementS2CH(getS2CStanzaCount())
    ]);
  }

  @override
  Future<void> loadState() async {
    final result = await Future.wait<int?>([
        GetIt.I.get<XmppRepository>().getStreamManagementC2SH(),
        GetIt.I.get<XmppRepository>().getStreamManagementS2CH()
    ]);

    setState(result[0] ?? 0, result[1] ?? 0);
  }

  @override
  Future<void> commitStreamResumptionId() async {
    final srid = getStreamResumptionId();
    if (srid !=  null) {
      getAttributes().log("Saving resumption token: $srid");
      await GetIt.I.get<XmppRepository>().saveStreamResumptionId(srid);
    }
  }

  @override
  Future<void> loadStreamResumptionId() async {
    final id = await GetIt.I.get<XmppRepository>().getStreamResumptionId();
    getAttributes().log("Setting resumption token: " + (id ?? ""));
    if (id != null) {
      setStreamResumptionId(id);
    }
  }
}
