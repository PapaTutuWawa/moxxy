import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/xeps/xep_0300.dart";
import "package:moxxyv2/xmpp/xeps/staging/file_thumbnails.dart";

class FileMetadataData {
  final String? mediaType;

  // TODO: Maybe create a special type for this
  final String? dimensions;

  final List<Thumbnail> thumbnails;
  final String? desc;
  final Map<String, String> hashes;
  final int? length;
  final String? name;
  final int? size;

  const FileMetadataData({
      this.mediaType,
      this.dimensions,
      this.desc,
      this.length,
      this.name,
      this.size,
      required this.thumbnails,
      Map<String, String>? hashes
  }) : hashes = hashes ?? const {};
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

  // Thumbnails
  final thumbnails = List<Thumbnail>.empty(growable: true);
  for (final i in node.findTags("file-thumbnail")) {
    final thumbnail = parseFileThumbnailElement(i);
    if (thumbnail != null) {
      thumbnails.add(thumbnail);
    }
  }
  
  return FileMetadataData(
    mediaType: node.firstTag("media-type")?.innerText(),
    dimensions: node.firstTag("dimensions")?.innerText(),
    desc: node.firstTag("desc")?.innerText(),
    hashes: hashes,
    length: length,
    name: node.firstTag("name")?.innerText(),
    size: size,
    thumbnails: thumbnails
  );
}

XMLNode constructFileMetadataElement(FileMetadataData data) {
  final node = XMLNode.xmlns(
    tag: "file",
    xmlns: fileMetadataXmlns
  );

  if (data.mediaType != null) node.addChild(XMLNode(tag: "media-type", text: data.mediaType));
  if (data.dimensions != null) node.addChild(XMLNode(tag: "dimensions", text: data.dimensions));
  if (data.desc != null) node.addChild(XMLNode(tag: "desc", text: data.desc));
  if (data.length != null) node.addChild(XMLNode(tag: "length", text: data.length.toString()));
  if (data.name != null) node.addChild(XMLNode(tag: "name", text: data.name));
  if (data.size != null) node.addChild(XMLNode(tag: "size", text: data.size.toString()));
  if (data.hashes.isNotEmpty) {
    for (final hash in data.hashes.entries) {
      node.addChild(
        constructHashElement(hash.key, hash.value)
      );
    }
  }
  if (data.thumbnails.isNotEmpty) {
    for (final thumbnail in data.thumbnails) {
      node.addChild(
        constructFileThumbnailElement(thumbnail)
      );
    }
  }
  
  return node;
}
