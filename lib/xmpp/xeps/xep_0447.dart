import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/xmpp/managers/base.dart';
import 'package:moxxyv2/xmpp/managers/data.dart';
import 'package:moxxyv2/xmpp/managers/handlers.dart';
import 'package:moxxyv2/xmpp/managers/namespaces.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stanza.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0446.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0448.dart';

/// The base class for sources for StatelessFileSharing
// ignore: one_member_abstracts
abstract class StatelessFileSharingSource {
  /// Turn the source into an XML element.
  XMLNode toXml();
}

/// Implementation for url-data source elements.
class StatelessFileSharingUrlSource extends StatelessFileSharingSource {

  StatelessFileSharingUrlSource(this.url);

  factory StatelessFileSharingUrlSource.fromXml(XMLNode element) {
    assert(element.attributes['xmlns'] == urlDataXmlns, 'Element has the wrong xmlns');

    return StatelessFileSharingUrlSource(element.attributes['target']! as String);
  }

  final String url;

  @override
  XMLNode toXml() {
    return XMLNode.xmlns(
      tag: 'url-data',
      xmlns: urlDataXmlns,
      attributes: <String, String>{
        'target': url,
      },
    );
  }
}

class StatelessFileSharingData {

  const StatelessFileSharingData(this.metadata, this.sources);

  /// Parse [node] as a StatelessFileSharingData element.
  factory StatelessFileSharingData.fromXML(XMLNode node) {
    assert(node.attributes['xmlns'] == sfsXmlns, 'Invalid element xmlns');
    assert(node.tag == 'file-sharing', 'Invalid element name');

    final sources = List<StatelessFileSharingSource>.empty(growable: true);
    
    final sourcesElement = node.firstTag('sources')!;
    for (final source in sourcesElement.children) {
      if (source.attributes['xmlns'] == urlDataXmlns) {
        sources.add(StatelessFileSharingUrlSource.fromXml(source));
      } else if (source.attributes['xmlns'] == sfsEncryptionXmlns) {
        sources.add(StatelessFileSharingEncryptedSource.fromXml(source));
      }
    }

    return StatelessFileSharingData(
      FileMetadataData.fromXML(node.firstTag('file')!),
      sources,
    );
  }

  final FileMetadataData metadata;
  final List<StatelessFileSharingSource> sources;

  XMLNode toXML() {
    return XMLNode.xmlns(
      tag: 'file-sharing',
      xmlns: sfsXmlns,
      children: [
        metadata.toXML(),
        XMLNode(
          tag: 'sources',
          children: sources
            .map((source) => source.toXml())
            .toList(),
        ),
      ],
    );
  }

  StatelessFileSharingUrlSource? getFirstUrlSource() {
    return firstWhereOrNull(
      sources,
      (StatelessFileSharingSource source) => source is StatelessFileSharingUrlSource,
    ) as StatelessFileSharingUrlSource?;
  }
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

  @override
  Future<bool> isSupported() async => true;
  
  Future<StanzaHandlerData> _onMessage(Stanza message, StanzaHandlerData state) async {
    final sfs = message.firstTag('file-sharing', xmlns: sfsXmlns)!;

    return state.copyWith(
      sfs: StatelessFileSharingData.fromXML(sfs),
    );
  }
}
