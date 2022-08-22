import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';
import 'package:moxxyv2/xmpp/xeps/staging/file_thumbnails.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0446.dart';

/// NOTE: Specified by https://github.com/PapaTutuWawa/custom-xeps/blob/master/xep-xxxx-file-upload-notifications.md

const fileUploadNotificationXmlns = 'proto:urn:xmpp:fun:0';

class FileUploadNotificationData {

  const FileUploadNotificationData(this.metadata);
  final FileMetadataData metadata;

  XMLNode toXml() {
    final thumbnailNodes = metadata.thumbnails.map(constructFileThumbnailElement).toList();
    return XMLNode.xmlns(
      tag: 'file-upload',
      xmlns: fileUploadNotificationXmlns,
      children: [
        constructFileMetadataElement(metadata),
        ...thumbnailNodes
      ],
    );
  }
}

FileUploadNotificationData parseFileUploadNotification(XMLNode node) {
  assert(node.attributes['xmlns'] == fileUploadNotificationXmlns, 'Invalid element xmlns');
  assert(node.tag == 'file-upload', 'Invalid element name');

  return FileUploadNotificationData(
    parseFileMetadataElement(node.firstTag('file', xmlns: fileMetadataXmlns)!),
  );
}
