import "dart:io";
import "dart:collection";
import "dart:convert";
import "dart:async";

// TODO: Maybe have a secondary stream that communicates errors and so on
class SocketWrapper {
  late Socket _socket;
  final StreamController<String> _dataStream;
  final StreamController<Object> _errorStream;
  late StreamSubscription<dynamic> _socketSubscription;

  final void Function(String) _log;

  SocketWrapper({ void Function(String) log = print })
  : _log = log,
  _dataStream = StreamController.broadcast(),
  _errorStream = StreamController.broadcast();

  Future<void> connect(String host, int port) async {
    this._socket = await SecureSocket.connect(host, port, supportedProtocols: [ "xmpp-client" ], timeout: Duration(seconds: 15));

    this._socketSubscription = this._socket.listen(
      (List<int> event) {
        this._dataStream.add(utf8.decode(event));
      },
      onError: (Object error) {
        this._log(error.toString());
        this._errorStream.add(error);
      }
    );
  }

  void close() {
    this._socket.close();
    this._socket.flush();
    this._socketSubscription.cancel();
  }

  Stream<String> getDataStream() => this._dataStream.stream.asBroadcastStream();
  Stream<Object> getErrorStream() => this._errorStream.stream.asBroadcastStream();
 
  void write(Object? object) {
    if (object != null && object is String) {
      this._log("==> " + object);
    }

    this._socket.write(object);
  }
}
