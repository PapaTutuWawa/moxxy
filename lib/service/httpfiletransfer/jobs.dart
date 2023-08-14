import 'package:meta/meta.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/httpfiletransfer/location.dart';
import 'package:moxxyv2/shared/models/message.dart';

/// A job describing the download of a file.
@immutable
class FileUploadJob {
  const FileUploadJob(
    this.accountJid,
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
  final String accountJid;
  final List<JingleContentThumbnail> thumbnails;

  @override
  bool operator ==(Object other) {
    return other is FileUploadJob &&
        accountJid == other.accountJid &&
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
    this.messageId,
    this.conversationJid,
    this.accountJid,
    this.location,
    this.metadataId,
    this.createMetadataHashes,
    this.mimeGuess, {
    this.shouldShowNotification = true,
  });

  /// The message id.
  final String messageId;

  /// The JID of the conversation we're downloading the file in.
  final String conversationJid;

  /// The associated account.
  final String accountJid;

  /// The location where the file can be found.
  final MediaFileLocation location;

  /// The id of the file metadata describing the file.
  final String metadataId;

  /// Flag indicating whether we should create hash pointers to the file metadata
  /// object.
  final bool createMetadataHashes;

  /// A guess to the files's MIME type.
  final String? mimeGuess;

  /// Flag indicating whether a notification should be shown after successful download.
  final bool shouldShowNotification;

  @override
  bool operator ==(Object other) {
    return other is FileDownloadJob &&
        messageId == other.messageId &&
        conversationJid == other.conversationJid &&
        location == other.location &&
        accountJid == other.accountJid &&
        metadataId == other.metadataId &&
        mimeGuess == other.mimeGuess &&
        shouldShowNotification == other.shouldShowNotification;
  }

  @override
  int get hashCode =>
      conversationJid.hashCode ^
      messageId.hashCode ^
      location.hashCode ^
      metadataId.hashCode ^
      mimeGuess.hashCode ^
      shouldShowNotification.hashCode;
}
