import "dart:async";

import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/stanzas/stanza.dart";

class XmppManagerAttributes {
  /// Somehow display logging info.
  final void Function(String) log;

  /// Send a stanza whose response can be awaited.
  final Future<XMLNode> Function(Stanza stanza, { bool addFrom, bool addId }) sendStanza;

  /// Send a nonza.
  final void Function(XMLNode) sendNonza;

  /// Send an event to the connection's event channel.
  final void Function(XmppEvent) sendEvent;

  /// Inject a raw string into the XML stream to the server.
  final void Function(String) sendRawXml;

  /// Get the connection settings of the attached connection.
  final ConnectionSettings Function() getConnectionSettings;

  /// (Maybe) Get a Manager attached to the connection by its Id.
  final XmppManagerBase? Function(String) getManagerById;

  /// Returns true if a stream feature is supported
  final bool Function(String) isStreamFeatureSupported;

  /// Returns the full JID of the current account
  final FullJID Function() getFullJID;
  
  XmppManagerAttributes({ required this.log, required this.sendStanza, required this.sendNonza, required this.getManagerById, required this.sendEvent, required this.sendRawXml, required this.getConnectionSettings, required this.isStreamFeatureSupported, required this.getFullJID });
}
