import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0448.dart';

Future<EncryptionResult> _encryptFile(_EncryptionRequest request) async { 
  Cipher algorithm;
  switch (request.encryption) {
    case SFSEncryptionType.aes128GcmNoPadding:
      algorithm = AesGcm.with128bits();
      break;
    case SFSEncryptionType.aes256GcmNoPadding:
      algorithm = AesGcm.with256bits();
      break;
    case SFSEncryptionType.aes256CbcPkcs7:
      // TODO(Unknown): Implement
      throw Exception();
      // ignore: dead_code
      break;
  }

  // Generate a key and an IV for the file
  final key = await algorithm.newSecretKey();
  final iv = algorithm.newNonce();
  final secretBox = await algorithm.encrypt(
    await File(request.source).readAsBytes(),
    secretKey: key,
    nonce: iv,
  );

  // Write the file
  await File(request.dest).writeAsBytes([
    ...secretBox.cipherText,
    ...secretBox.mac.bytes,
  ]);

  return EncryptionResult(
    await key.extractBytes(),
    iv,
  );
}

Future<void> _decryptFile(_DecryptionRequest request) async {
  Cipher algorithm;
  switch (request.encryption) {
    case SFSEncryptionType.aes128GcmNoPadding:
      algorithm = AesGcm.with128bits();
      break;
    case SFSEncryptionType.aes256GcmNoPadding:
      algorithm = AesGcm.with256bits();
      break;
    case SFSEncryptionType.aes256CbcPkcs7:
      // TODO(Unknown): Implement
      throw Exception();
      // ignore: dead_code
      break;
  }
  
  final ciphertextRaw = await File(request.source).readAsBytes();
  final mac = List<int>.empty(growable: true);
  final ciphertext = List<int>.empty(growable: true);
  // TODO(PapaTutuWawa): Somehow handle aes256CbcPkcs7
  if (request.encryption == SFSEncryptionType.aes128GcmNoPadding ||
      request.encryption == SFSEncryptionType.aes256GcmNoPadding) {
    mac.addAll(ciphertextRaw.sublist(ciphertextRaw.length - 16));
    ciphertext.addAll(ciphertextRaw.sublist(0, ciphertextRaw.length - 16));
  }

  final secretBox = SecretBox(
    ciphertext,
    nonce: request.iv,
    mac: Mac(mac),
  );

  final data = await algorithm.decrypt(
    secretBox,
    secretKey: SecretKey(request.key),
  );

  await File(request.dest).writeAsBytes(data);
}

@immutable
class EncryptionResult {

  const EncryptionResult(this.key, this.iv);
  final List<int> key;
  final List<int> iv;
}

@immutable
class _EncryptionRequest {

  const _EncryptionRequest(this.source, this.dest, this.encryption);
  final String source;
  final String dest;
  final SFSEncryptionType encryption;
}

@immutable
class _DecryptionRequest {

  const _DecryptionRequest(this.source, this.dest, this.encryption, this.key, this.iv);
  final String source;
  final String dest;
  final SFSEncryptionType encryption;
  final List<int> key;
  final List<int> iv;
}

class CryptographyService {

  CryptographyService() : _log = Logger('CryptographyService');
  final Logger _log;

  Future<EncryptionResult> encryptFile(String source, String dest, SFSEncryptionType encryption) async {
    _log.finest('Beginning encryption routine for $source');
    final result = await compute(
      _encryptFile,
      _EncryptionRequest(
        source,
        dest,
        encryption,
      ),
    );
    _log.finest('Encryption done for $source');

    return result;
  }

  Future<void> decryptFile(String source, String dest, SFSEncryptionType encryption, List<int> key, List<int> iv) async {
    _log.finest('Beginning decryption for $source');
    await compute(
      _decryptFile,
      _DecryptionRequest(
        source,
        dest,
        encryption,
        key,
        iv,
      ),
    );
    _log.finest('Decryption done for $source');
  }
}
