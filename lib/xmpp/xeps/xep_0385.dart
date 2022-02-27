import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/xeps/staging/file_thumbnails.dart";

class StatelessMediaSharingData {
  final String mediaType;
  final int size;
  final String description;
  final Map<String, String> hashes; // algo -> hash value
  final List<Thumbnail> thumbnails;
  
  final String url;

  const StatelessMediaSharingData({ required this.mediaType, required this.size, required this.description, required this.hashes, required this.url, required this.thumbnails });
}

StatelessMediaSharingData parseSIMSElement(XMLNode node) {
  assert(node.attributes["xmlns"] == simsXmlns);
  assert(node.tag == "media-sharing");

  final file = node.firstTag("file", xmlns: jingleFileTransferXmlns)!;
  final Map<String, String> hashes = {};
  for (final i in file.findTags("hash", xmlns: hashXmlns)) {
    hashes[i.attributes["algo"]] = i.innerText();
  }

  String url = "";
  for (final i in file.firstTag("sources")!.findTags("reference", xmlns: referenceXmlns)) {
    if (i.attributes["type"] != "data") continue;
    if (!i.attributes["uri"]!.startsWith("https://")) continue;

    url = i.attributes["uri"]!;
    break;
  }

  final List<Thumbnail> thumbnails = List.empty(growable: true);
  for (final child in file.children) {
    // TODO: Handle other thumbnails
    if (child.tag == "file-thumbnail" && child.attributes["xmlns"] == fileThumbnailsXmlns) {
      final thumb = parseFileThumbnailElement(child);
      if (thumb != null) {
        thumbnails.add(thumb);
      }
    }
  }
  
  return StatelessMediaSharingData(
    mediaType: file.firstTag("media-type")!.innerText(),
    size: int.parse(file.firstTag("size")!.innerText()),
    description: file.firstTag("description")!.innerText(),
    url: url,
    hashes: hashes,
    thumbnails: thumbnails
  );
}
