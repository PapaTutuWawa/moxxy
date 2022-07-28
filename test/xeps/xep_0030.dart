import 'package:moxxyv2/xmpp/connection.dart';
import 'package:moxxyv2/xmpp/jid.dart';
import 'package:moxxyv2/xmpp/managers/attributes.dart';
import 'package:moxxyv2/xmpp/managers/namespaces.dart';
import 'package:moxxyv2/xmpp/negotiators/resource_binding.dart';
import 'package:moxxyv2/xmpp/negotiators/sasl/plain.dart';
import 'package:moxxyv2/xmpp/negotiators/sasl/scram.dart';
import 'package:moxxyv2/xmpp/reconnect.dart';
import 'package:moxxyv2/xmpp/settings.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';
import 'package:moxxyv2/xmpp/ping.dart';
import 'package:moxxyv2/xmpp/presence.dart';
import 'package:moxxyv2/xmpp/reconnect.dart';
import 'package:moxxyv2/xmpp/roster.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0030/xep_0030.dart';
import 'package:test/test.dart';

import '../helpers/xmpp.dart';

void main() {
  test('Test having multiple disco requests for the same JID', () async {
    final fakeSocket = StubTCPSocket(
      play: [
        StringExpectation(
          "<stream:stream xmlns='jabber:client' version='1.0' xmlns:stream='http://etherx.jabber.org/streams' to='test.server' xml:lang='en'>",
          '''
<stream:stream
    xmlns="jabber:client"
    version="1.0"
    xmlns:stream="http://etherx.jabber.org/streams"
    from="test.server"
    xml:lang="en">
  <stream:features xmlns="http://etherx.jabber.org/streams">
    <mechanisms xmlns="urn:ietf:params:xml:ns:xmpp-sasl">
      <mechanism>PLAIN</mechanism>
    </mechanisms>
  </stream:features>''',
        ),
        StringExpectation(
          "<auth xmlns='urn:ietf:params:xml:ns:xmpp-sasl' mechanism='PLAIN'>AHBvbHlub21kaXZpc2lvbgBhYWFh</auth>",
          '<success xmlns="urn:ietf:params:xml:ns:xmpp-sasl" />'
        ),
        StringExpectation(
          "<stream:stream xmlns='jabber:client' version='1.0' xmlns:stream='http://etherx.jabber.org/streams' to='test.server' xml:lang='en'>",
          '''
<stream:stream
    xmlns="jabber:client"
    version="1.0"
    xmlns:stream="http://etherx.jabber.org/streams"
    from="test.server"
    xml:lang="en">
  <stream:features xmlns="http://etherx.jabber.org/streams">
    <bind xmlns="urn:ietf:params:xml:ns:xmpp-bind">
      <required/>
    </bind>
    <session xmlns="urn:ietf:params:xml:ns:xmpp-session">
      <optional/>
    </session>
    <csi xmlns="urn:xmpp:csi:0"/>
    <sm xmlns="urn:xmpp:sm:3"/>
  </stream:features>
''',
        ),
        StanzaExpectation(
          '<iq xmlns="jabber:client" type="set" id="a"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"/></iq>',
          '<iq xmlns="jabber:client" type="result" id="a"><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"><jid>polynomdivision@test.server/MU29eEZn</jid></bind></iq>',
          ignoreId: true,
        ),
        StringExpectation(
          "<presence xmlns='jabber:client' from='polynomdivision@test.server/MU29eEZn'><show>chat</show><c xmlns='http://jabber.org/protocol/caps' hash='sha-1' node='http://moxxy.im' ver='QRTBC5cg/oYd+UOTYazSQR4zb/I=' /></presence>",
          '',
        ),
        StanzaExpectation(
          "<iq type='get' id='ec325efc-9924-4c48-93f8-ed34a2b0e5fc' to='romeo@montague.lit/orchard' from='polynomdivision@test.server/MU29eEZn' xmlns='jabber:client'><query xmlns='http://jabber.org/protocol/disco#info' /></iq>",
          '',
          ignoreId: true,
          adjustId: false,
        ),

      ],
    );
    final XmppConnection conn = XmppConnection(TestingReconnectionPolicy(), socket: fakeSocket);
    conn.setConnectionSettings(ConnectionSettings(
        jid: JID.fromString('polynomdivision@test.server'),
        password: 'aaaa',
        useDirectTLS: true,
        allowPlainAuth: true,
    ),);
    conn.registerManagers([
      PresenceManager(),
      RosterManager(),
      DiscoManager(),
      PingManager(),
    ]);
    conn.registerFeatureNegotiators(
      [
        SaslPlainNegotiator(),
        SaslScramNegotiator(10, '', '', ScramHashType.sha512),
        ResourceBindingNegotiator(),
      ]
    );

    final disco = conn.getManagerById<DiscoManager>(discoManager)!;
      
    await conn.connect();
    await Future.delayed(const Duration(seconds: 3));

    final jid = JID.fromString('romeo@montague.lit/orchard');
    final result1 = disco.discoInfoQuery(jid.toString());
    final result2 = disco.discoInfoQuery(jid.toString());

    await Future.delayed(const Duration(seconds: 1));
    expect(
      disco.getRunningInfoQueries(DiscoCacheKey(jid.toString(), null)).length,
      1,
    );
    fakeSocket.injectRawXml("<iq type='result' id='${fakeSocket.lastId!}' from='romeo@montague.lit/orchard' to='polynomdivision@test.server/MU29eEZn' xmlns='jabber:client'><query xmlns='http://jabber.org/protocol/disco#info' /></iq>");
    
    await Future.delayed(const Duration(seconds: 2));
    
    expect(fakeSocket.getState(), 6);
    expect(await result1, await result2);
    expect(disco.hasInfoQueriesRunning(), false);
  });
}
