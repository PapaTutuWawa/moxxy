import "package:test/test.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/reconnect.dart";
import "package:moxxyv2/xmpp/presence.dart";
import "package:moxxyv2/xmpp/ping.dart";
import "package:moxxyv2/xmpp/roster.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/negotiators/negotiator.dart";
import "package:moxxyv2/xmpp/xeps/xep_0030/xep_0030.dart";

import "helpers/logging.dart";
import "helpers/xmpp.dart";

const exampleXmlns1 = "im:moxxy:example1";
const exampleNamespace1 = "im.moxxy.test.example1";
const exampleXmlns2 = "im:moxxy:example2";
const exampleNamespace2 = "im.moxxy.test.example2";

class StubNegotiator1 extends XmppFeatureNegotiatorBase {
  StubNegotiator1() : called = false, super(1, false, exampleXmlns1, exampleNamespace1);

  bool called;
  
  @override
  Future<void> negotiate(XMLNode nonza) async {
    called = true;
    state = NegotiatorState.done;
  }
}

class StubNegotiator2 extends XmppFeatureNegotiatorBase {
  StubNegotiator2() : called = false, super(10, false, exampleXmlns2, exampleNamespace2);

  bool called;
  
  @override
  Future<void> negotiate(XMLNode nonza) async {
    called = true;
    state = NegotiatorState.done;
  }
}

void main() {
  initLogger();

  final stubSocket = StubTCPSocket(
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
                  tag: "example1",
                  xmlns: exampleXmlns1,
                ),
                XMLNode.xmlns(
                  tag: "example2",
                  xmlns: exampleXmlns2,
                )
              ]
            )
          ]
        )
      ),
    ]
  );
  
  final connection = XmppConnection(TestingReconnectionPolicy(), socket: stubSocket)
    ..registerFeatureNegotiators([
      StubNegotiator1(),
      StubNegotiator2(),
    ])
    ..registerManagers([
      PresenceManager(),
      RosterManager(),
      DiscoManager(),
      PingManager(),
    ])
    ..setConnectionSettings(
      ConnectionSettings(
        jid: JID.fromString("user@test.server"),
        password: "abc123",
        useDirectTLS: true,
        allowPlainAuth: false,
      )
    );
  final features = [
    XMLNode.xmlns(tag: "example1", xmlns: exampleXmlns1),
    XMLNode.xmlns(tag: "example2", xmlns: exampleXmlns2),
  ];

  test("Test the priority system", () {
    expect(connection.getNextNegotiator(features)?.id, exampleNamespace2);
  });

  test("Test negotiating features with no stream restarts", () async {    
    await connection.connect();
    await Future.delayed(const Duration(seconds: 3), () {
      final negotiator1 = connection.getNegotiatorById(exampleNamespace1) as StubNegotiator1?;
      final negotiator2 = connection.getNegotiatorById(exampleNamespace2) as StubNegotiator2?;
      expect(negotiator1?.called, true);
      expect(negotiator2?.called, true);
    });
  });
}
