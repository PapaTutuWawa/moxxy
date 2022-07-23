import 'package:moxxyv2/xmpp/managers/base.dart';
import 'package:moxxyv2/xmpp/managers/data.dart';
import 'package:moxxyv2/xmpp/managers/handlers.dart';
import 'package:moxxyv2/xmpp/managers/namespaces.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stanza.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0446.dart';

class StatelessFileSharingData {

  const StatelessFileSharingData({ required this.metadata, required this.url });
  final FileMetadataData metadata;
  final String url;
}

StatelessFileSharingData parseSFSElement(XMLNode node) {
  assert(node.attributes['xmlns'] == sfsXmlns, 'Invalid element xmlns');
  assert(node.tag == 'file-sharing', 'Invalid element name');

  final metadata = parseFileMetadataElement(node.firstTag('file')!);
  final sources = node.firstTag('sources')!;
  final urldata = sources.firstTag('url-data', xmlns: urlDataXmlns);
  final url = urldata!.attributes['target']! as String;

  return StatelessFileSharingData(
    metadata: metadata,
    url: url,
  );
}

XMLNode constructSFSElement(StatelessFileSharingData data) {
  return XMLNode.xmlns(
    tag: 'file-sharing',
    xmlns: sfsXmlns,
    children: [
      constructFileMetadataElement(data.metadata),
      XMLNode(
        tag: 'sources',
        children: [
          XMLNode.xmlns(
            tag: 'url-data',
            xmlns: urlDataXmlns,
            attributes: <String, String>{
              'target': data.url,
            },
          ),
        ],
      ),
    ],
  );
}

class SFSManager extends XmppManagerBase {
  @override
  String getName() => 'SFSManager';

  @override
  String getId() => sfsManager;

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: 'message',
      tagName: 'file-sharing',
      tagXmlns: sfsXmlns,
      callback: _onMessage,
      // Before the message handler
      priority: -99,
    )
  ];

  Future<StanzaHandlerData> _onMessage(Stanza message, StanzaHandlerData state) async {
    final sfs = message.firstTag('file-sharing', xmlns: sfsXmlns)!;

    return state.copyWith(
      sfs: parseSFSElement(sfs),
    );
  }
}
