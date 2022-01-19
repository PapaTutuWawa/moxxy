import "dart:async";

import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/nonzas/stream.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/sasl/scram.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/xeps/0368.dart";

import "helpers/xml.dart";
import "helpers/xmpp.dart";

import "package:test/test.dart";
import "package:xml/xml.dart";
import "package:hex/hex.dart";

void main() {
  test("Test SASL PLAIN", () async {
      final fakeSocket = StubTCPSocket(
        play: [
          Expectation(
            XMLNode(
              tag: "stream:stream",
              attributes: {
                "xmlns": "jabber:client",
                "version": "1.0",
                "xmlns:stream": "http://etherx.jabber.org/streams",
                "to": "test.server",
                "xml:lang": "en"
              },
              closeTag: false
            ),
            XMLNode(
              tag: "stream:stream",
              attributes: {
                "xmlns": "jabber:client",
                "version": "1.0",
                "xmlns:stream": "http://etherx.jabber.org/streams",
                "from": "test.server",
                "xml:lang": "en"
              },
              closeTag: false,
              children: [
                XMLNode.xmlns(
                  tag: "stream:features",
                  xmlns: "http://etherx.jabber.org/streams",
                  children: [
                    XMLNode.xmlns(
                      tag: "mechanisms",
                      xmlns: "urn:ietf:params:xml:ns:xmpp-sasl",
                      children: [
                        XMLNode(tag: "mechanism", text: "PLAIN")
                      ]
                    )
                  ]
                )
              ]
            )
          ),
          Expectation(
            XMLNode.xmlns(
              tag: "auth",
              xmlns: "urn:ietf:params:xml:ns:xmpp-sasl",
              attributes: {
                "mechanism": "PLAIN"
              },
              text: "AHBvbHlub21kaXZpc2lvbgBhYWFh"
            ),
            XMLNode.xmlns(
              tag: "success",
              xmlns: "urn:ietf:params:xml:ns:xmpp-sasl"
            )
          ),
          Expectation(
            XMLNode(
              tag: "stream:stream",
              attributes: {
                "xmlns": "jabber:client",
                "version": "1.0",
                "xmlns:stream": "http://etherx.jabber.org/streams",
                "to": "test.server",
                "xml:lang": "en"
              },
              closeTag: false
            ),
            XMLNode(
              tag: "stream:stream",
              attributes: {
                "xmlns": "jabber:client",
                "version": "1.0",
                "xmlns:stream": "http://etherx.jabber.org/streams",
                "from": "test.server",
                "xml:lang": "en"
              },
              closeTag: false,
              children: [
                XMLNode.xmlns(
                  tag: "stream:features",
                  xmlns: "http://etherx.jabber.org/streams",
                  children: [
                    XMLNode.xmlns(
                      tag: "bind",
                      xmlns: "urn:ietf:params:xml:ns:xmpp-bind",
                      children: [
                        XMLNode(tag: "required")
                      ]
                    ),
                    XMLNode.xmlns(
                      tag: "session",
                      xmlns: "urn:ietf:params:xml:ns:xmpp-session",
                      children: [
                        XMLNode(tag: "optional")
                      ]
                    ),
                    XMLNode.xmlns(
                      tag: "csi",
                      xmlns: "urn:xmpp:csi:0",
                    )
                  ]
                )
              ]
            ),            
          ),
          Expectation(
            XMLNode.xmlns(
              tag: "iq",
              xmlns: "jabber:client",
              attributes: { "type": "set", "id": "a" },
              children: [
                XMLNode.xmlns(
                  tag: "bind",
                  xmlns: "urn:ietf:params:xml:ns:xmpp-bind"
                )
              ]
            ),
            XMLNode.xmlns(
              tag: "iq",
              xmlns: "jabber:client",
              attributes: { "type": "result" },
              children: [
                XMLNode.xmlns(
                  tag: "bind",
                  xmlns: "urn:ietf:params:xml:ns:xmpp-bind",
                  children: [
                    XMLNode(
                      tag: "jid",
                      text: "polynomdivision@test.server/MU29eEZn"
                    )
                  ]
                )
              ]
            )
          ),
          Expectation(
            XMLNode.xmlns(
              tag: "presence",
              xmlns: "jabber:client",
              attributes: { "from": "polynomdivision@test.server/MU29eEZn" },
              children: [
                XMLNode(
                  tag: "show",
                  text: "show"
                )
              ]
            ),
            XMLNode(
              tag: "presence",
            )
          ),
        ]
      );
      final XmppConnection conn = XmppConnection(socket: fakeSocket);
      conn.setConnectionSettings(ConnectionSettings(
          jid: BareJID.fromString("polynomdivision@test.server"),
          password: "aaaa",
          useDirectTLS: true,
          allowPlainAuth: true,
          streamResumptionSettings: StreamResumptionSettings()
      ));
      await conn.connect();
      await Future.delayed(Duration(seconds: 3), () {
          expect(fakeSocket.getState(), 4);
      });
  });

  test("Test XMPP Scram-Sha-1", () async {

      final challenge = ServerChallenge.fromBase64("cj02ZDQ0MmI1ZDllNTFhNzQwZjM2OWUzZGNlY2YzMTc4ZWMxMmIzOTg1YmJkNGE4ZTZmODE0YjQyMmFiNzY2NTczLHM9UVNYQ1IrUTZzZWs4YmY5MixpPTQwOTY=");
      expect(challenge.nonce, "6d442b5d9e51a740f369e3dcecf3178ec12b3985bbd4a8e6f814b422ab766573");
      expect(challenge.salt, "QSXCR+Q6sek8bf92");
      expect(challenge.iterations, 4096);

      final negotiator = SaslScramNegotiator(
        settings: ConnectionSettings(jid: BareJID.fromString("user@server"), password: "pencil", useDirectTLS: true, allowPlainAuth: true, streamResumptionSettings: StreamResumptionSettings()),
        clientNonce: "fyko+d2lbbFgONRv9qkxdawL",
        initialMessageNoGS2: "n=user,r=fyko+d2lbbFgONRv9qkxdawL",
        sendRawXML: (data) {},
        hashType: ScramHashType.SHA1
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
      final String authMessage = "n=user,r=fyko+d2lbbFgONRv9qkxdawL,r=fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j,s=QSXCR+Q6sek8bf92,i=4096,c=biws,r=fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j";
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

  test("Test bare JIDs", () {
      expect(BareJID.fromString("hallo@welt").toString(), "hallo@welt");
      expect(BareJID.fromString("@welt").toString(), "@welt");
      expect(BareJID.fromString("hallo@").toString(), "hallo@");
      expect(BareJID.fromString("hallo@welt/whatever").toString(), "hallo@welt");
  });
}
