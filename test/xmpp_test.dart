import "dart:async";

import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/nonzas/stream.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/sasl/scramsha1.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/xeps/0368.dart";

import "package:xml/xml.dart";
import "package:test/test.dart";
import "package:hex/hex.dart";

class FakeSocket implements SocketWrapper {
  int state;
  final StreamController<String> _streamController = StreamController<String>();
  final String server;

  FakeSocket({ required this.server }) : state = 0;
  
  @override
  Future<void> connect(String host, int port) async {}

  @override
  Stream<String> asBroadcastStream() {
    return this._streamController.stream.asBroadcastStream();
  }
  
  @override
  void write(Object? object) {
    final str = object as String;

    print("==> " + str);
    
    switch (this.state) {
      case 0: {
        this.state++;
        expect(str, "<?xml version='1.0'?><stream:stream xmlns='jabber:client' version='1.0' xmlns:stream='http://etherx.jabber.org/streams' to='${this.server}' xml:lang='en'>");

        this._streamController.add("""
<stream:stream
  xmlns:stream='http://etherx.jabber.org/streams'
  xmlns='jabber:client'
  from='${this.server}'
  xml:lang='en' version='1.0' id='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'>
   <stream:features xmlns='http://etherx.jabber.org/streams'>
      <mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'>
         <mechanism>PLAIN</mechanism>
      </mechanisms>
   </stream:features>
""");
      }
      break;
      case 1: {
        this.state++;
        expect(str, "<auth xmlns='urn:ietf:params:xml:ns:xmpp-sasl' mechanism='PLAIN'>AHBvbHlub21kaXZpc2lvbgBhYWFh</auth>");

        this._streamController.add("<success xmlns='$SASL_XMLNS' />");
      }
      break;
      case 2: {
        this.state++;
        expect(str, "<?xml version='1.0'?><stream:stream xmlns='jabber:client' version='1.0' xmlns:stream='http://etherx.jabber.org/streams' to='${this.server}' xml:lang='en'>");

        this._streamController.add("<stream:stream xmlns:stream='http://etherx.jabber.org/streams' from='${this.server}' xmlns='jabber:client' version='1.0' id='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' xml:lang='en'><stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'><required/></bind><session xmlns='urn:ietf:params:xml:ns:xmpp-session'><optional/></session><ver xmlns='urn:xmpp:features:rosterver'/><c hash='sha-1' ver='e6y9LzWVyTcm31DV0THfhNwlHZo=' node='http://prosody.im' xmlns='http://jabber.org/protocol/caps'/><sm xmlns='urn:xmpp:sm:2'><optional/></sm><sm xmlns='urn:xmpp:sm:3'><optional/></sm><csi xmlns='urn:xmpp:csi:0'/></stream:features>");
      }
      break;
      case 3: {
        this.state++;
        expect(str, "<iq xmlns='jabber:client' id='aaaaaaaaaa' type='set'><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></iq>");

        this._streamController.add("<iq type='result' id='aaaaaaaaaa'><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'><jid>polynomdivision@test.server/MU29eEZn</jid></bind></iq>");
      }
      break;
      case 4: {
        this.state++;
        expect(str, "<presence xmlns='jabber:client' from='polynomdivision@test.server/MU29eEZn'><show >show</show></presence>");

        this._streamController.add("<presence /><message />");
      }
      break;
    }
  }
}

void main() {
  test("Test SASL PLAIN", () async {
    final fakeSocket = FakeSocket(server: "test.server");
    final XmppConnection conn = XmppConnection(socket: fakeSocket, settings: ConnectionSettings(
        jid: BareJID.fromString("polynomdivision@test.server"),
        password: "aaaa",
        useDirectTLS: true
    ));
    await conn.connect();
    await Future.delayed(Duration(seconds: 3), () {
        expect(fakeSocket.state, 5);
    });
  });

  test("Test stringxml", () {
      final child = XMLNode(tag: "uwu", attributes: { "strength": 10 });
      final stanza = XMLNode.xmlns(tag: "uwu-meter", xmlns: "uwu", children: [ child ]);
      expect(XMLNode(tag: "iq", attributes: {"xmlns": "uwu"}).toXml(), "<iq xmlns='uwu' />");
      expect(XMLNode.xmlns(tag: "iq", xmlns: "uwu", attributes: {"how": "uwu"}).toXml(), "<iq xmlns='uwu' how='uwu' />");
      expect(stanza.toXml(), "<uwu-meter xmlns='uwu'><uwu strength=10 /></uwu-meter>");

      expect(StreamHeaderNonza("uwu.server").toXml(), "<stream:stream xmlns='jabber:client' version='1.0' xmlns:stream='http://etherx.jabber.org/streams' to='uwu.server' xml:lang='en'>");
  });

  // "
  test("Test XMPP Scram-Sha-1", () async {

      final challenge = ServerChallenge.fromBase64("cj02ZDQ0MmI1ZDllNTFhNzQwZjM2OWUzZGNlY2YzMTc4ZWMxMmIzOTg1YmJkNGE4ZTZmODE0YjQyMmFiNzY2NTczLHM9UVNYQ1IrUTZzZWs4YmY5MixpPTQwOTY=");
      expect(challenge.nonce, "6d442b5d9e51a740f369e3dcecf3178ec12b3985bbd4a8e6f814b422ab766573");
      expect(challenge.salt, "QSXCR+Q6sek8bf92");
      expect(challenge.iterations, 4096);

      final negotiator = SaslScramSha1Negotiator(
        settings: ConnectionSettings(jid: BareJID.fromString("user@server"), password: "pencil", useDirectTLS: true),
        clientNonce: "fyko+d2lbbFgONRv9qkxdawL",
        initialMessageNoGS2: "n=user,r=fyko+d2lbbFgONRv9qkxdawL",
        send: (data) {},
        sendStreamHeader: () {}
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
