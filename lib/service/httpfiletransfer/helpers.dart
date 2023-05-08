import 'dart:io';
import 'package:moxxyv2/service/files.dart';
import 'package:moxxyv2/service/httpfiletransfer/client.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Calculates the path for a given file to be saved to and, if neccessary, create it.
Future<String> getDownloadPath(
  String filename,
  Map<String, String>? plaintextHashes,
) async {
  final basePath = path.join(
    (await getApplicationDocumentsDirectory()).path,
    'media',
  );
  final baseDir = Directory(basePath);

  if (!baseDir.existsSync()) {
    await baseDir.create(recursive: true);
  }

  // Keep the extension of the file. Otherwise Android will be really confused
  // as to what it should open the file with.
  final ext = path.extension(filename);
  final hash = getStrongestHashFromMap(plaintextHashes);
  return path.join(
    basePath,
    hash != null
        ? '$hash.$ext'
        : '$filename.${DateTime.now().millisecondsSinceEpoch}.$ext',
  );
}

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
