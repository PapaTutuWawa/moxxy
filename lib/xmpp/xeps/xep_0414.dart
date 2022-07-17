import 'package:cryptography/cryptography.dart';

class InvalidHashAlgorithmException implements Exception {

  InvalidHashAlgorithmException(this.name);
  final String name;

  String errMsg() => 'Invalid hash algorithm: $name';
}

/// Returns the hash algorithm specified by its name, according to XEP-0414.
HashAlgorithm? getHashByName(String name) {
  switch (name) {
    case 'sha-1': return Sha1();
    case 'sha-256': return Sha256();
    case 'sha-512': return Sha512();
    // NOTE: cryptography provides an implementation of blake2b, however,
    //       I have no idea what it's output length is and you cannot set
    //       one. => New dependency
    // TODO(Unknown): Implement
    //case "blake2b-256": ;
    // hashLengthInBytes == 64 => 512?
    case 'blake2b-512': Blake2b();
    // NOTE: cryptography does not provide SHA3 hashes => New dependency
    // TODO(Unknown): Implement
    //case "sha3-256": ;
    // TODO(Unknown): Implement
    //case "sha3-512": ;
  }

  throw InvalidHashAlgorithmException(name);
}
