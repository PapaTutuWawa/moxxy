import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0448.dart';

@immutable
class EncryptionResult {

  const EncryptionResult(this.key, this.iv, this.ciphertext, this.mac);
  final List<int> key;
  final List<int> iv;
  final List<int> ciphertext;
  final List<int> mac;
}

class CryptographyService {

  CryptographyService() : _log = Logger('CryptographyService');
  final Logger _log;

  Future<EncryptionResult> encryptFile(String path, SFSEncryptionType encryption) async {
    _log.finest('Beginning encryption routine for $path');
    Cipher algorithm;
    switch (encryption) {
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
      await File(path).readAsBytes(),
      secretKey: key,
      nonce: iv,
    );

    _log.finest('Encryption done for $path');
    return EncryptionResult(
      [
        ...await key.extractBytes(),
        ...secretBox.mac.bytes,
      ],
      iv,
      secretBox.cipherText,
      secretBox.mac.bytes,
    );
  }

  Future<List<int>> decryptFile(String path, SFSEncryptionType encryption, List<int> key, List<int> iv) async {
    _log.finest('Beginning decryption for $path');
    Cipher algorithm;
    switch (encryption) {
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
    
    final ciphertext = await File(path).readAsBytes();
    final mac = List<int>.empty(growable: true);
    // TODO(PapaTutuWawa): Somehow handle aes256CbcPkcs7
    if (encryption == SFSEncryptionType.aes128GcmNoPadding || encryption == SFSEncryptionType.aes256GcmNoPadding) {
      mac.addAll(ciphertext.sublist(ciphertext.length - 16));
    }

    final secretBox = SecretBox(
      ciphertext,
      nonce: iv,
      mac: Mac(mac),
    );

    final data = await algorithm.decrypt(
      secretBox,
      secretKey: SecretKey(key),
    );
    
    _log.finest('Decryption done for $path');
    return data;
  }
}
