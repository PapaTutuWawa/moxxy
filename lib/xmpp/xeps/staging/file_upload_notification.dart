import 'package:moxxyv2/xmpp/managers/base.dart';
import 'package:moxxyv2/xmpp/managers/data.dart';
import 'package:moxxyv2/xmpp/managers/handlers.dart';
import 'package:moxxyv2/xmpp/managers/namespaces.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stanza.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0446.dart';

/// NOTE: Specified by https://github.com/PapaTutuWawa/custom-xeps/blob/master/xep-xxxx-file-upload-notifications.md

const fileUploadNotificationXmlns = 'proto:urn:xmpp:fun:0';

class FileUploadNotificationManager extends XmppManagerBase {
  FileUploadNotificationManager() : super();

  @override
  String getId() => fileUploadNotificationManager;

  @override
  String getName() => 'FileUploadNotificationManager';

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: 'message',
      tagName: 'file-upload',
      tagXmlns: fileUploadNotificationXmlns,
      callback: _onFileUploadNotificationReceived,
    ),
    StanzaHandler(
      stanzaTag: 'message',
      tagName: 'replaces',
      tagXmlns: fileUploadNotificationXmlns,
      callback: _onFileUploadNotificationReplacementReceived,
    ),
    StanzaHandler(
      stanzaTag: 'message',
      tagName: 'cancelled',
      tagXmlns: fileUploadNotificationXmlns,
      callback: _onFileUploadNotificationCancellationReceived,
    ),
  ];

  @override
  Future<bool> isSupported() async => true;

  Future<StanzaHandlerData> _onFileUploadNotificationReceived(Stanza message, StanzaHandlerData state) async {
    final funElement = message.firstTag('file-upload', xmlns: fileUploadNotificationXmlns)!;
    return state.copyWith(
      fun: FileMetadataData.fromXML(
        funElement.firstTag('file', xmlns: fileMetadataXmlns)!,
      ),
    );
  }

  Future<StanzaHandlerData> _onFileUploadNotificationReplacementReceived(Stanza message, StanzaHandlerData state) async {
    final element = message.firstTag('replaces', xmlns: fileUploadNotificationXmlns)!;
    return state.copyWith(
      funReplacement: element.attributes['id']! as String,
    );
  }

  Future<StanzaHandlerData> _onFileUploadNotificationCancellationReceived(Stanza message, StanzaHandlerData state) async {
    final element = message.firstTag('cancels', xmlns: fileUploadNotificationXmlns)!;
    return state.copyWith(
      funCancellation: element.attributes['id']! as String,
    );
  }
}
