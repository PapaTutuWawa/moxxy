import 'dart:io';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/shared/events.dart';

// TODO(Unknown): Make this more reliable:
//       - Retry if a download failed, e.g. because we lost internet connection
//       - hold a queue of files to download
class UploadService {
  UploadService() : _tasks = {}, _log = Logger('UploadService');
  final Logger _log;
  // Path of file -> Jid to send to
  final Map<String, String> _tasks;

  /// Upload the file at [path] to the server after requesting a slot.
  Future<bool> uploadFile(String path, String putUrl, Map<String, String> headers, int mId) async {
    _log.finest('Beginning upload of $path');
    final data = await File(path).readAsBytes();
    final putUri = Uri.parse(putUrl);

    var rateLimit = 0;
    final response = await Dio().putUri<dynamic>(
      putUri,
      options: Options(
        headers: headers,
        contentType: 'application/octet-stream',
        requestEncoder: (_, __) => data,
      ),
      data: data,
      onSendProgress: (count, total) {
        final progress = count.toDouble() / total.toDouble();

        // TODO(Unknown): Maybe rate limit harder
        if (progress * 100 >= rateLimit) {
          sendEvent(
            ProgressEvent(
              id: mId,
              progress: progress == 1 ? 0.99 : progress,
            ),
          );

          rateLimit = (progress * 10).round() * 10;
        }
      },
    );

    if (response.statusCode != 201) {
      _log.severe('Upload failed');
      return false;
    }

    _log.fine('Upload was successful');
    return true;
  }
}
