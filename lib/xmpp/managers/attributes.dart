import "dart:async";
import "dart:collection";

import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/stanzas/stanza.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/settings.dart";

class XmppManagerAttributes {
  final void Function(String) log;
  final Future<XMLNode> Function(Stanza stanza, { bool addFrom, bool addId }) sendStanza;
  final void Function(XMLNode) sendNonza;
  final void Function(XmppEvent) sendEvent;
  final void Function(String) sendRawXml;
  final ConnectionSettings Function() getConnectionSettings;
  // NOTE: Use dynamic to prevent an import cycle
  final Map<String, dynamic> Function() getManager;

  XmppManagerAttributes({ required this.log, required this.sendStanza, required this.sendNonza, required this.getManager, required this.sendEvent, required this.sendRawXml, required this.getConnectionSettings });
}
