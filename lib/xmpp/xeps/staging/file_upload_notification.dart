import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';
import 'package:moxxyv2/xmpp/xeps/staging/file_thumbnails.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0446.dart';

/// NOTE: Specified by https://github.com/PapaTutuWawa/custom-xeps/blob/master/xep-xxxx-file-upload-notifications.md

const fileUploadNotificationXmlns = 'proto:urn:xmpp:fun:0';

class FileUploadNotificationData {

  const FileUploadNotificationData({ required this.metadata, required this.thumbnails });
  final FileMetadataData metadata;
  final List<Thumbnail> thumbnails;
}

XMLNode constructFileUploadNotification(FileMetadataData metadata, List<Thumbnail> thumbnails) {
  final thumbnailNodes = thumbnails.map(constructFileThumbnailElement).toList();
  return XMLNode.xmlns(
    tag: 'file-upload',
    xmlns: fileUploadNotificationXmlns,
    children: [
      constructFileMetadataElement(metadata),
      ...thumbnailNodes
    ],
  );
}

FileUploadNotificationData parseFileUploadNotification(XMLNode node) {
  assert(node.attributes['xmlns'] == fileUploadNotificationXmlns, 'Invalid element xmlns');
  assert(node.tag == 'file-upload', 'Invalid element name');

  final thumbnails = node.findTags('thumbnail', xmlns: fileThumbnailsXmlns).map((t) => parseFileThumbnailElement(t)!).toList();
  
  return FileUploadNotificationData(
    metadata: parseFileMetadataElement(node.firstTag('file', xmlns: fileMetadataXmlns)!),
    thumbnails: thumbnails,
  );
}
