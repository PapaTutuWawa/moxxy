import "dart:convert";
import "dart:math" show Random;

import "package:moxxyv2/xmpp/types/result.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/sasl/authenticator.dart";
import "package:moxxyv2/xmpp/sasl/errors.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/namespaces.dart";

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

class SaslScramAuthNonza extends XMLNode {
  SaslScramAuthNonza({ required String body, required ScramHashType type }) : super(
    tag: "auth",
    attributes: {
      "xmlns": saslXmlns,
      "mechanism": mechanismNameFromType(type)
    },
    text: body
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

class ServerChallenge {
  late final String nonce;
  late final String salt;
  late final int iterations;
  late final String firstMessage;

  ServerChallenge({ required this.nonce, required this.salt, required this.iterations });
  ServerChallenge.fromBase64(String challenge) {
    final Map<String, String> parameters = {};

    firstMessage = utf8.decode(base64.decode(challenge));
    for (var parameter in firstMessage.split(",")) {
      final parts = parameter.split("=");
      parameters[parts[0]] = parts[1];
    }
    
    nonce = parameters["r"]!;
    salt = parameters["s"]!;
    iterations = int.parse(parameters["i"]!);
  }
}

enum ScramState {
  preSent,
  initialMessageSent,
  challengeResponseSent,
  error
}

const gs2Header = "n,,";

class SaslScramNegotiator extends AuthenticationNegotiator {
  final ConnectionSettings settings;
  ScramState state = ScramState.preSent;
  String? clientNonce;
  String initialMessageNoGS2;
  final ScramHashType hashType;
  final HashAlgorithm _hash;

  void Function(XMLNode) sendRawXML;

  // NOTE: NEVER, and I mean, NEVER set clientNonce or initalMessageNoGS2. They are just there for testing
  SaslScramNegotiator({ required this.settings, this.clientNonce, required this.initialMessageNoGS2, required this.sendRawXML, required this.hashType }) : _hash = hashFromType(hashType);

  Future<List<int>> calculateSaltedPassword(String salt, int iterations) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac(_hash),
      iterations: iterations,
      bits: 160 // NOTE: RFC says 20 octets => 20 octets * 8 bits/octet
    );

    final saltedPasswordRaw = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(Saslprep.saslprep(settings.password))),
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
        final challenge = ServerChallenge.fromBase64(base64Challenge);
        final clientFinalMessageBare = "c=biws,r=" + challenge.nonce;
        
        final saltedPassword = await calculateSaltedPassword(challenge.salt, challenge.iterations);
        final clientKey = await calculateClientKey(saltedPassword);
        final storedKey = (await _hash.hash(clientKey)).bytes;
        final authMessage = initialMessageNoGS2 + "," + challenge.firstMessage + "," + clientFinalMessageBare;
        final clientSignature = await calculateClientSignature(authMessage, storedKey);
        final clientProof = calculateClientProof(clientKey, clientSignature);
        // TODO: Check
        //final serverKey = await calculateServerKey(saltedPassword);
        //final serverSignature = await calculateServerSignature(authMessage, serverKey);

        return clientFinalMessageBare + ",p=" + base64.encode(clientProof);
  }

  @override
  Future<Result<AuthenticationResult, String>> next(XMLNode? nonza) async {
    switch (state) {
      case ScramState.preSent:
        if (clientNonce == null || clientNonce == "") {
          clientNonce = randomAlphaNumeric(40, provider: CoreRandomProvider.from(Random.secure()));
        }
        
        initialMessageNoGS2 = "n=" + settings.jid.local + ",r=$clientNonce";

        state = ScramState.initialMessageSent;
        sendRawXML(SaslScramAuthNonza(body: base64.encode(utf8.encode(gs2Header + initialMessageNoGS2)), type: hashType));
        return Result(AuthenticationResult.notDone, "");
      case ScramState.initialMessageSent:
        if (nonza!.tag == "failure") {
          return Result(AuthenticationResult.failure, getSaslError(nonza));
        }

        final challengeBase64 = nonza.innerText();
        final response = await calculateChallengeResponse(challengeBase64);
        final responseBase64 = base64.encode(utf8.encode(response));
        state = ScramState.challengeResponseSent;
        sendRawXML(SaslScramResponseNonza(body: responseBase64));
        return Result(AuthenticationResult.notDone, "");
      case ScramState.challengeResponseSent:
        final tag = nonza!.tag;

        if (tag == "success") {
          // TODO: Check the response
          return Result(AuthenticationResult.success, "");
        }
        
        return Result(AuthenticationResult.failure, getSaslError(nonza));
      case ScramState.error:
        return Result(AuthenticationResult.failure, "");   
    }
  }
}
