import "dart:convert";
import "dart:math" show Random;

import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/negotiators/namespaces.dart";
import "package:moxxyv2/xmpp/negotiators/negotiator.dart";
import "package:moxxyv2/xmpp/negotiators/sasl/kv.dart";
import "package:moxxyv2/xmpp/negotiators/sasl/negotiator.dart";
import "package:moxxyv2/xmpp/negotiators/sasl/nonza.dart";

import "package:cryptography/cryptography.dart";
import "package:random_string/random_string.dart";
import "package:saslprep/saslprep.dart";

// NOTE: Inspired by https://github.com/vukoye/xmpp_dart/blob/3b1a0588562b9e591488c99d834088391840911d/lib/src/features/sasl/ScramSaslHandler.dart

enum ScramHashType {
  sha1,
  sha256,
  sha512
}

HashAlgorithm hashFromType(ScramHashType type) {
  switch (type) {
    case ScramHashType.sha1: return Sha1();
    case ScramHashType.sha256: return Sha256();
    case ScramHashType.sha512: return Sha512();
  }
}

const scramSha1Mechanism = "SCRAM-SHA-1";
const scramSha256Mechanism = "SCRAM-SHA-256";
const scramSha512Mechanism = "SCRAM-SHA-512";

String mechanismNameFromType(ScramHashType type) {
  switch (type) {
    case ScramHashType.sha1: return scramSha1Mechanism;
    case ScramHashType.sha256: return scramSha256Mechanism;
    case ScramHashType.sha512: return scramSha512Mechanism;
  }
}

String namespaceFromType(ScramHashType type) {
  switch (type) {
    case ScramHashType.sha1: return saslScramSha1Negotiator;
    case ScramHashType.sha256: return saslScramSha256Negotiator;
    case ScramHashType.sha512: return saslScramSha512Negotiator;
  }
}

class SaslScramAuthNonza extends SaslAuthNonza {
  // This subclassing makes less sense here, but this is since the auth nonza here
  // requires knowledge of the inner state of the Negotiator.
  SaslScramAuthNonza({ required ScramHashType type, required String body }) : super(
    mechanismNameFromType(type), body
  );
}

class SaslScramResponseNonza extends XMLNode {
  SaslScramResponseNonza({ required String body }) : super(
    tag: "response",
    attributes: {
      "xmlns": saslXmlns,
    },
    text: body
  );
}

enum ScramState {
  preSent,
  initialMessageSent,
  challengeResponseSent,
  error
}

const gs2Header = "n,,";

class SaslScramNegotiator extends SaslNegotiator {
  String? clientNonce;
  String initialMessageNoGS2;
  final ScramHashType hashType;
  final HashAlgorithm _hash;
  String _serverSignature;

  // The internal state for performing the negotiation
  ScramState _scramState;
  
  // NOTE: NEVER, and I mean, NEVER set clientNonce or initalMessageNoGS2. They are just there for testing
  SaslScramNegotiator(
    int priority,
    this.initialMessageNoGS2,
    this.clientNonce,
    this.hashType
  ) :
    _hash = hashFromType(hashType),
    _serverSignature = "",
    _scramState = ScramState.preSent,
    super(priority, namespaceFromType(hashType), mechanismNameFromType(hashType));

