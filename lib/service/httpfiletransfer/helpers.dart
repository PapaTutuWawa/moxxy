import 'dart:io';
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
