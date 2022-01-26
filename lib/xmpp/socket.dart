import "dart:io";
import "dart:convert";
import "dart:async";

/// This class is the base for a socket that [XmppConnection] can use.
abstract class BaseSocketWrapper {
  /// This must return the unbuffered string stream that the socket receives.
  Stream<String> getDataStream();

  /// This must return errors generated by the socket.
  Stream<Object> getErrorStream();

  /// This must close the socket but not the streams so that the same class can be
  /// reused by calling [this.connect] again.
  void close();

  /// Write [data] into the socket.
  void write(String data);
  
  /// This must connect to [host]:[port] and initialize the streams accordingly.
  Future<void> connect(String host, int port);
}

/// TCP socket implementation for [XmppConnection]
class TCPSocketWrapper extends BaseSocketWrapper {
  late Socket _socket;
  final StreamController<String> _dataStream;
  final StreamController<Object> _errorStream;
  late StreamSubscription<dynamic> _socketSubscription;

  final void Function(String) _log;

  TCPSocketWrapper({ void Function(String) log = print })
  : _log = log,
  _dataStream = StreamController.broadcast(),
  _errorStream = StreamController.broadcast();

  @override
  Future<void> connect(String host, int port) async {
    _socket = await SecureSocket.connect(host, port, supportedProtocols: [ "xmpp-client" ], timeout: const Duration(seconds: 15));

    _socketSubscription = _socket.listen(
      (List<int> event) {
        _dataStream.add(utf8.decode(event));
      },
      onError: (Object error) {
        _log(error.toString());
        _errorStream.add(error);
      }
    );
  }

  @override
  void close() {
    _socket.close();
    _socket.flush();
    _socketSubscription.cancel();
  }

  @override
  Stream<String> getDataStream() => _dataStream.stream.asBroadcastStream();

  @override
  Stream<Object> getErrorStream() => _errorStream.stream.asBroadcastStream();

  @override
  void write(Object? data) {
    if (data != null && data is String) {
      _log("==> " + data);
    }

    try {
      _socket.write(data);
    } on SocketException catch (e) {
      _errorStream.add(e);
    }
  }
}