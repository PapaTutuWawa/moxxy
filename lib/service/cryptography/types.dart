import 'package:meta/meta.dart';
import 'package:moxxmpp/moxxmpp.dart';

@immutable
class EncryptionResult {

  const EncryptionResult(this.key, this.iv, this.plaintextHashes, this.ciphertextHashes);
  final List<int> key;
  final List<int> iv;

  final Map<String, String> plaintextHashes;
  final Map<String, String> ciphertextHashes;
}

@immutable
class EncryptionRequest {

  const EncryptionRequest(this.source, this.dest, this.encryption);
  final String source;
  final String dest;
  final SFSEncryptionType encryption;
}

@immutable
class DecryptionResult {

  const DecryptionResult(
    this.decryptionOkay,
    this.plaintextOkay,
    this.ciphertextOkay,
  );
  final bool decryptionOkay;
  final bool plaintextOkay;
  final bool ciphertextOkay;
}

@immutable
class DecryptionRequest {

  const DecryptionRequest(
    this.source,
    this.dest,
    this.encryption,
    this.key,
    this.iv,
    this.plaintextHashes,
    this.ciphertextHashes,
  );
  final String source;
  final String dest;
  final SFSEncryptionType encryption;
  final List<int> key;
  final List<int> iv;
  final Map<String, String> plaintextHashes;
  final Map<String, String> ciphertextHashes;
}

@immutable
class HashRequest {

  const HashRequest(this.path, this.hash);
  final String path;
  final HashFunction hash;
}
