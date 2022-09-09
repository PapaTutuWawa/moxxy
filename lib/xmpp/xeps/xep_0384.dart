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

XMLNode bundleToXML(OmemoBundle bundle) {
  final prekeys = List<XMLNode>.empty(growable: true);
  for (final pk in bundle.opksEncoded.entries) {
    prekeys.add(
      XMLNode(
        tag: 'pk',
        attributes: <String, String>{
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
  
  @override
  String getId() => omemoManager;

  @override
  String getName() => 'OmemoManager';

  // TODO(Unknown): Technically, this is not always true
  @override
  Future<bool> isSupported() async => true;

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: 'iq',
      tagXmlns: omemoXmlns,
      tagName: 'encrypted',
      callback: _onIncomingStanza,
    ),
    StanzaHandler(
      stanzaTag: 'message',
      tagXmlns: omemoXmlns,
      tagName: 'encrypted',
      callback: _onIncomingStanza,
    ),
  ];

  @override
  List<StanzaHandler> getOutgoingPreStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: 'iq',
      tagXmlns: omemoXmlns,
      tagName: 'encrypted',
      callback: _onOutgoingStanza,
    ),
    StanzaHandler(
      stanzaTag: 'message',
      tagXmlns: omemoXmlns,
      tagName: 'encrypted',
      callback: _onOutgoingStanza,
    ),
  ];
  
  /// Commit the OMEMO ratchet to persistent storage, if wanted.
  @visibleForOverriding
  Future<void> commitRatchet(OmemoDoubleRatchet ratchet, String jid, int deviceId) async {}

  /// Commit the session manager to storage, if wanted.
  @visibleForOverriding
  Future<void> commitState() async {}

  Future<StanzaHandlerData> _onOutgoingStanza(Stanza stanza, StanzaHandlerData state) async {
    return state;
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
  Future<List<int>?> retrieveDeviceList(JID jid) async {
    final items = await _retrieveDeviceListPayload(jid);
    if (items == null) return null;

    return items.children
      .map((child) => int.parse(child.attributes['id']! as String))
      .toList();
  }

  /// Retrieves a bundle from entity [jid] with the device id [deviceId].
  Future<OmemoBundle?> retrieveDeviceBundle(JID jid, int deviceId) async {
    final pm = getAttributes().getManagerById<PubSubManager>(pubsubManager)!;
    final bareJid = jid.toBare().toString();
    final item = await pm.getItem(bareJid, omemoBundlesXmlns, '$deviceId');
    if (item == null) return null;

    final spk = item.payload.firstTag('spk')!;
    final spks = item.payload.firstTag('spks')!;
    final ik = item.payload.firstTag('ik')!;
    final prekeysElement = item.payload.firstTag('prekeys')!;
    final prekeys = <int, String>{};
    for (final prekey in prekeysElement.children) {
      prekeys[int.parse(prekey.attributes['id']! as String)] = prekey.innerText();
    }
    
    return OmemoBundle(
      bareJid,
      deviceId,
      spk.innerText(),
      int.parse(spk.attributes['id']! as String),
      spks.innerText(),
      ik.innerText(),
      prekeys,
    );
  }

  Future<bool> publishBundle(OmemoBundle bundle) async {
    final attrs = getAttributes();
    final pm = attrs.getManagerById<PubSubManager>(pubsubManager)!;
    final bareJid = attrs.getFullJID().toBare();

    final deviceList = await _retrieveDeviceListPayload(bareJid);
    if (deviceList == null) return false;

    deviceList.addChild(
      XMLNode(
        tag: 'device',
        attributes: <String, String>{
          'id': '${bundle.id}',
        },
      ),
    );
    
    final deviceListPublish = await pm.publish(
      bareJid.toString(),
      omemoDevicesXmlns,
      deviceList,
      id: '${bundle.id}',
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
