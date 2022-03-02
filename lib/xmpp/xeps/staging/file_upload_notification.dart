import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/xeps/xep_0446.dart";
import "package:moxxyv2/xmpp/xeps/staging/file_thumbnails.dart";

/// NOTE: Specified by https://github.com/PapaTutuWawa/custom-xeps/blob/master/xep-xxxx-file-upload-notifications.md

const fileUploadNotificationXmlns = "proto:urn:xmpp:fun:0";

class FileUploadNotificationData {
  final FileMetadataData metadata;
  final List<Thumbnail> thumbnails;

  const FileUploadNotificationData({ required this.metadata, required this.thumbnails });
}

XMLNode constructFileUploadNotification(FileMetadataData metadata, List<Thumbnail> thumbnails) {
  final thumbnailNodes = thumbnails.map((t) => constructFileThumbnailElement(t)).toList();
  return XMLNode.xmlns(
    tag: "file-upload",
    xmlns: fileUploadNotificationXmlns,
    children: [
      constructFileMetadataElement(metadata),
      ...thumbnailNodes
    ]
  );
}

FileUploadNotificationData parseFileUploadNotification(XMLNode node) {
  assert(node.attributes["xmlns"] == fileUploadNotificationXmlns);
  assert(node.tag == "file-upload");

  final thumbnails = node.findTags("thumbnail", xmlns: fileThumbnailsXmlns).map((t) => parseFileThumbnailElement(t)!).toList();
  
  return FileUploadNotificationData(
    metadata: parseFileMetadataElement(node.firstTag("file", xmlns: fileMetadataXmlns)!),
    thumbnails: thumbnails
  );
}
