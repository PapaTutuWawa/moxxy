import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:moxxyv2/service/cryptography/implementations.dart';
import 'package:moxxyv2/service/cryptography/types.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0300.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0448.dart';

class CryptographyService {

  CryptographyService() : _log = Logger('CryptographyService');
  final Logger _log;

  /// Encrypt the file at path [source] and write the encrypted data to [dest]. For the
  /// encryption, use the algorithm indicated by [encryption].
  Future<EncryptionResult> encryptFile(String source, String dest, SFSEncryptionType encryption) async {
    _log.finest('Beginning encryption routine for $source');
    final result = await compute(
      encryptFileImpl,
      EncryptionRequest(
        source,
        dest,
        encryption,
      ),
    );
    _log.finest('Encryption done for $source');

    return result;
  }

  /// Decrypt the file at [source] and write the decrypted version to [dest]. For the
  /// decryption, use the algorithm indicated by [encryption] with the key [key] and the
  /// IV or nonce [iv].
  Future<bool> decryptFile(String source, String dest, SFSEncryptionType encryption, List<int> key, List<int> iv) async {
    _log.finest('Beginning decryption for $source');
    final result = await compute(
      decryptFileImpl,
      DecryptionRequest(
        source,
        dest,
        encryption,
        key,
        iv,
      ),
    );
    _log.finest('Decryption done for $source');
    return result;
  }

  /// Read the file at [path] and calculate the base64-encoded hash using the algorithm
  /// indicated by [hash].
  Future<String> hashFile(String path, HashFunction hash) async {
    _log.finest('Beginning hash generation of $path');
    final data = await compute(
      hashFileImpl,
      HashRequest(path, hash),
    );
    _log.finest('Hash generation done for $path');
    return base64Encode(data);
  }
}
