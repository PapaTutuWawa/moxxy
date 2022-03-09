import "dart:io";
import "dart:convert";
import "dart:async";

import "package:moxxyv2/xmpp/rfcs/rfc_2782.dart";

import "package:logging/logging.dart";
import "package:moxdns/moxdns.dart";

// NOTE: https://www.iana.org/assignments/tls-extensiontype-values/tls-extensiontype-values.xhtml#alpn-protocol-ids
const xmppClientALPNId = "xmpp-client";

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
  /// [domain] is the domain that TLS should be validated against, in case the Socket
  /// provides TLS encryption. Returns true if the connection has been successfully
  /// established. Returns false if the connection has failed.
  Future<bool> connect(String domain, { String? host, int? port });

  /// Returns true if the socket is secured, e.g. using TLS.
  bool isSecure();

  /// Upgrades the connection into a secure version, e.g. by performing a TLS upgrade.
  /// May do nothing if the connection is always secure.
  /// Returns true if the socket has been successfully upgraded. False otherwise.
  Future<bool> secure();
}

/// TCP socket implementation for [XmppConnection]
class TCPSocketWrapper extends BaseSocketWrapper {
  late Socket _socket;
  final StreamController<String> _dataStream;
  final StreamController<Object> _errorStream;
  late StreamSubscription<dynamic> _socketSubscription;

  final Logger _log;

  bool _secure;
  
  TCPSocketWrapper()
  : _log = Logger("TCPSocketWrapper"),
  _dataStream = StreamController.broadcast(),
  _errorStream = StreamController.broadcast(),
  _secure = false;

  @override
  bool isSecure() => _secure;
  
  Future<bool> _xep368Connect(String domain) async {
    // TODO: Maybe do DNSSEC one day
    final results = await Moxdns.srvQuery("_xmpps-client._tcp.$domain", false);
    if (results.isEmpty) {
      return false;
    }

    results.sort(srvRecordSortComparator);
    for (final srv in results) {
      try {
        _log.finest("Attempting secure conection to ${srv.target}:${srv.port}...");
        _socket = await SecureSocket.connect(
          srv.target,
          srv.port,
          timeout: const Duration(seconds: 5),
          supportedProtocols: const [ xmppClientALPNId ],
          onBadCertificate: (certificate) {
            // TODO
            //final isExpired = certificate.endValidity.isAfter(DateTime.now());
            //return !isExpired /*&& certificate.domain == domain */;

            _log.fine("Bad certificate: ${certificate.toString()}");
            
            return false;
          }
        );

        _secure = true;
        _log.finest("Success!");
        return true;
      } on SocketException {
        return false;
      }
    }

    return false;
  }
  
  Future<bool> _rfc6120Connect(String domain) async {
    // TODO: Maybe do DNSSEC one day
    final results = await Moxdns.srvQuery("_xmpp-client._tcp.$domain", false);
    if (results.isEmpty) {
      return await _rfc6120FallbackConnect(domain);
    }

    results.sort(srvRecordSortComparator);

    for (final srv in results) {
      try {
        _log.finest("Attempting connection to ${srv.target}:${srv.port}...");
        _socket = await Socket.connect(
          srv.target,
          srv.port,
          timeout: const Duration(seconds: 5)
        );
        _log.finest("Success!");
        return true;
      } on SocketException {
        _log.finest("Failure!");
        continue;
      }
    }

    return false;
  }

  Future<bool> _hostPortConnect(String host, int port) async {
    try {
      _log.finest("Attempting fallback connection to $host:$port...");
      _socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 5)
      );
      _log.finest("Success!");
      return true;
    } on SocketException {
      _log.finest("Failure!");
      return false;
    }
  }
  
  Future<bool> _rfc6120FallbackConnect(String domain) async {
    return await _hostPortConnect(domain, 5222);
  }

  @override
  Future<bool> secure() async {
    if (_secure) {
      _log.warning("Connection is already marked as secure. Doing nothing");
      return true;
    }

    try {
      _socket = await SecureSocket.secure(
        _socket,
        supportedProtocols: const [ xmppClientALPNId ]
      );

      _secure = true;
      _setupStreams();
      return true;
    } on SocketException {
      return false;
    }
  }

  void _setupStreams() {
    _socketSubscription = _socket.listen(
      (List<int> event) {
        _dataStream.add(utf8.decode(event));
      },
      onError: (Object error) {
        _log.severe(error.toString());
        _errorStream.add(error);
      }
    );
  }
  
  @override
  Future<bool> connect(String domain, { String? host, int? port }) async {
    _secure = false;

    // Connection order:
    // 1. host:port, if given
    // 2. XEP-0368
    // 3. RFC 6120
    // 4. RFC 6120 fallback

    if (host != null && port != null) {
      _log.finest("Specific host and port given");
      if (await _hostPortConnect(host, port)) {
        _setupStreams();
        return true;
      }
    }

    if (await _xep368Connect(domain)) {
      _setupStreams();
      return true;
    }

    // NOTE: _rfc6120Connect already attempts the fallback
    if (await _rfc6120Connect(domain)) {
      _setupStreams();
      return true;
    }

    return false;
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
      _log.finest("==> " + data);
    }

    try {
      _socket.write(data);
    } on SocketException catch (e) {
      _errorStream.add(e);
    }
  }
}
