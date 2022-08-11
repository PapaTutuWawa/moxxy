import 'dart:io';
import 'package:dio/dio.dart';
import 'package:external_path/external_path.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:path/path.dart' as path;

/// Calculates the path for a given file to be saved to and, if neccessary, create it.
Future<String> getDownloadPath(String filename, String conversationJid, String? mime) async {
  String type;
  var prependMoxxy = true;
  if (mime != null && ['image/', 'video/'].any((e) => mime.startsWith(e))) {
    type = ExternalPath.DIRECTORY_PICTURES;
  } else {
    type = ExternalPath.DIRECTORY_DOWNLOADS;
    prependMoxxy = false;
  }
  
  final externalDir = await ExternalPath.getExternalStoragePublicDirectory(type);
  final fileDirectory = prependMoxxy ? path.join(externalDir, 'Moxxy', conversationJid) : externalDir;
  final dir = Directory(fileDirectory);
  if (!dir.existsSync()) {
    await dir.create(recursive: true);
  }

  var i = 0;
  while (true) {
    final filenameSuffix = i == 0 ? '' : '($i)';
    final suffixedFilename = filenameWithSuffix(filename, filenameSuffix);

    final filePath = path.join(fileDirectory, suffixedFilename);
    if (!File(filePath).existsSync()) {
      return filePath;
    }

    i++;
  }
}

/// Returns true if the request was successful based on [statusCode].
/// Based on https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
bool isRequestOkay(int? statusCode) {
  return statusCode != null && statusCode >= 200 && statusCode <= 399;
}

class FileMetadata {

  const FileMetadata({ this.mime, this.size });
  final String? mime;
  final int? size;
}

/// Returns the size of the file at [url] in octets. If an error occurs or the server
/// does not specify the Content-Length header, null is returned.
/// See https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Length
Future<FileMetadata> peekFile(String url) async {
  final response = await Dio().headUri<dynamic>(Uri.parse(url));

  if (!isRequestOkay(response.statusCode)) return const FileMetadata();

  final contentLengthHeaders = response.headers['Content-Length'];
  final contentTypeHeaders = response.headers['Content-Type'];
  
  return FileMetadata(
    mime: contentTypeHeaders?.first,
    size: contentLengthHeaders != null && contentLengthHeaders.isNotEmpty ? int.parse(contentLengthHeaders.first) : null,
  );
}
