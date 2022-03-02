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

XMLNode? _fromThumbnail(Thumbnail thumbnail) {
  if (thumbnail is BlurhashThumbnail) {
    return XMLNode(
      tag: "blurhash",
      text: thumbnail.hash
    );
  }

  return null;
}

XMLNode constructFileThumbnailElement(Thumbnail thumbnail) {
  XMLNode node = _fromThumbnail(thumbnail)!;
  String type = "";
  if (thumbnail is BlurhashThumbnail) {
    type = "blurhash";
  }

  return XMLNode.xmlns(
    tag: "file-thumbnail",
    xmlns: fileThumbnailsXmlns,
    attributes: { "type": type },
    children: [ node ]
  );
}
