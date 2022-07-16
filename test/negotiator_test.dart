import "package:test/test.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/reconnect.dart";
import "package:moxxyv2/xmpp/presence.dart";
import "package:moxxyv2/xmpp/negotiators/negotiator.dart";

import "helpers/logging.dart";

const exampleXmlns1 = "im:moxxy:example1";
const exampleNamespace1 = "im.moxxy.test.example1";
const exampleXmlns2 = "im:moxxy:example2";
const exampleNamespace2 = "im.moxxy.test.example2";

class StubNegotiator1 extends XmppFeatureNegotiatorBase {
  StubNegotiator1() : called = false, super(1, false, exampleXmlns1, exampleNamespace1);

  bool called;
  
  @override
  Future<void> negotiate(XMLNode nonza) async {
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

  final connection = XmppConnection(TestingReconnectionPolicy())
    ..registerFeatureNegotiators([
      StubNegotiator1(),
      StubNegotiator2(),
    ])
    ..registerManagers([
      PresenceManager(),
    ]);
  final features = [
    XMLNode.xmlns(tag: "example1", xmlns: exampleXmlns1),
    XMLNode.xmlns(tag: "example2", xmlns: exampleXmlns2),
  ];

  test("Test the priority system", () {
    expect(connection.getNextNegotiator(features)?.id, exampleNamespace2);
  });

  test("Test negotiating features with no stream restarts", () async {
    // TODO: Use a simple connection setup to test this
    final streamFeatures = XMLNode(tag: "stream:features", children: features);
    await connection.handleXmlStream(streamFeatures);

    final negotiator1 = connection.getNegotiatorById(exampleNamespace1) as StubNegotiator1?;
    final negotiator2 = connection.getNegotiatorById(exampleNamespace2) as StubNegotiator2?;
    expect(negotiator1?.called, true);
    expect(negotiator2?.called, true);
  });
}
