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

  /// Commit the OMEMO ratchet to persistent storage, if wanted.
  @visibleForOverriding
  Future<void> commitRatchet(OmemoDoubleRatchet ratchet, String jid, int deviceId) async {}

  /// Commit the session manager to storage, if wanted.
  @visibleForOverriding
  Future<void> commitState() async {}

  /// Retrieves the OMEMO device list from [jid].
  Future<List<int>?> retrieveDeviceList(JID jid) async {
    final pm = getAttributes().getManagerById<PubSubManager>(pubsubManager)!;
    final items = await pm.getItems(jid.toBare().toString(), omemoDevicesXmlns);
    if (items == null) return null;

    return items.first.payload.children
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
}
