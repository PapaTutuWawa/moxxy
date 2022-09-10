import 'dart:convert';
import 'package:meta/meta.dart';
import 'package:moxxyv2/xmpp/events.dart';
import 'package:moxxyv2/xmpp/jid.dart';
import 'package:moxxyv2/xmpp/managers/base.dart';
import 'package:moxxyv2/xmpp/managers/data.dart';
import 'package:moxxyv2/xmpp/managers/handlers.dart';
import 'package:moxxyv2/xmpp/managers/namespaces.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stanza.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0004.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0060.dart';
import 'package:omemo_dart/omemo_dart.dart';

class _DoNotEncrypt {

  const _DoNotEncrypt(this.tag, this.xmlns);
  final String tag;
  final String xmlns;
}

const _doNotEncryptList = [
  // XEP-0033
  _DoNotEncrypt('addresses', extendedAddressingXmlns),
  // XEP-0334
  _DoNotEncrypt('no-permanent-store', messageProcessingHintsXmlns),
  _DoNotEncrypt('no-store', messageProcessingHintsXmlns),
  _DoNotEncrypt('no-copy', messageProcessingHintsXmlns),
  _DoNotEncrypt('store', messageProcessingHintsXmlns),
  // XEP-0359
  _DoNotEncrypt('origin-id', stableIdXmlns),
  _DoNotEncrypt('stanza-id', stableIdXmlns),
];

bool shouldEncrypt(XMLNode node) {
  for (final ignore in _doNotEncryptList) {
    if (node.tag == ignore.tag && (node.attributes['xmlns'] ?? '') == ignore.xmlns) {
      return false;
    }
  }

  return true;
}

XMLNode bundleToXML(OmemoBundle bundle) {
  final prekeys = List<XMLNode>.empty(growable: true);
  for (final pk in bundle.opksEncoded.entries) {
    prekeys.add(
      XMLNode(
        tag: 'pk', attributes: <String, String>{
          'id': '${pk.key}',
        },
        text: pk.value,
      ),
    );
  }

  return XMLNode.xmlns(
    tag: 'bundle',
    xmlns: omemoXmlns,
    children: [
      XMLNode(
        tag: 'spk',
        attributes: <String, String>{
          'id': '${bundle.spkId}',
        },
        text: bundle.spkEncoded,
      ),
      XMLNode(
        tag: 'spks',
        text: bundle.spkSignatureEncoded,
      ),
      XMLNode(
        tag: 'ik',
        text: bundle.ikEncoded,
      ),
      XMLNode(
        tag: 'prekeys',
        children: prekeys,
      ),
    ],
  );
}

OmemoBundle bundleFromXML(JID jid, int id, XMLNode bundle) {
  assert(bundle.attributes['xmlns'] == omemoXmlns, 'Invalid xmlns');

  final spk = bundle.firstTag('spk')!;
  final prekeys = <int, String>{};
  for (final pk in bundle.firstTag('prekeys')!.findTags('pk')) {
    prekeys[int.parse(pk.attributes['id']! as String)] = pk.innerText();
  }

  return OmemoBundle(
    jid.toBare().toString(),
    id,
    spk.innerText(),
    int.parse(spk.attributes['id']! as String),
    bundle.firstTag('spks')!.innerText(),
    bundle.firstTag('ik')!.innerText(),
    prekeys,
  );
}

class OmemoManager extends XmppManagerBase {

  OmemoManager(this.omemoState) : super() {
    omemoState.eventStream.listen((event) async {
      if (event is RatchetModifiedEvent) {
        await commitRatchet(event.ratchet, event.jid, event.deviceId);
      }
    });
  }

  @protected
  final OmemoSessionManager omemoState;

  final Map<JID, List<int>> _deviceMap = {};
  
  @override
  String getId() => omemoManager;

  @override
  String getName() => 'OmemoManager';

