import 'package:get_it/get_it.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/conversation.dart';
import 'package:moxxyv2/service/omemo/omemo.dart';
import 'package:omemo_dart/omemo_dart.dart';

class MoxxyOmemoManager extends BaseOmemoManager {
  MoxxyOmemoManager() : super();

  @override
  Future<OmemoManager> getOmemoManager() async {
    final os = GetIt.I.get<OmemoService>();
    await os.ensureInitialized();
    return os.omemoManager;
  }

  @override
  Future<bool> shouldEncryptStanza(JID toJid, Stanza stanza) async {
    // Never encrypt stanzas that contain PubSub elements
    if (stanza.firstTag('pubsub', xmlns: pubsubXmlns) != null ||
        stanza.firstTag('pubsub', xmlns: pubsubOwnerXmlns) != null ||
        stanza.firstTagByXmlns(carbonsXmlns) != null ||
        stanza.firstTagByXmlns(rosterXmlns) != null) {
      return false;
    }

    // Encrypt when the conversation is set to use OMEMO.
    return GetIt.I
        .get<ConversationService>()
        .shouldEncryptForConversation(toJid);
  }
}

class MoxxyBTBVTrustManager extends BlindTrustBeforeVerificationTrustManager {
  MoxxyBTBVTrustManager(
    Map<RatchetMapKey, BTBVTrustState> trustCache,
    Map<RatchetMapKey, bool> enablementCache,
    Map<String, List<int>> devices,
  ) : super(
          trustCache: trustCache,
          enablementCache: enablementCache,
          devices: devices,
        );

  @override
  Future<void> commitState() async {
    await GetIt.I.get<OmemoService>().commitTrustManager(await toJson());
  }
}
