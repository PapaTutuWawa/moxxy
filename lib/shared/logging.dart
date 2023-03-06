import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:cryptography/cryptography.dart';
import 'package:udp/udp.dart';

Future<List<int>> deriveKey(String key) async {
  return (await Sha256().hash(utf8.encode(key))).bytes;
}

/// Encrypt a log entry with AES-256 in GCM mode. Takes an optional argument [nonce], which
/// SHOULD NEVER be used, except when testing the function.
/// This function is "validated" against
/// https://github.com/monal-im/Monal/blob/develop/UDPLogServer/server.py if
/// [key] is derived using [deriveKey].
Future<List<int>> encryptData(
  List<int> data,
  List<int> key, {
  List<int>? nonce,
}) async {
  final algorithm = AesGcm.with256bits();

  final secretBox = await algorithm.encrypt(
    data,
    secretKey: SecretKey(key),
    nonce: nonce ?? algorithm.newNonce(),
  );

  return [...secretBox.nonce, ...secretBox.mac.bytes, ...secretBox.cipherText];
}

/// Just a wrapper around encoder to compress the payload using GZip.
List<int> compressData(List<int> payload) {
  return GZipEncoder().encode(payload)!;
}

/// Format a log message similarly as to how Monal does it.
List<int> logToPayload(
  String line,
  int timestamp,
  String loglevel,
  int counter, {
  String? filename,
}) {
  return utf8.encode(
    jsonEncode(
      <String, dynamic>{
        'formattedMessage': line,
        'timestamp': timestamp.toString(),
        'level': loglevel,
        '_counter': counter,
        ...filename != null
            ? <String, String>{'filename': filename}
            : <String, String>{}
      },
    ),
  );
}

class UDPLogger {
  UDPLogger()
      : _counter = 0,
        _canSend = false,
        _enabled = true;
  late UDP _sender;
  late Endpoint _target;
  late List<int> _derivedKey;
  int _counter;
  bool _canSend;
  bool _enabled;

  Future<void> init(String key, String ip, int port) async {
    _sender = await UDP.bind(Endpoint.any());
    _derivedKey = await deriveKey(key);
    _target = Endpoint.unicast(InternetAddress(ip), port: Port(port));
    _canSend = true;
    _enabled = true;
  }

  void setEnabled(bool enabled) => _enabled = enabled;
  bool isEnabled() => _enabled;

  Future<void> sendLog(
    String line,
    int timestamp,
    String loglevel, {
    String? filename,
  }) async {
    if (!_canSend || !_enabled) return;

    final rawPayload =
        logToPayload(line, timestamp, loglevel, _counter, filename: filename);
    final compressed = compressData(rawPayload);
    final encrypted = await encryptData(compressed, _derivedKey);

    try {
      await _sender.send(encrypted, _target);
    } catch (_) {
      // Nothing
    }

    _counter++;
  }
}
