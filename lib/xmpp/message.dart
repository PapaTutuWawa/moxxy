import "package:moxxyv2/xmpp/stanza.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/managers/handlers.dart";
import "package:moxxyv2/xmpp/xeps/xep_0030/cachemanager.dart";
import "package:moxxyv2/xmpp/xeps/xep_0066.dart";
import "package:moxxyv2/xmpp/xeps/xep_0280.dart";
import "package:moxxyv2/xmpp/xeps/xep_0297.dart";
import "package:moxxyv2/xmpp/xeps/xep_0359.dart";
import "package:moxxyv2/xmpp/xeps/xep_0385.dart";
import "package:moxxyv2/xmpp/xeps/xep_0447.dart";

class MessageManager extends XmppManagerBase {
  @override
  String getId() => messageManager;

  @override
  String getName() => "MessageManager";

  @override
  List<StanzaHandler> getStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: "message",
      callback: _onMessage
    )
  ];

  @override
  List<String> getDiscoFeatures() => [ chatMarkersXmlns, oobDataXmlns ];

  /// Helper function to extract and verify the origin and stanza Id according to
  /// XEP-0359.
  /// Requires a [DiscoCacheManager] to be registered in order to provide anything
  /// other than [null].
  Future<StableStanzaId> _getStanzaId(Stanza message) async {
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

    return StableStanzaId(
      originId: originId,
      stanzaId: stanzaId,
      stanzaIdBy: stanzaIdBy
    );
  }
  
  Future<void> _handleChatMarker(Stanza message, XMLNode marker) async {
    final attrs = getAttributes();

    if (!["received", "displayed", "acknowledged"].contains(marker.tag)) {
      logger.warning("Unknown message marker '${marker.tag}' found.");
      return;
    }

    attrs.sendEvent(ChatMarkerEvent(
        type: marker.tag,
        sid: message.id!,
        stanzaId: await _getStanzaId(message)
    ));
  }

  StatelessMediaSharingData? _getSIMS(Stanza message) {
    final references = message.findTags("reference", xmlns: referenceXmlns);
    for (final ref in references) {
      final sims = ref.firstTag("media-sharing", xmlns: simsXmlns);
      if (sims != null) return parseSIMSElement(sims);
    }

    return null;
  }
  
  Future<bool> _onMessage(Stanza message) async {
    // First check if it's a carbon
    final from = JID.fromString(message.attributes["from"]!);
    final received = message.firstTag("received", xmlns: carbonsXmlns);
    final attrs = getAttributes();
    bool isCarbon = false;
    if (received != null) {
      final cm = attrs.getManagerById(carbonsManager) as CarbonsManager?;

      // Ignore invalid carbons
      if (cm == null || !cm.isCarbonValid(from)) return true;

      final forwarded = received.firstTag("forwarded", xmlns: forwardedXmlns)!;
      message = unpackForwarded(forwarded);
      isCarbon = true;
    }

    final sfs = message.firstTag("file-sharing", xmlns: sfsXmlns);
    final sims = _getSIMS(message);
    final body = message.firstTag("body");
    if (body == null && sfs == null && sims == null) {
      final marker = message.firstTagByXmlns(chatMarkersXmlns);
      if (marker != null) {
        // Response to a marker
        await _handleChatMarker(message, marker);
      }

      return true;
    }

    OOBData? oob;
    final oobTag = message.firstTag("x", xmlns: oobDataXmlns);
    if (oobTag != null) {
      final url = oobTag.firstTag("url");
      final desc = oobTag.firstTag("desc");
      oob = OOBData(
        url: url?.innerText(),
        desc: desc?.innerText()
      );
    }
    
    getAttributes().sendEvent(MessageEvent(
      body: body != null ? body.innerText() : "",
      fromJid: from,
      sid: message.attributes["id"]!,
      stanzaId: await _getStanzaId(message),
      isCarbon: isCarbon,
      oob: oob,
      sfs: sfs != null ? parseSFSElement(sfs) : null,
      sims: sims
    ));

    return true;
  }

  /// Send a message to [to] with the content [body].
  void sendMessage(String body, String to) {
    getAttributes().sendStanza(Stanza.message(
        to: to,
        type: "normal",
        children: [
          XMLNode(tag: "body", text: body)
        ]
    ));
  }
}
