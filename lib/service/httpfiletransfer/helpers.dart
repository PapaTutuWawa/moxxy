import 'package:moxxyv2/service/httpfiletransfer/client.dart';

/// Returns true if the request was successful based on [statusCode].
/// Based on https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
bool isRequestOkay(int? statusCode) {
  return statusCode != null && statusCode >= 200 && statusCode <= 399;
}

class FileUploadMetadata {
  const FileUploadMetadata({this.mime, this.size});
  final String? mime;
  final int? size;
}

/// Returns the size of the file at [url] in octets. If an error occurs or the server
/// does not specify the Content-Length header, null is returned.
/// See https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Length
Future<FileUploadMetadata> peekFile(String url) async {
  final result = await peekUrl(Uri.parse(url));

  return FileUploadMetadata(
    mime: result?.contentType,
    size: result?.contentLength,
  );
}
