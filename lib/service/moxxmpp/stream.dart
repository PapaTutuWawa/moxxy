import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/xmpp_state.dart';

class MoxxyStreamManagementManager extends StreamManagementManager {
  @override
  bool shouldTriggerAckedEvent(Stanza stanza) {
    return stanza.tag == 'message' &&
      stanza.id != null && (
        stanza.firstTag('body') != null ||
        stanza.firstTag('x', xmlns: oobDataXmlns) != null ||
        stanza.firstTag('file-sharing', xmlns: sfsXmlns) != null ||
        stanza.firstTag('file-upload', xmlns: fileUploadNotificationXmlns) != null ||
        stanza.firstTag('encrypted', xmlns: omemoXmlns) != null
      );
  }
  
  @override
  Future<void> commitState() async {
    await GetIt.I.get<XmppStateService>().modifyXmppState((s) => s.copyWith(
      smState: state,
    ),);
  }

  @override
  Future<void> loadState() async {
    final state = await GetIt.I.get<XmppStateService>().getXmppState();
    if (state.smState != null) {
      await setState(state.smState!);
    }
  }
}
