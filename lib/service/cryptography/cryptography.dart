import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/service/cryptography/types.dart';

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
    case SFSEncryptionType.aes128GcmNoPadding:
      return CipherAlgorithm.aes128GcmNoPadding;
    case SFSEncryptionType.aes256GcmNoPadding:
      return CipherAlgorithm.aes256GcmNoPadding;
    case SFSEncryptionType.aes256CbcPkcs7:
      return CipherAlgorithm.aes256CbcPkcs7;
  }
}

class CryptographyService {
  /// Access to hardware-accelerated cryptography
  final MoxxyCryptographyApi _api = MoxxyCryptographyApi();

  /// A logger.
  final Logger _log = Logger('CryptographyService');

  /// Encrypt the file at path [source] and write the encrypted data to [dest]. For the
  /// encryption, use the algorithm indicated by [encryption].
  Future<EncryptionResult> encryptFile(
    String source,
    String dest,
    SFSEncryptionType encryption,
  ) async {
    _log.finest('Beginning encryption routine for $source');
    final key = encryption == SFSEncryptionType.aes128GcmNoPadding
        ? _randomBuffer(16)
        : _randomBuffer(32);
    final iv = _randomBuffer(12);
    final result = (await _api.encryptFile(
      source,
      dest,
      Uint8List.fromList(key),
      Uint8List.fromList(iv),
      _sfsToCipher(encryption),
      'SHA-256',
    ))!;
    _log.finest('Encryption done for $source ($result)');

    return EncryptionResult(
      key,
      iv,
      <HashFunction, String>{
        HashFunction.sha256: base64Encode(result.plaintextHash),
      },
      <HashFunction, String>{
        HashFunction.sha256: base64Encode(result.ciphertextHash),
      },
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
    Map<HashFunction, String> plaintextHashes,
    Map<HashFunction, String> ciphertextHashes,
  ) async {
    _log.finest('Beginning decryption for $source');
    final result = await _api.decryptFile(
      source,
      dest,
      Uint8List.fromList(key),
      Uint8List.fromList(iv),
      _sfsToCipher(encryption),
      // TODO(Unknown): How to we get hash agility here?
      'SHA-256',
    );
    _log.finest('Decryption done for $source (${result != null})');

    var passedPlaintextIntegrityCheck = true;
    var passedCiphertextIntegrityCheck = true;
    for (final entry in plaintextHashes.entries) {
      if (entry.key == HashFunction.sha256) {
        if (base64Encode(result!.plaintextHash) != entry.value) {
          passedPlaintextIntegrityCheck = false;
        } else {
          passedPlaintextIntegrityCheck = true;
        }

        break;
      }
    }
    for (final entry in ciphertextHashes.entries) {
      if (entry.key == HashFunction.sha256) {
        if (base64Encode(result!.ciphertextHash) != entry.value) {
          passedCiphertextIntegrityCheck = false;
        } else {
          passedCiphertextIntegrityCheck = true;
        }

        break;
      }
    }

    return DecryptionResult(
      result != null,
      passedPlaintextIntegrityCheck,
      passedCiphertextIntegrityCheck,
    );
  }

  /// Read the file at [path] and calculate the base64-encoded hash using the algorithm
  /// indicated by [hash].
  Future<String> hashFile(String path, HashFunction hash) async {
    String hashSpec;
    if (hash == HashFunction.sha256) {
      hashSpec = 'SHA-256';
    } else if (hash == HashFunction.sha512) {
      hashSpec = 'SHA-512';
    } else {
      // Android itself does not provide more
      throw Exception();
    }

    _log.finest('Beginning hash generation of $path');
    final data = await _api.hashFile(path, hashSpec);
    _log.finest('Hash generation done for $path');
    return base64Encode(data!);
  }
}
