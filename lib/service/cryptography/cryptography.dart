import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxplatform_platform_interface/moxplatform_platform_interface.dart';
import 'package:moxxyv2/service/cryptography/implementations.dart';
import 'package:moxxyv2/service/cryptography/types.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0300.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0448.dart';

List<int> _randomBuffer(int length) {
  final buf = List<int>.empty(growable: true);

  final random = Random.secure();
  for (var i = 0; i < length; i++) {
    buf.add(random.nextInt(256));
  }

  return buf;
}

CipherAlgorithm _sfsToCipher(SFSEncryptionType type) {
  switch (type) {
    case SFSEncryptionType.aes128GcmNoPadding: return CipherAlgorithm.aes128GcmNoPadding;
    case SFSEncryptionType.aes256GcmNoPadding: return CipherAlgorithm.aes256GcmNoPadding;
    case SFSEncryptionType.aes256CbcPkcs7: return CipherAlgorithm.aes256CbcPkcs7;
  }
}

class CryptographyService {

  CryptographyService() : _log = Logger('CryptographyService');
  final Logger _log;

  /// Encrypt the file at path [source] and write the encrypted data to [dest]. For the
  /// encryption, use the algorithm indicated by [encryption].
  Future<EncryptionResult> encryptFile(String source, String dest, SFSEncryptionType encryption) async {
    _log.finest('Beginning encryption routine for $source');
    final key = encryption == SFSEncryptionType.aes128GcmNoPadding ?
      _randomBuffer(16) :
      _randomBuffer(32);
    final iv = encryption == SFSEncryptionType.aes128GcmNoPadding ?
      // TODO(PapaTutuWawa): What was the IV for aes128GcmNoPadding?
      _randomBuffer(12) :
      _randomBuffer(12);
    final result = await MoxplatformPlugin.crypto.encryptFile(
      source,
      dest,
      Uint8List.fromList(key),
      Uint8List.fromList(iv),
      _sfsToCipher(encryption),
    );
    _log.finest('Encryption done for $source ($result)');

    return EncryptionResult(
      key,
      iv,
      const {},
      const {},
    );
  }

  /// Decrypt the file at [source] and write the decrypted version to [dest]. For the
  /// decryption, use the algorithm indicated by [encryption] with the key [key] and the
  /// IV or nonce [iv].
  Future<DecryptionResult> decryptFile(
    String source,
    String dest,
    SFSEncryptionType encryption,
    List<int> key,
    List<int> iv,
    Map<String, String> plaintextHashes,
    Map<String, String> ciphertextHashes,
  ) async {
    _log.finest('Beginning decryption for $source');
    final result = await MoxplatformPlugin.crypto.encryptFile(
      source,
      dest,
      Uint8List.fromList(key),
      Uint8List.fromList(iv),
      _sfsToCipher(encryption),
    );
    _log.finest('Decryption done for $source ($result)');

    return DecryptionResult(
      result,
      // TODO(PapaTutuWawa): Implement
      true,
      true,
    );
  }

  /// Read the file at [path] and calculate the base64-encoded hash using the algorithm
  /// indicated by [hash].
  // TODO(PapaTutuWawa): Handle on the native side
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
