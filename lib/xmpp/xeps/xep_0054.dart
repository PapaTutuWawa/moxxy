import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/stanza.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/managers/handlers.dart";

class vCardPhoto {
  final String? binval;

  const vCardPhoto({ this.binval });
}

class vCard {
  final String? nickname;
  final String? url;
  final vCardPhoto? photo;

  const vCard({ this.nickname, this.url, this.photo });
}

class vCardManager extends XmppManagerBase {
  final Map<String, String> _lastHash;

  vCardManager() : _lastHash = {}, super();
  
  @override
  String getId() => vcardManager;

  @override
  String getName() => "vCardManager";

  @override
  List<StanzaHandler> getStanzaHandlers() => [
    StanzaHandler(stanzaTag: "presence", tagName: "x", tagXmlns: vCardTempUpdate, callback: _onPresence)
  ];

  /// In case we get the avatar hash some other way.
  void setLastHash(String jid, String hash) {
    _lastHash[jid] = hash;
  }
  
  Future<bool> _onPresence(Stanza presence) async {
    final x = presence.firstTag("x", xmlns: vCardTempUpdate)!;
    final hash = x.firstTag("photo")!.innerText();

    final from = JID.fromString(presence.from!).toBare().toString();
    final lastHash = _lastHash[from];
    if (lastHash != hash) {
      _lastHash[from] = hash;
      final vcard = await requestVCard(from);

      if (vcard != null) {
        final binval = vcard.photo?.binval;
        if (binval != null) {
          getAttributes().sendEvent(AvatarUpdatedEvent(jid: from, base64: binval, hash: hash));
        } else {
          logger.warning("No avatar data found");
        }
      } else {
        logger.warning("Failed to retrieve vCard for $from");
      }
    }
    
    return true;
  }
  
  vCardPhoto? _parseVCardPhoto(XMLNode? node) {
    if (node == null) return null;

    return vCardPhoto(
      binval: node.firstTag("BINVAL")?.innerText()
    );
  }
  
  vCard _parseVCard(XMLNode vcard) {
    String? nickname = vcard.firstTag("NICKNAME")?.innerText();
    String? url = vcard.firstTag("URL")?.innerText();
    
    return vCard(
      url: url,
      nickname: nickname,
      photo: _parseVCardPhoto(vcard.firstTag("PHOTO"))
    );
  }
  
  Future<vCard?> requestVCard(String jid) async {
    final result = await getAttributes().sendStanza(
      Stanza.iq(
        to: jid,
        type: "get",
        children: [
          XMLNode.xmlns(
            tag: "vCard",
            xmlns: vCardTempXmlns
          )
        ]
      )
    );

    if (result.attributes["type"] != "result") return null;
    final vcard = result.firstTag("vCard", xmlns: vCardTempXmlns);
    if (vcard == null) return null;
    
    return _parseVCard(vcard);
  } 
}
