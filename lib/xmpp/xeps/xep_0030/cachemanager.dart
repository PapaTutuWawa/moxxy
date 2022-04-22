import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/stanza.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/xeps/xep_0030/helpers.dart";
import "package:moxxyv2/xmpp/xeps/xep_0030/xep_0030.dart";

class CapabilityHashInfo {
  final String ver;
  final String node;
  final String hash;

  const CapabilityHashInfo({ required this.ver, required this.node, required this.hash });
}

// TODO: Keep track of which cap hashes we are requesting to prevent querying them multiple times
// TODO: Verify the capability hashes
class DiscoCacheManager extends XmppManagerBase {
  final Map<String, CapabilityHashInfo> _capHashCache; // Map full JID to Capability hashes
  final Map<String, DiscoInfo> _discoInfoCache; // Map capability hash to the disco info
  final Map<String, DiscoInfo> _discoInfoNoCapsCache; // Map full JID to disco info in case they do not advertise Entity Capabilities

  DiscoCacheManager(): _capHashCache = {}, _discoInfoCache = {}, _discoInfoNoCapsCache = {}, super();
  
  @override
  String getId() => discoCacheManager;

  @override
  String getName() => "DiscoCache";

  @override
  Future<void> onXmppEvent(XmppEvent event) async {
    if (event is PresenceReceivedEvent) {
      await _onPresence(event.jid, event.presence);
    }
  }

  Future<void> _onPresence(JID from, Stanza presence) async {
    // We are only interested in presence that is just there to indicate its CapHash
    if (presence.attributes["type"] != null) return;

    // We're not interested in presence from other clients connected to the account
    final attrs = getAttributes();
    if (from.toBare() == attrs.getConnectionSettings().jid.toBare()) return;

    final disco = attrs.getManagerById(discoManager)! as DiscoManager;

    // Check if we know the JID and its hash
    if (_capHashCache.containsKey(from.toString())) {
      final capHash = _capHashCache[from.toString()]!;

      if (!_discoInfoCache.containsKey(capHash.ver)) { 
        logger.finest("Know the capability hash of ${from.toString()} but not what the hash stands for. Querying...");
        final info = await disco.discoInfoCapHashQuery(from.toString(), capHash.node, capHash.ver);

        if (info != null) {
          _discoInfoCache[capHash.ver] = info;
        } else {
          logger.warning("Disco query for ${from.toString()} returned nothing.");
        } 
      }

      return;
    }
    
    // Check if there is a capability hash
    final c = presence.firstTag("c", xmlns: capsXmlns);
    if (c != null) {
      final ver = c.attributes["ver"]!;
      final node = c.attributes["node"]!;

      if (!_discoInfoCache.containsKey(ver)) {
        _capHashCache[from.toString()] = CapabilityHashInfo(
          ver: ver,
          node: node,
          hash: c.attributes["hash"]!
        );

        logger.finest("Know the capability hash of ${from.toString()} but not what the hash stands for. Querying...");
        final info = await disco.discoInfoCapHashQuery(from.toString(), node, ver);

        if (info != null) {
          _discoInfoCache[ver] = info;
        } else {
          logger.warning("Disco query for ${from.toString()} returned nothing.");
        }
      }

      return;
    }

    // Fallback: No caps available; do a raw query
    if (!_discoInfoNoCapsCache.containsKey(from.toString())) {
      logger.fine("${from.toString()} does not specify a <c /> in their presence. Querying without Entity Capabilities...");

      final info = await disco.discoInfoQuery(from.toString());
      if (info != null) {
        _discoInfoNoCapsCache[from.toString()] = info;
      } else {
        logger.warning("Disco query for ${from.toString()} returned nothing.");
      }
    }
  }

  // TODO: If we are already requesting a JID or a Capability Hash, return a [Completer]
  //       that completes when the original request finishes.
  Future<DiscoInfo?> getInfoByJid(String jid) async {
    if (_discoInfoNoCapsCache.containsKey(jid)) {
      return _discoInfoNoCapsCache[jid]!;
    }

    final disco = getAttributes().getManagerById(discoManager)! as DiscoManager;
    final capHash = _capHashCache[jid];
    if (capHash != null) {
      final cachedInfo = _discoInfoCache[capHash.ver];
      if (cachedInfo != null) {
        return cachedInfo;
      }

      final info = await disco.discoInfoCapHashQuery(jid, capHash.node, capHash.ver);
      if (info != null) {
        _discoInfoCache[capHash.ver] = info;
        return info;
      } else {
        logger.warning("Disco query for $jid returned nothing.");
        return null;
      }
    }

    final info = await disco.discoInfoQuery(jid);
    if (info != null) {
      _discoInfoNoCapsCache[jid] = info;
      return info;
    } else {
      logger.warning("Disco query for $jid returned nothing.");
      return null;
    }
  }
}
