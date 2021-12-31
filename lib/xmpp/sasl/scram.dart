import "dart:convert";
import "dart:math" show Random;

import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/sasl/authenticator.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/routing.dart";
import "package:moxxyv2/xmpp/nonzas/stream.dart";
import "package:moxxyv2/xmpp/stringxml.dart";

import "package:cryptography/cryptography.dart";
import "package:random_string/random_string.dart";
import "package:xml/xml.dart";

// NOTE: Inspired by https://github.com/vukoye/xmpp_dart/blob/3b1a0588562b9e591488c99d834088391840911d/lib/src/features/sasl/ScramSaslHandler.dart

enum ScramHashType {
  SHA1,
  SHA256,
  SHA512
}

HashAlgorithm hashFromType(ScramHashType type) {
  switch (type) {
    case ScramHashType.SHA1: return Sha1();
    case ScramHashType.SHA256: return Sha256();
    case ScramHashType.SHA512: return Sha512();
  }
}

const SCRAM_SHA1_MECHANISM = "SCRAM-SHA-1";
const SCRAM_SHA256_MECHANISM = "SCRAM-SHA-256";
const SCRAM_SHA512_MECHANISM = "SCRAM-SHA-512";

String mechanismNameFromType(ScramHashType type) {
  switch (type) {
    case ScramHashType.SHA1: return SCRAM_SHA1_MECHANISM;
    case ScramHashType.SHA256: return SCRAM_SHA256_MECHANISM;
    case ScramHashType.SHA512: return SCRAM_SHA512_MECHANISM;
  }
}

class SaslScramAuthNonza extends XMLNode {
  SaslScramAuthNonza({ required String body, required ScramHashType type }) : super(
    tag: "auth",
    attributes: {
      "xmlns": SASL_XMLNS,
      "mechanism": mechanismNameFromType(type)
    },
    text: body
  );
}

class SaslScramResponseNonza extends XMLNode {
  SaslScramResponseNonza({ required String body }) : super(
    tag: "response",
    attributes: {
      "xmlns": SASL_XMLNS,
    },
    text: body
  );
}


class ServerChallenge {
  late final String nonce;
  late final String salt;
  late final int iterations;
  late final String firstMessage;

  ServerChallenge({ required this.nonce, required this.salt, required this.iterations });
  ServerChallenge.fromBase64(String challenge) {
    final parameters = Map<String, String>();

    this.firstMessage = utf8.decode(base64.decode(challenge));
    this.firstMessage.split(",").forEach((parameter) {
        final parts = parameter.split("=");
        parameters[parts[0]] = parts[1];
    });
    
    this.nonce = parameters["r"]!;
    this.salt = parameters["s"]!;
    this.iterations = int.parse(parameters["i"]!);
  }
}

enum ScramState {
  PRE_SENT,
  INITIAL_MESSAGE_SENT,
  CHALLENGE_RESPONSE_SENT,
  ERROR
}

const GS2_HEADER = "n,,";

class SaslScramNegotiator extends AuthenticationNegotiator {
  final ConnectionSettings settings;
  ScramState state = ScramState.PRE_SENT;
  String? clientNonce;
  String initialMessageNoGS2;
  final ScramHashType hashType;
  final HashAlgorithm _hash;

  void Function(XMLNode) sendRawXML;

  // NOTE: NEVER, and I mean, NEVER set clientNonce or initalMessageNoGS2. They are just there for testing
  SaslScramNegotiator({ required this.settings, this.clientNonce, required this.initialMessageNoGS2, required this.sendRawXML, required ScramHashType this.hashType }) : _hash = hashFromType(hashType);

  Future<List<int>> calculateSaltedPassword(String salt, int iterations) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac(this._hash),
      iterations: iterations,
      bits: 160 // NOTE: RFC says 20 octets => 20 octets * 8 bits/octet
    );

    final saltedPasswordRaw = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(this.settings.password)),
      nonce: base64.decode(salt)
    );
    return await saltedPasswordRaw.extractBytes();
  }

  Future<List<int>> calculateClientKey(List<int> saltedPassword) async {
    return (await Hmac(this._hash).calculateMac(
        utf8.encode("Client Key"), secretKey: SecretKey(saltedPassword)
    )).bytes;
  }

  Future<List<int>> calculateClientSignature(String authMessage, List<int> storedKey) async {
    return (await Hmac(this._hash).calculateMac(
        utf8.encode(authMessage),
        secretKey: SecretKey(storedKey)
    )).bytes;
  }

  Future<List<int>> calculateServerKey(List<int> saltedPassword) async {
    return (await Hmac(this._hash).calculateMac(
        utf8.encode("Server Key"),
        secretKey: SecretKey(saltedPassword)
    )).bytes;
  }

  Future<List<int>> calculateServerSignature(String authMessage, List<int> serverKey) async {
    return (await Hmac(this._hash).calculateMac(
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
        final challenge = ServerChallenge.fromBase64(base64Challenge);
        final clientFinalMessageBare = "c=biws,r=" + challenge.nonce;

        final hmac = Hmac(this._hash);
        
        final saltedPassword = await this.calculateSaltedPassword(challenge.salt, challenge.iterations);
        final clientKey = await this.calculateClientKey(saltedPassword);
        final storedKey = (await this._hash.hash(clientKey)).bytes;
        final authMessage = this.initialMessageNoGS2 + "," + challenge.firstMessage + "," + clientFinalMessageBare;
        final clientSignature = await this.calculateClientSignature(authMessage, storedKey);
        final clientProof = this.calculateClientProof(clientKey, clientSignature);
        final serverKey = await this.calculateServerKey(saltedPassword);
        final serverSignature = await this.calculateServerSignature(authMessage, serverKey);

        return clientFinalMessageBare + ",p=" + base64.encode(clientProof);
  }
  
  Future<AuthenticationResult> next(XMLNode? nonza) async {
    switch (this.state) {
      case ScramState.PRE_SENT: {
        // TODO: saslprep
        if (this.clientNonce == null || this.clientNonce == "") {
          this.clientNonce = randomAlphaNumeric(40, provider: CoreRandomProvider.from(Random.secure()));
        }
        
        this.initialMessageNoGS2 = "n=" + this.settings.jid.local + ",r=${this.clientNonce}";

        this.state = ScramState.INITIAL_MESSAGE_SENT;
        this.sendRawXML(SaslScramAuthNonza(body: base64.encode(utf8.encode(GS2_HEADER + this.initialMessageNoGS2)), type: this.hashType));
        return AuthenticationResult.NOT_DONE;
      }
      break;
      case ScramState.INITIAL_MESSAGE_SENT: {
        final challengeBase64 = nonza!.innerText();
        final response = await this.calculateChallengeResponse(challengeBase64);
        final responseBase64 = base64.encode(utf8.encode(response));
        this.state = ScramState.CHALLENGE_RESPONSE_SENT;
        this.sendRawXML(SaslScramResponseNonza(body: responseBase64));
        return AuthenticationResult.NOT_DONE;
      }
      break;
      case ScramState.CHALLENGE_RESPONSE_SENT: {
        final tag = nonza!.tag;

        if (tag == "success") {
          // TODO: Check the response
          print("SUCCESS!");
          return AuthenticationResult.SUCCESS;
        } else {
          print("FUCK");
        }
      }
      break;
    }

    return AuthenticationResult.FAILURE;
  }
}