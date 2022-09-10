import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/xmpp/events.dart';
import 'package:moxxyv2/xmpp/jid.dart';
import 'package:moxxyv2/xmpp/managers/base.dart';
import 'package:moxxyv2/xmpp/managers/data.dart';
import 'package:moxxyv2/xmpp/managers/handlers.dart';
import 'package:moxxyv2/xmpp/managers/namespaces.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stanza.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';
import 'package:moxxyv2/xmpp/xeps/staging/file_upload_notification.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0066.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0085.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0184.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0333.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0359.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0446.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0447.dart';

class MessageDetails {

  const MessageDetails({
    required this.to,
    this.body,
    this.requestDeliveryReceipt = false,
    this.requestChatMarkers = true,
    this.id,
    this.originId,
    this.quoteBody,
    this.quoteId,
    this.quoteFrom,
    this.chatState,
    this.sfs,
    this.fun,
    this.funReplacement,
    this.funCancellation,
  });
  final String to;
  final String? body;
  final bool requestDeliveryReceipt;
  final bool requestChatMarkers;
  final String? id;
  final String? originId;
  final String? quoteBody;
  final String? quoteId;
  final String? quoteFrom;
  final ChatState? chatState;
  final StatelessFileSharingData? sfs;
  final FileMetadataData? fun;
  final String? funReplacement;
  final String? funCancellation;
}

class MessageManager extends XmppManagerBase {
  @override
  String getId() => messageManager;

  @override
  String getName() => 'MessageManager';

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: 'message',
      callback: _onMessage,
      priority: -100,
    )
  ];

  @override
  Future<bool> isSupported() async => true;
  
  Future<StanzaHandlerData> _onMessage(Stanza _, StanzaHandlerData state) async {
    final message = state.stanza;
    final body = message.firstTag('body');

    getAttributes().sendEvent(MessageEvent(
      body: body != null ? body.innerText() : '',
      fromJid: JID.fromString(message.attributes['from']! as String),
      toJid: JID.fromString(message.attributes['to']! as String),
      sid: message.attributes['id']! as String,
      stanzaId: state.stableId ?? const StableStanzaId(),
      isCarbon: state.isCarbon,
      deliveryReceiptRequested: state.deliveryReceiptRequested,
      isMarkable: state.isMarkable,
      type: message.attributes['type'] as String?,
      oob: state.oob,
      sfs: state.sfs,
      sims: state.sims,
      reply: state.reply,
      chatState: state.chatState,
      fun: state.fun,
      funReplacement: state.funReplacement,
      funCancellation: state.funCancellation,
      encrypted: state.encrypted,
      other: state.other,
    ),);

    return state.copyWith(done: true);
  }

  /// Send a message to to with the content body. If deliveryRequest is true, then
  /// the message will also request a delivery receipt from the receiver.
  /// If id is non-null, then it will be the id of the message stanza.
  /// element to this id. If originId is non-null, then it will create an "origin-id"
  /// child in the message stanza and set its id to originId.
  void sendMessage(MessageDetails details) {
    final stanza = Stanza.message(
      to: details.to,
      type: 'chat',
      id: details.id,
      children: [],
    );

    if (details.quoteBody != null) {
      final fallback = '&gt; ${details.quoteBody!}';

      stanza
        ..addChild(
          XMLNode(tag: 'body', text: '$fallback\n${details.body}'),
        )
        ..addChild(
          XMLNode.xmlns(
            tag: 'reply',
            xmlns: replyXmlns,
            attributes: {
              'to': details.quoteFrom!,
              'id': details.quoteId!
            },
          ),
        )
        ..addChild(
          XMLNode.xmlns(
            tag: 'fallback',
            xmlns: fallbackXmlns,
            attributes: {
              'for': replyXmlns
            },
            children: [
              XMLNode(
                tag: 'body',
                attributes: <String, String>{
                  'start': '0',
                  'end': '${fallback.length}'
                },
              )
            ],
          ),
        );
    } else {
      var body = details.body;
      if (details.sfs != null) {
        body = details.sfs!.url;
      }

      stanza.addChild(
        XMLNode(tag: 'body', text: body),
      );
    }

    if (details.requestDeliveryReceipt) {
      stanza.addChild(makeMessageDeliveryRequest());
    }
    if (details.requestChatMarkers) {
      stanza.addChild(makeChatMarkerMarkable());
    }
    if (details.originId != null) {
      stanza.addChild(makeOriginIdElement(details.originId!));
    }

    if (details.sfs != null) {
      stanza
        ..addChild(details.sfs!.toXML())
        // SFS recommends OOB as a fallback
        ..addChild(constructOOBNode(OOBData(url: details.sfs!.url)),);
    }
    
    if (details.chatState != null) {
      stanza.addChild(
        // TODO(Unknown): Move this into xep_0085.dart
        XMLNode.xmlns(tag: chatStateToString(details.chatState!), xmlns: chatStateXmlns),
      );
    }

    if (details.fun != null) {
      stanza.addChild(
        XMLNode.xmlns(
          tag: 'file-upload',
          xmlns: fileUploadNotificationXmlns,
          children: [
            details.fun!.toXML(),
          ],
        ),
      );
    }

    if (details.funReplacement != null) {
      stanza.addChild(
        XMLNode.xmlns(
          tag: 'replaces',
          xmlns: fileUploadNotificationXmlns,
          attributes: <String, String>{
            'id': details.funReplacement!,
          },
        ),
      );
    }
    
    getAttributes().sendStanza(stanza, awaitable: false);
  }
}
