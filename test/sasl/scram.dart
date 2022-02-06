import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/sasl/scram.dart";
import "package:moxxyv2/xmpp/sasl/authenticator.dart";

import "package:test/test.dart";
import "package:hex/hex.dart";

void main() {
  test("Test SASL SCRAM-SHA-1", () async {
      final negotiator = SaslScramNegotiator(
        settings: ConnectionSettings(jid: BareJID.fromString("user@server"), password: "pencil", useDirectTLS: true, allowPlainAuth: true),
        clientNonce: "fyko+d2lbbFgONRv9qkxdawL",
        initialMessageNoGS2: "n=user,r=fyko+d2lbbFgONRv9qkxdawL",
        sendRawXML: (data) {},
        hashType: ScramHashType.sha1
      );

      expect(
        HEX.encode(await negotiator.calculateSaltedPassword("QSXCR+Q6sek8bf92", 4096)),
        "1d96ee3a529b5a5f9e47c01f229a2cb8a6e15f7d"
      );
      expect(
        HEX.encode(
          await negotiator.calculateClientKey(HEX.decode("1d96ee3a529b5a5f9e47c01f229a2cb8a6e15f7d"))
        ),
        "e234c47bf6c36696dd6d852b99aaa2ba26555728"
      );
      const authMessage = "n=user,r=fyko+d2lbbFgONRv9qkxdawL,r=fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j,s=QSXCR+Q6sek8bf92,i=4096,c=biws,r=fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j";
      expect(
        HEX.encode(
          await negotiator.calculateClientSignature(authMessage, HEX.decode("e9d94660c39d65c38fbad91c358f14da0eef2bd6"))
        ),
        "5d7138c486b0bfabdf49e3e2da8bd6e5c79db613"
      );
      expect(
        HEX.encode(
          negotiator.calculateClientProof(HEX.decode("e234c47bf6c36696dd6d852b99aaa2ba26555728"), HEX.decode("5d7138c486b0bfabdf49e3e2da8bd6e5c79db613"))
        ),
        "bf45fcbf7073d93d022466c94321745fe1c8e13b"
      );
      expect(
        HEX.encode(
          await negotiator.calculateServerSignature(authMessage, HEX.decode("0fe09258b3ac852ba502cc62ba903eaacdbf7d31"))
        ),
        "ae617da6a57c4bbb2e0286568dae1d251905b0a4"
      );
      expect(
        HEX.encode(
          await negotiator.calculateServerKey(HEX.decode("1d96ee3a529b5a5f9e47c01f229a2cb8a6e15f7d"))
        ),
        "0fe09258b3ac852ba502cc62ba903eaacdbf7d31"
      );
      expect(
        HEX.encode(
          negotiator.calculateClientProof(
            HEX.decode("e234c47bf6c36696dd6d852b99aaa2ba26555728"),
            HEX.decode("5d7138c486b0bfabdf49e3e2da8bd6e5c79db613")
          )
        ),
        "bf45fcbf7073d93d022466c94321745fe1c8e13b"
      );

      expect(await negotiator.calculateChallengeResponse("cj1meWtvK2QybGJiRmdPTlJ2OXFreGRhd0wzcmZjTkhZSlkxWlZ2V1ZzN2oscz1RU1hDUitRNnNlazhiZjkyLGk9NDA5Ng=="), "c=biws,r=fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j,p=v0X8v3Bz2T0CJGbJQyF0X+HI4Ts=");
  });

  test("Test a positive server signature check", () async {
      final negotiator = SaslScramNegotiator(
        settings: ConnectionSettings(jid: BareJID.fromString("user@server"), password: "pencil", useDirectTLS: true, allowPlainAuth: true),
        clientNonce: "fyko+d2lbbFgONRv9qkxdawL",
        initialMessageNoGS2: "n,,n=user,r=fyko+d2lbbFgONRv9qkxdawL",
        sendRawXML: (data) {},
        hashType: ScramHashType.sha1
      );

      await negotiator.next(null);
      await negotiator.next(XMLNode.fromString("<challenge xmlns='urn:ietf:params:xml:ns:xmpp-sasl'>cj1meWtvK2QybGJiRmdPTlJ2OXFreGRhd0wzcmZjTkhZSlkxWlZ2V1ZzN2oscz1RU1hDUitRNnNlazhiZjkyLGk9NDA5Ng==</challenge>"));
      final result = await negotiator.next(XMLNode.fromString("<success xmlns='urn:ietf:params:xml:ns:xmpp-sasl'>dj1ybUY5cHFWOFM3c3VBb1pXamE0ZEpSa0ZzS1E9</success>"));

      expect(result.getState(), AuthenticationResult.success, reason: result.getValue());
  });
  test("Test a negative server signature check", () async {
      final negotiator = SaslScramNegotiator(
        settings: ConnectionSettings(jid: BareJID.fromString("user@server"), password: "pencil", useDirectTLS: true, allowPlainAuth: true),
        clientNonce: "fyko+d2lbbFgONRv9qkxdawL",
        initialMessageNoGS2: "n,,n=user,r=fyko+d2lbbFgONRv9qkxdawL",
        sendRawXML: (data) {},
        hashType: ScramHashType.sha1
      );

      await negotiator.next(null);
      await negotiator.next(XMLNode.fromString("<challenge xmlns='urn:ietf:params:xml:ns:xmpp-sasl'>cj1meWtvK2QybGJiRmdPTlJ2OXFreGRhd0wzcmZjTkhZSlkxWlZ2V1ZzN2oscz1RU1hDUitRNnNlazhiZjkyLGk9NDA5Ng==</challenge>"));
      final result = await negotiator.next(XMLNode.fromString("<success xmlns='urn:ietf:params:xml:ns:xmpp-sasl'>dj1zbUY5cHFWOFM3c3VBb1pXamE0ZEpSa0ZzS1E9</success>"));

      expect(result.getState(), AuthenticationResult.failure, reason: result.getValue());
  });
}
