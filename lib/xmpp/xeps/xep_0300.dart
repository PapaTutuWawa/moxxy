import 'package:cryptography/cryptography.dart';
import 'package:moxxyv2/xmpp/managers/base.dart';
import 'package:moxxyv2/xmpp/managers/namespaces.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';

XMLNode constructHashElement(String algo, String base64Hash) {
  return XMLNode.xmlns(
    tag: 'hash',
    xmlns: hashXmlns,
    attributes: { 'algo': algo },
    text: base64Hash,
  );
}

enum HashFunction {
  sha256,
  sha512,
  sha3_256,
  sha3_512,
  blake2b256,
  blake2b512,
}

extension HashNameToEnumExtension on HashFunction {
  String toName() {
    switch (this) {
      case HashFunction.sha256:
        return hashSha256;
      case HashFunction.sha512:
        return hashSha512;
      case HashFunction.sha3_256:
        return hashSha3512;
      case HashFunction.sha3_512:
        return hashSha3512;
      case HashFunction.blake2b256:
        return hashBlake2b256;
      case HashFunction.blake2b512:
        return hashBlake2b512;
    }
  }
}

HashFunction hashFunctionFromName(String name) {
  switch (name) {
    case hashSha256:
      return HashFunction.sha256;
    case hashSha512:
      return HashFunction.sha512;
    case hashSha3256:
      return HashFunction.sha3_256;
    case hashSha3512:
      return HashFunction.sha3_512;
    case hashBlake2b256:
      return HashFunction.blake2b256;
    case hashBlake2b512:
      return HashFunction.blake2b512;
  }

  throw Exception();
}

class CryptographicHashManager extends XmppManagerBase {
  @override
  String getId() => cryptographicHashManager;

  @override
  String getName() => 'CryptographicHashManager';

  @override
  Future<bool> isSupported() async => true;

  @override
  List<String> getDiscoFeatures() => [
    '$hashFunctionNameBaseXmlns:$hashSha256',
    '$hashFunctionNameBaseXmlns:$hashSha512',
    //'$hashFunctionNameBaseXmlns:$hashSha3256',
    //'$hashFunctionNameBaseXmlns:$hashSha3512',
    //'$hashFunctionNameBaseXmlns:$hashBlake2b256',
    '$hashFunctionNameBaseXmlns:$hashBlake2b512',
  ];

  static Future<List<int>> hashFromData(List<int> data, HashFunction function) async {
    // TODO(PapaTutuWawa): Implemen the others as well
    HashAlgorithm algo;
    switch (function) {
      case HashFunction.sha256:
        algo = Sha256();
        break;
      case HashFunction.sha512:
        algo = Sha512();
        break;
      case HashFunction.blake2b512:
        algo = Blake2b();
        break;
      // ignore: no_default_cases
      default:
        throw Exception();
    }

    final digest = await algo.hash(data);
    return digest.bytes;
  }
}
