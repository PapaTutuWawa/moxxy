import 'package:meta/meta.dart';

/// A job describing the download of a file.
@immutable
class FileUploadJob {

  const FileUploadJob(this.path, this.putUrl, this.headers, this.mId);
  final String path;
  final String putUrl;
  final Map<String, String> headers;
  final int mId;

  @override
  bool operator ==(Object other) {
    return other is FileUploadJob &&
      path == other.path &&
      putUrl == other.putUrl &&
      headers == other.headers &&
      mId == other.mId;
  }

  @override
  int get hashCode => path.hashCode ^ putUrl.hashCode ^ headers.hashCode ^ mId.hashCode;
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
