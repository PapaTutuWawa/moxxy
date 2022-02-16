import "package:cryptography/cryptography.dart";

/// Returns the hash algorithm specified by its name, according to XEP-0414.
HashAlgorithm? getHashByName(String name) {
  switch (name) {
    case "sha-1": return Sha1();
    case "sha-256": return Sha256();
    case "sha-512": return Sha512();
    // NOTE: cryptography provides an implementation of blake2b, however,
    //       I have no idea what it's output length is and you cannot set
    //       one. => New dependency
    //case "blake2b-256": TODO;
    // hashLengthInBytes == 64 => 512?
    case "blake2b-512": Blake2b();
    // NOTE: cryptography does not provide SHA3 hashes => New dependency
    //case "sha3-256": TODO;
    //case "sha3-512": TODO;
  }

  assert(name == "UNKNOWN");
}
