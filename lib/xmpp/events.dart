import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/stanza.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/xeps/xep_0060.dart";
import "package:moxxyv2/xmpp/xeps/xep_0066.dart";
import "package:moxxyv2/xmpp/xeps/xep_0359.dart";
import "package:moxxyv2/xmpp/xeps/xep_0385.dart";
import "package:moxxyv2/xmpp/xeps/xep_0447.dart";

abstract class XmppEvent {}

/// Triggered when the connection state of the [XmppConnection] has
/// changed.
class ConnectionStateChangedEvent extends XmppEvent {
  final XmppConnectionState state;
  final bool resumed;

  ConnectionStateChangedEvent({ required this.state, required this.resumed });
}

/// Triggered when we encounter a stream error.
class StreamErrorEvent extends XmppEvent {
  final String error;

  StreamErrorEvent({ required this.error });
}

/// Triggered after the SASL authentication has failed.
class AuthenticationFailedEvent extends XmppEvent {
  final String saslError;

  AuthenticationFailedEvent({ required this.saslError });
}

/// Triggered when we send a stanza to the socket
class StanzaSentEvent extends XmppEvent {
  final Stanza stanza;

  StanzaSentEvent({ required this.stanza });
}

/// Triggered when we want to ping the connection open
class SendPingEvent extends XmppEvent {}

/// Triggered when the stream resumption was successful
class StreamResumedEvent extends XmppEvent {
  final int h;

  StreamResumedEvent({ required this.h });
}

class MessageEvent extends XmppEvent {
  final String body;
  final JID fromJid;
  final String sid;
  final StableStanzaId stanzaId;
  final bool isCarbon;
  final bool deliveryReceiptRequested;
  final OOBData? oob;
  final StatelessFileSharingData? sfs;
  final StatelessMediaSharingData? sims;

  MessageEvent({
      required this.body,
      required this.fromJid,
      required this.sid,
      required this.stanzaId,
      required this.isCarbon,
      required this.deliveryReceiptRequested,
      this.oob,
      this.sfs,
      this.sims
  });
}

/// Triggered when a client responds to our delivery receipt request
class DeliveryReceiptReceivedEvent extends XmppEvent {
  final JID from;
  final String id;

  DeliveryReceiptReceivedEvent({ required this.from, required this.id });
}

class ChatMarkerEvent extends XmppEvent {
  final JID from;
  final String type;
  final String id;

  ChatMarkerEvent({
      required this.type,
      required this.from,
      required this.id,
  });
}

// Triggered when we received a Stream resumption ID
// TODO: Make the id optional since a server doesn't have to support resumption
class StreamManagementEnabledEvent extends XmppEvent {
  final String resource;
  final String id;

  StreamManagementEnabledEvent({ required this.id, required this.resource });
}

/// Triggered when we bound a resource
class ResourceBindingSuccessEvent extends XmppEvent {
  final String resource;

  ResourceBindingSuccessEvent({ required this.resource });
}

/// Triggered when we receive presence
class PresenceReceivedEvent extends XmppEvent {
  final JID jid;
  final Stanza presence;

  PresenceReceivedEvent(this.jid, this.presence);
}

/// Triggered when we are starting an connection attempt
class ConnectingEvent extends XmppEvent {}

/// Triggered when we found out what the server supports
class ServerDiscoDoneEvent extends XmppEvent {}

/// Triggered when we receive a subscription request
class SubscriptionRequestReceivedEvent extends XmppEvent {
  final JID from;

  SubscriptionRequestReceivedEvent({ required this.from });
}

/// Triggered when we receive a new or updated avatar
class AvatarUpdatedEvent extends XmppEvent {
  final String jid;
  final String base64;
  final String hash;

  AvatarUpdatedEvent({ required this.jid, required this.base64, required this.hash });
}

/// Triggered when a PubSub notification has been received
class PubSubNotificationEvent extends XmppEvent {
  final PubSubItem item;
  final String from;

  PubSubNotificationEvent({ required this.item, required this.from });
}