  // TODO(Unknown): Technically, this is not always true
  @override
  Future<bool> isSupported() async => true;

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
    /*StanzaHandler(
      stanzaTag: 'iq',
      tagXmlns: omemoXmlns,
      tagName: 'encrypted',
      callback: _onIncomingStanza,
    ),*/
    StanzaHandler(
      stanzaTag: 'message',
      tagXmlns: omemoXmlns,
      tagName: 'encrypted',
      callback: _onIncomingStanza,
    ),
  ];

  @override
  List<StanzaHandler> getOutgoingPreStanzaHandlers() => [
    /*StanzaHandler(
      stanzaTag: 'iq',
      tagXmlns: omemoXmlns,
      tagName: 'encrypted',
      callback: _onOutgoingStanza,
    ),*/
    StanzaHandler(
      stanzaTag: 'message',
      tagXmlns: omemoXmlns,
      tagName: 'encrypted',
      callback: _onOutgoingStanza,
    ),
  ];

  @override
  Future<void> onXmppEvent(XmppEvent event) async {
    if (event is PubSubNotificationEvent) {
      if (event.item.node != omemoDevicesXmlns) return;

      _deviceMap[JID.fromString(event.from)] = event.item.payload.children
        .map((child) => int.parse(child.attributes['id']! as String))
        .toList();
    }
  }
  
  /// Commit the OMEMO ratchet to persistent storage, if wanted.
  @visibleForOverriding
  Future<void> commitRatchet(OmemoDoubleRatchet ratchet, String jid, int deviceId) async {}

  /// Commit the session manager to storage, if wanted.
  @visibleForOverriding
  Future<void> commitState() async {}

  Future<StanzaHandlerData> _onOutgoingStanza(Stanza stanza, StanzaHandlerData state) async {
    if (!state.encrypted) {
      return state;
    }

    final attrs = getAttributes();
    final bareJid = attrs.getFullJID().toBare();
    final toJid = JID.fromString(stanza.to!).toBare();

    final newSessions = List<OmemoBundle>.empty(growable: true);
    final unackedRatchets = await omemoState.getUnacknowledgedRatchets(toJid.toString());
    if ((await omemoState.getDeviceMap()).containsKey(toJid.toString())) {
      newSessions.addAll((await retrieveDeviceBundles(toJid))!);
    } else if (unackedRatchets != null && unackedRatchets.isNotEmpty) {
      for (final id in unackedRatchets) {
        newSessions.add((await retrieveDeviceBundle(toJid, id))!);
      }
    } else {
      final map = await omemoState.getDeviceMap();
      final devices = map[toJid.toString()]!;
      final ratchetSessions = (await getDeviceList(toJid))!;
      if (devices.length != ratchetSessions.length) {
        for (final id in devices) {
          if (ratchetSessions.contains(id)) continue;

          newSessions.add((await retrieveDeviceBundle(toJid, id))!);
        }
      }
    }
    
    final toEncrypt = List<XMLNode>.empty(growable: true);
    final children = List<XMLNode>.empty(growable: true);
    for (final child in stanza.children) {
      if (!shouldEncrypt(child)) {
        children.add(child);
      } else {
        toEncrypt.add(child);
      }
    }

    final envelopeElement = XMLNode.xmlns(
      tag: 'envelope',
      xmlns: sceXmlns,
      children: [
        XMLNode(
          tag: 'content',
          children: toEncrypt,
        ),

        // TODO(PapaTutuWawa): Affix elements
      ],
    );
    final encryptedEnvelope = await omemoState.encryptToJids(
      [
        JID.fromString(stanza.to!).toBare().toString(),
        bareJid.toString(),
      ],
      envelopeElement.toXml(),
      newSessions: newSessions,
    );
    final keyElements = <String, List<XMLNode>>{};
    for (final key in encryptedEnvelope.encryptedKeys) {
      final keyElement = XMLNode(
        tag: 'key',
        attributes: <String, String>{
          'rid': '${key.rid}',
          'kex': key.kex ? 'true' : 'false',
        },
        text: key.value,
      );

      if (keyElements.containsKey(key.jid)) {
        keyElements[key.jid]!.add(keyElement);
      } else {
        keyElements[key.jid] = [keyElement];
      }
    }

    final keysElements = keyElements.entries.map((entry) {
      return XMLNode(
        tag: 'keys',
        attributes: <String, String>{
          'jid': entry.key,
        },
        children: entry.value,
      );
    }).toList();
    
    final encrypted = XMLNode.xmlns(
      tag: 'encrypted',
      xmlns: omemoXmlns,
      children: [
        XMLNode(
          tag: 'payload',
          text: base64.encode(encryptedEnvelope.ciphertext!),
        ),
        XMLNode(
          tag: 'header',
          attributes: <String, String>{
            'sid': '',
          },
          children: keysElements,
        ),
      ],
    );

    children.add(encrypted);
      
    return state.copyWith(
      stanza: state.stanza.copyWith(
        children: children,
      ),
    );
  }


  Future<StanzaHandlerData> _onIncomingStanza(Stanza stanza, StanzaHandlerData state) async {
    final encrypted = stanza.firstTag('encrypted', xmlns: omemoXmlns)!;
    final header = encrypted.firstTag('header')!;
    final payloadElement = encrypted.firstTag('encrypted')!;
    final keys = List<EncryptedKey>.empty(growable: true);
    for (final keysElement in header.findTags('keys')) {
      final jid = keysElement.attributes['jid']! as String;
      for (final key in keysElement.findTags('key')) {
        keys.add(
          EncryptedKey(
            jid,
            int.parse(key.attributes['rid']! as String),
            key.innerText(),
            key.attributes['kex'] == 'true',
          ),
        );
      }
    }

    final decrypted = await omemoState.decryptMessage(
      base64.decode(payloadElement.innerText()),
      JID.fromString(stanza.from!).toBare().toString(),
      int.parse(header.attributes['sid']! as String),
      keys,
    );
    final envelope = XMLNode.fromString(decrypted!);
    // TODO(PapaTutuWawa): Check affix elements

    final children = stanza.children.where(
      (child) => child.tag != 'encrypted' || child.attributes['xmlns'] != omemoXmlns,
    ).toList()
      ..addAll(envelope.firstTag('content')!.children);
    
    return state.copyWith(
      encrypted: true,
      stanza: Stanza(
        to: stanza.to,
        from: stanza.from,
        id: stanza.id,
        type: stanza.type,
        children: children,
        tag: stanza.tag,
        attributes: stanza.attributes as Map<String, String>,
      ),
    );
  }

  Future<XMLNode?> _retrieveDeviceListPayload(JID jid) async {
    final pm = getAttributes().getManagerById<PubSubManager>(pubsubManager)!;
    final items = await pm.getItems(jid.toBare().toString(), omemoDevicesXmlns);
    return items?.first.payload;
  }
  
  /// Retrieves the OMEMO device list from [jid].
  Future<List<int>?> getDeviceList(JID jid) async {
    if (_deviceMap.containsKey(jid)) return _deviceMap[jid]!;

    final items = await _retrieveDeviceListPayload(jid);
    if (items == null) return null;

    final ids = items.children
      .map((child) => int.parse(child.attributes['id']! as String))
      .toList();
    _deviceMap[jid] = ids;
    return ids;
  }

  Future<List<OmemoBundle>?> retrieveDeviceBundles(JID jid) async {
    final pm = getAttributes().getManagerById<PubSubManager>(pubsubManager)!;
    // TODO(PapaTutuWawa): Error handling
    final bundles = (await pm.getItems(jid.toString(), omemoBundlesXmlns))!;

    return bundles.map(
      (bundle) => bundleFromXML(jid, int.parse(bundle.id), bundle.payload),
    ).toList();
  }
  
  /// Retrieves a bundle from entity [jid] with the device id [deviceId].
  Future<OmemoBundle?> retrieveDeviceBundle(JID jid, int deviceId) async {
    final pm = getAttributes().getManagerById<PubSubManager>(pubsubManager)!;
    final bareJid = jid.toBare().toString();
    final item = await pm.getItem(bareJid, omemoBundlesXmlns, '$deviceId');
    if (item == null) return null;

    return bundleFromXML(jid, deviceId, item.payload);
  }

  Future<bool> publishBundle(OmemoBundle bundle) async {
    final attrs = getAttributes();
    final pm = attrs.getManagerById<PubSubManager>(pubsubManager)!;
    final bareJid = attrs.getFullJID().toBare();

    var deviceList = await _retrieveDeviceListPayload(bareJid);
    deviceList ??= XMLNode.xmlns(
      tag: 'devices',
      xmlns: omemoDevicesXmlns,
    );

    final newDeviceList = XMLNode.xmlns(
      tag: 'devices',
      xmlns: omemoDevicesXmlns,
      children: [
        ...deviceList.children,
        XMLNode(
          tag: 'device',
          attributes: <String, String>{
            'id': '${bundle.id}',
          },
        ),
      ]
    );
    
    final deviceListPublish = await pm.publish(
      bareJid.toString(),
      omemoDevicesXmlns,
      newDeviceList,
      id: 'current',
      options: const PubSubPublishOptions(
        accessModel: 'open',
      ),
    );
    if (!deviceListPublish) return false;

    final deviceBundlePublish = await pm.publish(
      bareJid.toString(),
      omemoBundlesXmlns,
      bundleToXML(bundle),
      id: '${bundle.id}',
      options: const PubSubPublishOptions(
        accessModel: 'open',
        maxItems: 'max',
      ),
    );
    
    return deviceBundlePublish;
  }
}
