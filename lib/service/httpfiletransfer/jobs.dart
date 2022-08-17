import 'package:meta/meta.dart';
import 'package:moxxyv2/shared/models/message.dart';

/// A job describing the download of a file.
@immutable
class FileUploadJob {

  const FileUploadJob(this.recipient, this.path, this.copyToPath, this.message);
  final String path;
  final String recipient;
  final Message message;
  final String copyToPath;

  @override
  bool operator ==(Object other) {
    return other is FileUploadJob &&
      recipient == other.recipient &&
      path == other.path &&
      message == other.message &&
      copyToPath == other.copyToPath;
  }

  @override
  int get hashCode => path.hashCode ^ recipient.hashCode ^ message.hashCode ^ copyToPath.hashCode;
}

/// A job describing the upload of a file.
@immutable
class FileDownloadJob {

  const FileDownloadJob(this.url, this.mId, this.conversationJid, this.mimeGuess);
  final String url;
  final int mId;
  final String conversationJid;
  final String? mimeGuess;
  
  @override
  bool operator ==(Object other) {
    return other is FileDownloadJob &&
      url == other.url &&
      mId == other.mId &&
      conversationJid == other.conversationJid &&
      mimeGuess == other.mimeGuess;
  }
  @override
  int get hashCode => url.hashCode ^ mId.hashCode ^ conversationJid.hashCode ^ mimeGuess.hashCode;
}
