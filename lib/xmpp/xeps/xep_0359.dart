import "package:moxxyv2/xmpp/stanza.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/managers/handlers.dart";
import "package:moxxyv2/xmpp/managers/data.dart";
import "package:moxxyv2/xmpp/xeps/xep_0030/cachemanager.dart";

/// Represents data provided by XEP-0359.
/// NOTE: [StableStanzaId.stanzaId] must not be confused with the actual id attribute of
///       the message stanza.
class StableStanzaId {
  final String? originId;
  final String? stanzaId;
  final String? stanzaIdBy;

  const StableStanzaId({ this.originId, this.stanzaId, this.stanzaIdBy });
}

XMLNode makeOriginIdElement(String id) {
  return XMLNode.xmlns(
    tag: "origin-id",
    xmlns: stableIdXmlns,
    attributes: { "id": id }
  );
}

class StableIdManager extends XmppManagerBase {
  @override
  String getName() => "StableIdManager";

  @override
  String getId() => stableIdManager;

  @override
  List<String> getDiscoFeatures() => [ stableIdXmlns ];

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: "message",
      callback: _onMessage,
      // Before the MessageManager
      priority: -99
    )
  ];

  Future<StanzaHandlerData> _onMessage(Stanza message, StanzaHandlerData state) async {
    final from = JID.fromString(message.attributes["from"]!);
    String? originId;
    String? stanzaId;
    String? stanzaIdBy;
    final originIdTag = message.firstTag("origin-id", xmlns: stableIdXmlns);
    final stanzaIdTag = message.firstTag("stanza-id", xmlns: stableIdXmlns);
    if (originIdTag != null || stanzaIdTag != null) {
      logger.finest("Found Unique and Stable Stanza Id tag");
      final attrs = getAttributes();
      final cache = attrs.getManagerById(discoCacheManager) as DiscoCacheManager?;
      if (cache != null) {
        final info = await cache.getInfoByJid(from.toString());
        if (info != null) {
          logger.finest("Got info for ${from.toString()}");
          if (info.features.contains(stableIdXmlns)) {
            logger.finest("${from.toString()} supports $stableIdXmlns.");

            if (originIdTag != null) {
              originId = originIdTag.attributes["id"]!;
            }

            if (stanzaIdTag != null) {
              stanzaId = stanzaIdTag.attributes["id"]!;
              stanzaIdBy = stanzaIdTag.attributes["by"]!;
            }
          } else {
            logger.finest("${from.toString()} does not support $stableIdXmlns. Ignoring... ");
          }
        }
      }
    }

    return state.copyWith(
      stableId: StableStanzaId(
        originId: originId,
        stanzaId: stanzaId,
        stanzaIdBy: stanzaIdBy
      )
    );
  }
}
