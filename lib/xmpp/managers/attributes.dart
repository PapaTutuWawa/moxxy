import 'dart:async';

import 'package:moxxyv2/xmpp/connection.dart';
import 'package:moxxyv2/xmpp/events.dart';
import 'package:moxxyv2/xmpp/jid.dart';
import 'package:moxxyv2/xmpp/managers/base.dart';
import 'package:moxxyv2/xmpp/negotiators/negotiator.dart';
import 'package:moxxyv2/xmpp/settings.dart';
import 'package:moxxyv2/xmpp/socket.dart';
import 'package:moxxyv2/xmpp/stanza.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';

class XmppManagerAttributes {
  
  XmppManagerAttributes({
    required this.sendStanza,
    required this.sendNonza,
    required this.getManagerById,
    required this.sendEvent,
    required this.getConnectionSettings,
    required this.isFeatureSupported,
    required this.getFullJID,
    required this.getSocket,
    required this.getConnection,
    required this.getNegotiatorById,
  });
  /// Send a stanza whose response can be awaited.
  final Future<XMLNode> Function(Stanza stanza, { StanzaFromType addFrom, bool addId, bool awaitable, bool encrypted}) sendStanza;

  /// Send a nonza.
  final void Function(XMLNode) sendNonza;

  /// Send an event to the connection's event channel.
  final void Function(XmppEvent) sendEvent;

  /// Get the connection settings of the attached connection.
  final ConnectionSettings Function() getConnectionSettings;

  /// (Maybe) Get a Manager attached to the connection by its Id.
  final T? Function<T extends XmppManagerBase>(String) getManagerById;

  /// Returns true if a server feature is supported
  final bool Function(String) isFeatureSupported;
  
  /// Returns the full JID of the current account
  final JID Function() getFullJID;

  /// Returns the current socket. MUST NOT be used to send data.
  final BaseSocketWrapper Function() getSocket;

  /// Return the [XmppConnection] the manager is registered against.
  final XmppConnection Function() getConnection;

  final T? Function<T extends XmppFeatureNegotiatorBase>(String) getNegotiatorById;
}
