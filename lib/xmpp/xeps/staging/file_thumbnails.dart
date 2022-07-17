import 'package:moxxyv2/xmpp/stringxml.dart';

/// NOTE: Specified by https://github.com/PapaTutuWawa/custom-xeps/blob/master/xep-xxxx-file-thumbnails.md

const fileThumbnailsXmlns = 'proto:urn:xmpp:file-thumbnails:0';
const blurhashThumbnailType = 'blurhash';

abstract class Thumbnail {}

class BlurhashThumbnail extends Thumbnail {

  BlurhashThumbnail({ required this.hash });
  final String hash;
}

Thumbnail? parseFileThumbnailElement(XMLNode node) {
  assert(node.attributes['xmlns'] == fileThumbnailsXmlns, 'Invalid element xmlns');
  assert(node.tag == 'file-thumbnail', 'Invalid element name');

  switch (node.attributes['type']!) {
    case blurhashThumbnailType: {
      final hash = node.firstTag('blurhash')!.innerText();
      return BlurhashThumbnail(hash: hash);
    }
  }

  return null;
}

XMLNode? _fromThumbnail(Thumbnail thumbnail) {
  if (thumbnail is BlurhashThumbnail) {
    return XMLNode(
      tag: 'blurhash',
      text: thumbnail.hash,
    );
  }

  return null;
}

XMLNode constructFileThumbnailElement(Thumbnail thumbnail) {
  final node = _fromThumbnail(thumbnail)!;
  var type = '';
  if (thumbnail is BlurhashThumbnail) {
    type = 'blurhash';
  }

  return XMLNode.xmlns(
    tag: 'file-thumbnail',
    xmlns: fileThumbnailsXmlns,
    attributes: { 'type': type },
    children: [ node ],
  );
}
