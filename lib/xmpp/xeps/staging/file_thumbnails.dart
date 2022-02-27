import "package:moxxyv2/xmpp/stringxml.dart";

/// NOTE: Specified by https://github.com/PapaTutuWawa/custom-xeps/blob/master/xep-xxxx-file-thumbnails.md

const fileThumbnailsXmlns = "proto:urn:xmpp:file-thumbnails:0";
const blurhashThumbnailType = "$fileThumbnailsXmlns:blurhash";

abstract class Thumbnail {}

class BlurhashThumbnail extends Thumbnail {
  final String hash;

  BlurhashThumbnail({ required this.hash });
}

Thumbnail? parseFileThumbnailElement(XMLNode node) {
  assert(node.attributes["xmlns"] == fileThumbnailsXmlns);
  assert(node.tag == "file-thumbnail");

  switch (node.attributes["type"]!) {
    case blurhashThumbnailType: {
      final hash = node.firstTag("blurhash")!.innerText();
      return BlurhashThumbnail(hash: hash);
    }
  }

  return null;
}
