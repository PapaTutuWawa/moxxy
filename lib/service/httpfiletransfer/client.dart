import 'dart:async';
import 'dart:io';
import 'package:meta/meta.dart';
import 'package:moxxyv2/service/httpfiletransfer/helpers.dart';

typedef ProgressCallback = void Function(int total, int current);

@immutable
class HttpPeekResult {
  const HttpPeekResult(this.contentType, this.contentLength);
  final String? contentType;
  final int? contentLength;
}

/// Download the file found at [uri] into the file [destination]. [onProgress] is
/// called whenever new data has been downloaded.
///
/// Returns the status code if the server responded. If an error occurs, returns null.
Future<int?> downloadFile(
  Uri uri,
  String destination,
  ProgressCallback onProgress,
) async {
  // TODO(Unknown): How do we close fileSink? Do we have to?
  IOSink? fileSink;
  final client = HttpClient();
  try {
    final req = await client.getUrl(uri);
    final resp = await req.close();

    if (!isRequestOkay(resp.statusCode)) {
      client.close(force: true);
      return resp.statusCode;
    }

    // The size of the remote file
    final length = resp.contentLength;

    fileSink = File(destination).openWrite(mode: FileMode.append);
    var bytes = 0;
    final downloadCompleter = Completer<void>();
    unawaited(
      resp
          .transform(
            StreamTransformer<List<int>, List<int>>.fromHandlers(
              handleData: (data, sink) {
                bytes += data.length;
                onProgress(length, bytes);

                sink.add(data);
              },
              handleDone: (sink) {
                downloadCompleter.complete();
              },
            ),
          )
          .pipe(fileSink),
    );

    // Wait for the download to complete
    await downloadCompleter.future;
    client.close(force: true);
    //await fileSink.close();

    return resp.statusCode;
  } catch (ex) {
    client.close(force: true);
    //await fileSink?.close();
    return null;
  }
}

/// Upload the file found at [filePath] to [destination]. [headers] are HTTP headers
/// that are added to the PUT request. [onProgress] is called whenever new data has
/// been downloaded.
///
/// Returns the status code if the server responded. If an error occurs, returns null.
Future<int?> uploadFile(
  Uri destination,
  Map<String, String> headers,
  String filePath,
  ProgressCallback onProgress,
) async {
  final client = HttpClient();
  try {
    final req = await client.putUrl(destination);
    final file = File(filePath);
    final length = await file.length();
    req.contentLength = length;

    // Set all known headers
    headers.forEach((headerName, headerValue) {
      req.headers.set(headerName, headerValue);
    });

    var bytes = 0;
    final stream = file.openRead().transform(
          StreamTransformer<List<int>, List<int>>.fromHandlers(
            handleData: (data, sink) {
              bytes += data.length;
              onProgress(length, bytes);

              sink.add(data);
            },
            handleDone: (sink) {
              sink.close();
            },
          ),
        );
    await req.addStream(stream);
    final resp = await req.close();

    return resp.statusCode;
  } catch (ex) {
    client.close(force: true);
    return null;
  }
}

/// Sends a HEAD request to [uri].
///
/// Returns the content type and content length if the server responded. If an error
/// occurs, returns null.
Future<HttpPeekResult?> peekUrl(Uri uri) async {
  final client = HttpClient();

  try {
    final req = await client.headUrl(uri);
    final resp = await req.close();

    if (!isRequestOkay(resp.statusCode)) {
      client.close(force: true);
      return null;
    }

    client.close(force: true);
    final contentType = resp.headers['Content-Type'];
    return HttpPeekResult(
      contentType != null && contentType.isNotEmpty ? contentType.first : null,
      resp.contentLength,
    );
  } catch (ex) {
    client.close(force: true);
    return null;
  }
}
