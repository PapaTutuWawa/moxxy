import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/xeps/xep_0446.dart";

class StatelessFileSharingData {
  final FileMetadataData metadata;
  final String url;

  const StatelessFileSharingData({ required this.metadata, required this.url });
}

StatelessFileSharingData parseSFSElement(XMLNode node) {
  assert(node.attributes["xmlns"] == sfsXmlns);
  assert(node.tag == "file-sharing");

  final metadata = parseFileMetadataElement(node.firstTag("file")!);
  final sources = node.firstTag("sources")!;
  final urldata = sources.firstTag("url-data", xmlns: urlDataXmlns);
  final url = urldata?.attributes["target"]!;

  return StatelessFileSharingData(
    metadata: metadata,
    url: url
  );
}
