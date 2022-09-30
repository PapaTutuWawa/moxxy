import 'package:moxxyv2/service/moxxmpp/omemo.dart';
import 'package:omemo_dart/omemo_dart.dart';

Future<OmemoSessionManager> generateNewIdentityImpl(String jid) async {
  return OmemoSessionManager.generateNewIdentity(
    jid,
    MoxxyBTBVTrustManager(
      <RatchetMapKey, BTBVTrustState>{},
      <RatchetMapKey, bool>{},
      <String, List<int>>{},
    ),
  );
}
