import 'package:moxxyv2/xmpp/connection.dart';
import 'package:moxxyv2/xmpp/events.dart';
import 'package:moxxyv2/xmpp/jid.dart';
import 'package:moxxyv2/xmpp/managers/base.dart';
import 'package:moxxyv2/xmpp/managers/data.dart';
import 'package:moxxyv2/xmpp/managers/handlers.dart';
import 'package:moxxyv2/xmpp/managers/namespaces.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stanza.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0297.dart';


class CarbonsManager extends XmppManagerBase {

  CarbonsManager() : _isEnabled = false, super();
  bool _isEnabled;
  
  @override
  String getId() => carbonsManager;

  @override
  String getName() => 'CarbonsManager';

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: 'message',
      tagName: 'received',
      tagXmlns: carbonsXmlns,
      callback: _onMessageReceived,
      // Before all managers the message manager depends on
      priority: -98,
    ),
    StanzaHandler(
      stanzaTag: 'message',
      tagName: 'sent',
      tagXmlns: carbonsXmlns,
      callback: _onMessageSent,
      // Before all managers the message manager depends on
      priority: -98,
    )
  ];

  Future<StanzaHandlerData> _onMessageReceived(Stanza message, StanzaHandlerData state) async {
    final from = JID.fromString(message.attributes['from']! as String);
    final received = message.firstTag('received', xmlns: carbonsXmlns)!;
    if (!isCarbonValid(from)) return state.copyWith(done: true);

    final forwarded = received.firstTag('forwarded', xmlns: forwardedXmlns)!;
    final carbon = unpackForwarded(forwarded);

    return state.copyWith(
      isCarbon: true,
      stanza: carbon,
    );
  }

  Future<StanzaHandlerData> _onMessageSent(Stanza message, StanzaHandlerData state) async {
    final from = JID.fromString(message.attributes['from']! as String);
    final sent = message.firstTag('sent', xmlns: carbonsXmlns)!;
    if (!isCarbonValid(from)) return state.copyWith(done: true);

    final forwarded = sent.firstTag('forwarded', xmlns: forwardedXmlns)!;
    final carbon = unpackForwarded(forwarded);

    return state.copyWith(
      isCarbon: true,
      stanza: carbon,
    );
  }
  
  Future<bool> enableCarbons() async {
    final result = await getAttributes().sendStanza(
      Stanza.iq(
        type: 'set',
        children: [
          XMLNode.xmlns(
            tag: 'enable',
            xmlns: carbonsXmlns,
          )
        ],
      ),
      addFrom: StanzaFromType.full,
      addId: true,
    );

    if (result.attributes['type'] != 'result') {
      logger.warning('Failed to enable message carbons');

      return false;
    }

    logger.fine('Successfully enabled message carbons');

    _isEnabled = true;
    return true;
  }

  Future<bool> disableCarbons() async {
    final result = await getAttributes().sendStanza(
      Stanza.iq(
        type: 'set',
        children: [
          XMLNode.xmlns(
            tag: 'disable',
            xmlns: carbonsXmlns,
          )
        ],
      ),
      addFrom: StanzaFromType.full,
      addId: true,
    );

    if (result.attributes['type'] != 'result') {
      logger.warning('Failed to disable message carbons');

      return false;
    }

    logger.fine('Successfully disabled message carbons');
    
    _isEnabled = false;
    return true;
  }

  // TODO(Unknown): Reset _isEnabled if we fail stream resumption or otherwise need to assume a new
  //                state.
  @override
  Future<void> onXmppEvent(XmppEvent event) async {
    if (event is ServerDiscoDoneEvent && !_isEnabled) {
      final attrs = getAttributes();

      if (attrs.isFeatureSupported(carbonsXmlns)) {
        logger.finest('Message carbons supported. Enabling...');
        await enableCarbons();
        logger.finest('Message carbons enabled');
      } else {
        logger.info('Message carbons not supported.');
      }
    }
  }

  bool isCarbonValid(JID senderJid) {
    return _isEnabled && senderJid == getAttributes().getConnectionSettings().jid.toBare();
  }
}
