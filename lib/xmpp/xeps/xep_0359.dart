import 'package:moxxyv2/xmpp/jid.dart';
import 'package:moxxyv2/xmpp/managers/base.dart';
import 'package:moxxyv2/xmpp/managers/data.dart';
import 'package:moxxyv2/xmpp/managers/handlers.dart';
import 'package:moxxyv2/xmpp/managers/namespaces.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stanza.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0030/helpers.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0030/xep_0030.dart';

/// Represents data provided by XEP-0359.
/// NOTE: [StableStanzaId.stanzaId] must not be confused with the actual id attribute of
///       the message stanza.
class StableStanzaId {

  const StableStanzaId({ this.originId, this.stanzaId, this.stanzaIdBy });
  final String? originId;
  final String? stanzaId;
  final String? stanzaIdBy;
}

XMLNode makeOriginIdElement(String id) {
  return XMLNode.xmlns(
    tag: 'origin-id',
    xmlns: stableIdXmlns,
    attributes: { 'id': id },
  );
}

class StableIdManager extends XmppManagerBase {
  @override
  String getName() => 'StableIdManager';

  @override
  String getId() => stableIdManager;

  @override
  List<String> getDiscoFeatures() => [ stableIdXmlns ];

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: 'message',
      callback: _onMessage,
      // Before the MessageManager
      priority: -99,
    )
  ];

  @override
  Future<bool> isSupported() async => true;
  
  Future<StanzaHandlerData> _onMessage(Stanza message, StanzaHandlerData state) async {
    final from = JID.fromString(message.attributes['from']! as String);
    String? originId;
    String? stanzaId;
    String? stanzaIdBy;
    final originIdTag = message.firstTag('origin-id', xmlns: stableIdXmlns);
    final stanzaIdTag = message.firstTag('stanza-id', xmlns: stableIdXmlns);
    if (originIdTag != null || stanzaIdTag != null) {
      logger.finest('Found Unique and Stable Stanza Id tag');
      final attrs = getAttributes();
      final disco = attrs.getManagerById<DiscoManager>(discoManager)!;
      final result = await disco.discoInfoQuery(from.toString());
      if (result.isType<DiscoInfo>()) {
        final info = result.get<DiscoInfo>();
        logger.finest('Got info for ${from.toString()}');
        if (info.features.contains(stableIdXmlns)) {
          logger.finest('${from.toString()} supports $stableIdXmlns.');

          if (originIdTag != null) {
            originId = originIdTag.attributes['id']! as String;
          }

          if (stanzaIdTag != null) {
            stanzaId = stanzaIdTag.attributes['id']! as String;
            stanzaIdBy = stanzaIdTag.attributes['by']! as String;
          }
        } else {
          logger.finest('${from.toString()} does not support $stableIdXmlns. Ignoring... ');
        }
      }
    }

    return state.copyWith(
      stableId: StableStanzaId(
        originId: originId,
        stanzaId: stanzaId,
        stanzaIdBy: stanzaIdBy,
      ),
    );
  }
}
