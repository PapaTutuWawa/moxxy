import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';
import 'package:moxxyv2/xmpp/xeps/staging/file_thumbnails.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0446.dart';

/// NOTE: Specified by https://github.com/PapaTutuWawa/custom-xeps/blob/master/xep-xxxx-file-upload-notifications.md

const fileUploadNotificationXmlns = 'proto:urn:xmpp:fun:0';

class FileUploadNotificationData {

  const FileUploadNotificationData(this.metadata);

  factory FileUploadNotificationData.fromElement(XMLNode node) {
    assert(node.attributes['xmlns'] == fileUploadNotificationXmlns, 'Invalid element xmlns');
    assert(node.tag == 'file-upload', 'Invalid element name');

    return FileUploadNotificationData(
      parseFileMetadataElement(node.firstTag('file', xmlns: fileMetadataXmlns)!),
    );
  }

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
  
  /// Returns true if the message stanza [message] contains a File Upload Notification
  /// element (<file-upload />). If not, returns false.
  static bool containsFileUploadNotification(XMLNode message) {
    return message.firstTag('file-upload', xmlns: fileUploadNotificationXmlns) != null;
  }

  /// Returns true if the message stanza [message] contains a File Upload Notification
  /// replacement element (<replaces />). If not, returns false.
  static bool containsFileUploadNotificationReplace(XMLNode message) {
    return message.firstTag('replaces', xmlns: fileUploadNotificationXmlns) != null;
  }
}
