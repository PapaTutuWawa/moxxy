import 'package:moxxyv2/xmpp/stringxml.dart';

/// NOTE: Specified by https://codeberg.org/moxxy/custom-xeps/src/branch/master/xep-xxxx-extensible-file-thumbnails.md

const fileThumbnailsXmlns = 'proto:urn:xmpp:eft:0';
const blurhashThumbnailType = '$fileThumbnailsXmlns:blurhash';

abstract class Thumbnail {}

class BlurhashThumbnail extends Thumbnail {

  BlurhashThumbnail(this.hash);
  final String hash;
}

Thumbnail? parseFileThumbnailElement(XMLNode node) {
  assert(node.attributes['xmlns'] == fileThumbnailsXmlns, 'Invalid element xmlns');
  assert(node.tag == 'file-thumbnail', 'Invalid element name');

  switch (node.attributes['type']!) {
    case blurhashThumbnailType: {
      final hash = node.firstTag('blurhash')!.innerText();
      return BlurhashThumbnail(hash);
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
    type = blurhashThumbnailType;
  }

  return XMLNode.xmlns(
    tag: 'file-thumbnail',
    xmlns: fileThumbnailsXmlns,
    attributes: { 'type': type },
    children: [ node ],
  );
}
