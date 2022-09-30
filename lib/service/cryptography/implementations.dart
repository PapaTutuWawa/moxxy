import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:moxxyv2/service/cryptography/types.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0300.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0448.dart';

Future<List<int>> hashFileImpl(HashRequest request) async {
  final data = await File(request.path).readAsBytes();

  return CryptographicHashManager.hashFromData(data, request.hash);
}

Future<EncryptionResult> encryptFileImpl(EncryptionRequest request) async { 
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
  final plaintext = await File(request.source).readAsBytes();
  final secretBox = await algorithm.encrypt(
    plaintext,
    secretKey: key,
    nonce: iv,
  );
  final ciphertext = [
    ...secretBox.cipherText,
    ...secretBox.mac.bytes,
  ];

  // Write the file
  await File(request.dest).writeAsBytes(ciphertext);

  return EncryptionResult(
    await key.extractBytes(),
    iv,
    {
      hashSha256: base64Encode(
        await CryptographicHashManager.hashFromData(plaintext, HashFunction.sha256),
      ),
    },
    {
      hashSha256: base64Encode(
        await CryptographicHashManager.hashFromData(ciphertext, HashFunction.sha256),
      ),
    },
  );
}

// TODO(PapaTutuWawa): Somehow fail when the ciphertext hash is not matching the provided data
Future<void> decryptFileImpl(DecryptionRequest request) async {
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
