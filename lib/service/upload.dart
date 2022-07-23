import 'dart:io';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

// TODO(Unknown): Make this more reliable:
//       - Retry if a download failed, e.g. because we lost internet connection
//       - hold a queue of files to download
class UploadService {
  UploadService() : _tasks = {}, _log = Logger('UploadService');
  final Logger _log;
  // Path of file -> Jid to send to
  final Map<String, String> _tasks;

  /// Upload the file at [path] to the server after requesting a slot.
  Future<bool> uploadFile(String path, String putUrl, Map<String, String> headers) async { 
    _log.finest('Beginning upload of $path');
    final data = await File(path).readAsBytes();
    final putUri = Uri.parse(putUrl);
    final response = await Dio().putUri<dynamic>(
      putUri,
      options: Options(
        headers: headers,
        contentType: 'application/octet-stream',
        requestEncoder: (_, __) => data,
      ),
      data: data,
      onSendProgress: (count, total) {
        // TODO(PapaTutuWawa): Create event
        //_log.finest('Upload progress for $path: $count/$total');
      }
    );

    if (response.statusCode != 201) {
      _log.severe('Upload failed');
      return false;
    }

    _log.fine('Upload was successful');
    return true;
  }
}
