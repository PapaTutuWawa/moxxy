import 'package:meta/meta.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/httpfiletransfer/location.dart';
import 'package:moxxyv2/shared/models/message.dart';

/// A job describing the download of a file.
@immutable
class FileUploadJob {
  const FileUploadJob(
    this.recipients,
    this.path,
    this.mime,
    this.encryptMap,
    this.messageMap,
    this.metadataId,
    this.thumbnails,
  );
  final List<String> recipients;
  final String path;
  final String? mime;
  // Recipient -> Should encrypt
  final Map<String, bool> encryptMap;
  // Recipient -> Message
  final Map<String, Message> messageMap;
  final String metadataId;
  final List<Thumbnail> thumbnails;

  @override
  bool operator ==(Object other) {
    return other is FileUploadJob &&
        recipients == other.recipients &&
        path == other.path &&
        messageMap == other.messageMap &&
        mime == other.mime &&
        thumbnails == other.thumbnails &&
        encryptMap == other.encryptMap &&
        metadataId == other.metadataId;
  }

  @override
  int get hashCode =>
      path.hashCode ^
      recipients.hashCode ^
      messageMap.hashCode ^
      mime.hashCode ^
      thumbnails.hashCode ^
      encryptMap.hashCode ^
      metadataId.hashCode;
}

/// A job describing the upload of a file.
@immutable
class FileDownloadJob {
  const FileDownloadJob(
    this.location,
    this.mId,
    this.metadataId,
    this.conversationJid,
    this.mimeGuess, {
    this.shouldShowNotification = true,
  });
  final MediaFileLocation location;
  final int mId;
  final String metadataId;
  final String conversationJid;
  final String? mimeGuess;
  final bool shouldShowNotification;

  @override
  bool operator ==(Object other) {
    return other is FileDownloadJob &&
        location == other.location &&
        mId == other.mId &&
        metadataId == other.metadataId &&
        conversationJid == other.conversationJid &&
        mimeGuess == other.mimeGuess &&
        shouldShowNotification == other.shouldShowNotification;
  }

  @override
  int get hashCode =>
      location.hashCode ^
      mId.hashCode ^
      metadataId.hashCode ^
      conversationJid.hashCode ^
      mimeGuess.hashCode ^
      shouldShowNotification.hashCode;
}
