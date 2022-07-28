import 'package:moxxyv2/xmpp/managers/base.dart';
import 'package:moxxyv2/xmpp/managers/data.dart';
import 'package:moxxyv2/xmpp/managers/handlers.dart';
import 'package:moxxyv2/xmpp/managers/namespaces.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stanza.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';
import 'package:moxxyv2/xmpp/xeps/staging/file_thumbnails.dart';

class StatelessMediaSharingData {

  const StatelessMediaSharingData({ required this.mediaType, required this.size, required this.description, required this.hashes, required this.url, required this.thumbnails });
  final String mediaType;
  final int size;
  final String description;
  final Map<String, String> hashes; // algo -> hash value
  final List<Thumbnail> thumbnails;
  
  final String url;
}

StatelessMediaSharingData parseSIMSElement(XMLNode node) {
  assert(node.attributes['xmlns'] == simsXmlns, 'Invalid element xmlns');
  assert(node.tag == 'media-sharing', 'Invalid element name');

  final file = node.firstTag('file', xmlns: jingleFileTransferXmlns)!;
  final hashes = <String, String>{};
  for (final i in file.findTags('hash', xmlns: hashXmlns)) {
    hashes[i.attributes['algo']! as String] = i.innerText();
  }

  var url = '';
  final references = file.firstTag('sources')!.findTags('reference', xmlns: referenceXmlns);
  for (final i in references) {
    if (i.attributes['type'] != 'data') continue;

    final uri = i.attributes['uri']! as String;
    if (!uri.startsWith('https://')) continue;

    url = uri;
    break;
  }

  final thumbnails = List<Thumbnail>.empty(growable: true);
  for (final child in file.children) {
    // TODO(Unknown): Handle other thumbnails
    if (child.tag == 'file-thumbnail' && child.attributes['xmlns'] == fileThumbnailsXmlns) {
      final thumb = parseFileThumbnailElement(child);
      if (thumb != null) {
        thumbnails.add(thumb);
      }
    }
  }
  
  return StatelessMediaSharingData(
    mediaType: file.firstTag('media-type')!.innerText(),
    size: int.parse(file.firstTag('size')!.innerText()),
    description: file.firstTag('description')!.innerText(),
    url: url,
    hashes: hashes,
    thumbnails: thumbnails,
  );
}

class SIMSManager extends XmppManagerBase {
  @override
  String getName() => 'SIMSManager';

  @override
  String getId() => simsManager;

  @override
  List<String> getDiscoFeatures() => [ simsXmlns ];
  
  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: 'message',
      callback: _onMessage,
      tagName: 'reference',
      tagXmlns: referenceXmlns,
      // Before the message handler
      priority: -99,
    )
  ];

  @override
  Future<bool> isSupported() async => true;
  
  Future<StanzaHandlerData> _onMessage(Stanza message, StanzaHandlerData state) async {
    final references = message.findTags('reference', xmlns: referenceXmlns);
    for (final ref in references) {
      final sims = ref.firstTag('media-sharing', xmlns: simsXmlns);
      if (sims != null) return state.copyWith(sims: parseSIMSElement(sims));
    }

    return state;
  }
}
