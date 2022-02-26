import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";

// TODO: Thumbnail
class FileMetadataData {
  final String? mediaType;

  // TODO: Maybe create a special type for this
  final String? dimensions;

  final String? desc;
  final Map<String, String>? hashes;
  final int? length;
  final String? name;
  final int? size;

  const FileMetadataData({
      this.mediaType,
      this.dimensions,
      this.desc,
      this.hashes,
      this.length,
      this.name,
      this.size
  });
}

FileMetadataData parseFileMetadataElement(XMLNode node) {
  assert(node.attributes["xmlns"] == fileMetadataXmlns);
  assert(node.tag == "file");

  final lengthElement = node.firstTag("length");
  final int? length = lengthElement != null ? int.parse(lengthElement.innerText()) : null;
  final sizeElement = node.firstTag("size");
  final int? size = sizeElement != null ? int.parse(sizeElement.innerText()) : null;

  final Map<String, String> hashes = {};
  for (final e in node.findTags("hash")) {
    hashes[e.attributes["algo"]] = e.innerText();
  }
  
  return FileMetadataData(
    mediaType: node.firstTag("media-type")?.innerText(),
    dimensions: node.firstTag("dimensions")?.innerText(),
    desc: node.firstTag("desc")?.innerText(),
    hashes: hashes,
    length: length,
    name: node.firstTag("name")?.innerText(),
    size: size
  );
}
