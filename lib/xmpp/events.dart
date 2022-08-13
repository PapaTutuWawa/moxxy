import 'package:moxxyv2/xmpp/connection.dart';
import 'package:moxxyv2/xmpp/jid.dart';
import 'package:moxxyv2/xmpp/stanza.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0030/helpers.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0060.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0066.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0085.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0359.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0385.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0447.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0461.dart';

abstract class XmppEvent {}

/// Triggered when the connection state of the XmppConnection has
/// changed.
class ConnectionStateChangedEvent extends XmppEvent {

  ConnectionStateChangedEvent(this.state, this.before, this.resumed);
  final XmppConnectionState before;
  final XmppConnectionState state;
  final bool resumed;
}

/// Triggered when we encounter a stream error.
class StreamErrorEvent extends XmppEvent {

  StreamErrorEvent({ required this.error });
  final String error;
}

/// Triggered after the SASL authentication has failed.
class AuthenticationFailedEvent extends XmppEvent {

  AuthenticationFailedEvent(this.saslError);
  final String saslError;
}

/// Triggered after the SASL authentication has succeeded.
class AuthenticationSuccessEvent extends XmppEvent {}

/// Triggered when we want to ping the connection open
class SendPingEvent extends XmppEvent {}

/// Triggered when the stream resumption was successful
class StreamResumedEvent extends XmppEvent {

  StreamResumedEvent({ required this.h });
  final int h;
}

/// Triggered when stream resumption failed
class StreamResumeFailedEvent extends XmppEvent {}

class MessageEvent extends XmppEvent {

  MessageEvent({
      required this.body,
      required this.fromJid,
      required this.toJid,
      required this.sid,
      required this.stanzaId,
      required this.isCarbon,
      required this.deliveryReceiptRequested,
      required this.isMarkable,
      this.type,
      this.oob,
      this.sfs,
      this.sims,
      this.reply,
      this.chatState,
  });
  final String body;
  final JID fromJid;
  final JID toJid;
  final String sid;
  final String? type;
  final StableStanzaId stanzaId;
  final bool isCarbon;
  final bool deliveryReceiptRequested;
  final bool isMarkable;
  final OOBData? oob;
  final StatelessFileSharingData? sfs;
  final StatelessMediaSharingData? sims;
  final ReplyData? reply;
  final ChatState? chatState;
}

/// Triggered when a client responds to our delivery receipt request
class DeliveryReceiptReceivedEvent extends XmppEvent {

  DeliveryReceiptReceivedEvent({ required this.from, required this.id });
  final JID from;
  final String id;
}

class ChatMarkerEvent extends XmppEvent {

  ChatMarkerEvent({
      required this.type,
      required this.from,
      required this.id,
  });
  final JID from;
  final String type;
  final String id;
}

// Triggered when we received a Stream resumption ID
class StreamManagementEnabledEvent extends XmppEvent {

  StreamManagementEnabledEvent({
      required this.resource,
      this.id,
      this.location,
  });
  final String resource;
  final String? id;
  final String? location;
}

/// Triggered when we bound a resource
class ResourceBindingSuccessEvent extends XmppEvent {

  ResourceBindingSuccessEvent({ required this.resource });
  final String resource;
}

/// Triggered when we receive presence
class PresenceReceivedEvent extends XmppEvent {

  PresenceReceivedEvent(this.jid, this.presence);
  final JID jid;
  final Stanza presence;
}

/// Triggered when we are starting an connection attempt
class ConnectingEvent extends XmppEvent {}

/// Triggered when we found out what the server supports
class ServerDiscoDoneEvent extends XmppEvent {}

class ServerItemDiscoEvent extends XmppEvent {

  ServerItemDiscoEvent(this.info);
  final DiscoInfo info;
}

/// Triggered when we receive a subscription request
class SubscriptionRequestReceivedEvent extends XmppEvent {

  SubscriptionRequestReceivedEvent({ required this.from });
  final JID from;
}

/// Triggered when we receive a new or updated avatar
class AvatarUpdatedEvent extends XmppEvent {

  AvatarUpdatedEvent({ required this.jid, required this.base64, required this.hash });
  final String jid;
  final String base64;
  final String hash;
}

/// Triggered when a PubSub notification has been received
class PubSubNotificationEvent extends XmppEvent {

  PubSubNotificationEvent({ required this.item, required this.from });
  final PubSubItem item;
  final String from;
}

/// Triggered by the StreamManagementManager if a message stanza has been acked
class MessageAckedEvent extends XmppEvent {

  MessageAckedEvent({ required this.id, required this.to });
  final String id;
  final String to;
}

/// Triggered when receiving a push of the blocklist
class BlocklistBlockPushEvent extends XmppEvent {

  BlocklistBlockPushEvent({ required this.items });
  final List<String> items;
}

/// Triggered when receiving a push of the blocklist
class BlocklistUnblockPushEvent extends XmppEvent {

  BlocklistUnblockPushEvent({ required this.items });
  final List<String> items;
}

/// Triggered when receiving a push of the blocklist
class BlocklistUnblockAllPushEvent extends XmppEvent {
  BlocklistUnblockAllPushEvent();
}