  Future<List<int>> calculateSaltedPassword(String salt, int iterations) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac(_hash),
      iterations: iterations,
      bits: 160 // NOTE: RFC says 20 octets => 20 octets * 8 bits/octet
    );

    final saltedPasswordRaw = await pbkdf2.deriveKey(
      secretKey: SecretKey(
        utf8.encode(Saslprep.saslprep(attributes.getConnectionSettings().password))
      ),
      nonce: base64.decode(salt)
    );
    return await saltedPasswordRaw.extractBytes();
  }

  Future<List<int>> calculateClientKey(List<int> saltedPassword) async {
    return (await Hmac(_hash).calculateMac(
        utf8.encode("Client Key"), secretKey: SecretKey(saltedPassword)
    )).bytes;
  }

  Future<List<int>> calculateClientSignature(String authMessage, List<int> storedKey) async {
    return (await Hmac(_hash).calculateMac(
        utf8.encode(authMessage),
        secretKey: SecretKey(storedKey)
    )).bytes;
  }

  Future<List<int>> calculateServerKey(List<int> saltedPassword) async {
    return (await Hmac(_hash).calculateMac(
        utf8.encode("Server Key"),
        secretKey: SecretKey(saltedPassword)
    )).bytes;
  }

  Future<List<int>> calculateServerSignature(String authMessage, List<int> serverKey) async {
    return (await Hmac(_hash).calculateMac(
        utf8.encode(authMessage),
        secretKey: SecretKey(serverKey)
    )).bytes;
  }

  List<int> calculateClientProof(List<int> clientKey, List<int> clientSignature) {
    final clientProof = List<int>.filled(clientKey.length, 0);
    for (int i = 0; i < clientKey.length; i++) {
      clientProof[i] = clientKey[i] ^ clientSignature[i];
    }

    return clientProof;
  }
  
  Future<String> calculateChallengeResponse(String base64Challenge) async {
    final challengeString = utf8.decode(base64.decode(base64Challenge));
    final challenge = parseKeyValue(challengeString);
    final clientFinalMessageBare = "c=biws,r=" + challenge["r"]!;
    
    final saltedPassword = await calculateSaltedPassword(challenge["s"]!, int.parse(challenge["i"]!));
    final clientKey = await calculateClientKey(saltedPassword);
    final storedKey = (await _hash.hash(clientKey)).bytes;
    final authMessage = initialMessageNoGS2 + "," + challengeString + "," + clientFinalMessageBare;
    final clientSignature = await calculateClientSignature(authMessage, storedKey);
    final clientProof = calculateClientProof(clientKey, clientSignature);
    final serverKey = await calculateServerKey(saltedPassword);
    _serverSignature = base64.encode(await calculateServerSignature(authMessage, serverKey));

    return clientFinalMessageBare + ",p=" + base64.encode(clientProof);
  }

  @override
  Future<void> negotiate(XMLNode nonza) async {
    switch (_scramState) {
      case ScramState.preSent:
        if (clientNonce == null || clientNonce == "") {
          clientNonce = randomAlphaNumeric(40, provider: CoreRandomProvider.from(Random.secure()));
        }
        
        initialMessageNoGS2 = "n=" + attributes.getConnectionSettings().jid.local + ",r=$clientNonce";

        _scramState = ScramState.initialMessageSent;
        attributes.sendNonza(
          // TODO: Redact
          SaslScramAuthNonza(body: base64.encode(utf8.encode(gs2Header + initialMessageNoGS2)), type: hashType),
        );
        break;
      case ScramState.initialMessageSent:
        if (nonza.tag == "failure") {
          state = NegotiatorState.error;
          _scramState = ScramState.error;
          return;
        }

        final challengeBase64 = nonza.innerText();
        final response = await calculateChallengeResponse(challengeBase64);
        final responseBase64 = base64.encode(utf8.encode(response));
        _scramState = ScramState.challengeResponseSent;
        attributes.sendNonza(
          // TODO: Redact
          SaslScramResponseNonza(body: responseBase64),
        );
        break;
      case ScramState.challengeResponseSent:
        final tag = nonza.tag;

        if (tag == "success") {
          // NOTE: This assumes that the string is always "v=..." and contains no other parameters
          final signature = parseKeyValue(utf8.decode(base64.decode(nonza.innerText())));
          if (signature["v"]! != _serverSignature) {
            _scramState = ScramState.error;
            state = NegotiatorState.error;
            return;
          }

          state = NegotiatorState.done;
          return;
        }
        
        _scramState = ScramState.error;
        state = NegotiatorState.error;
        return;
      case ScramState.error:
        state = NegotiatorState.error;
        return;
    }
  }

  @override
  void reset() {
    _scramState = ScramState.preSent;

    super.reset();
  }
}
