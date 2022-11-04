import 'dart:async';

import 'package:moxxyv2/xmpp/connection.dart';
import 'package:moxxyv2/xmpp/events.dart';
import 'package:moxxyv2/xmpp/jid.dart';
import 'package:moxxyv2/xmpp/managers/attributes.dart';
import 'package:moxxyv2/xmpp/managers/data.dart';
import 'package:moxxyv2/xmpp/negotiators/resource_binding.dart';
import 'package:moxxyv2/xmpp/negotiators/sasl/plain.dart';
import 'package:moxxyv2/xmpp/negotiators/sasl/scram.dart';
import 'package:moxxyv2/xmpp/ping.dart';
import 'package:moxxyv2/xmpp/presence.dart';
import 'package:moxxyv2/xmpp/reconnect.dart';
import 'package:moxxyv2/xmpp/roster.dart';
import 'package:moxxyv2/xmpp/settings.dart';
import 'package:moxxyv2/xmpp/stanza.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0030/xep_0030.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0198/negotiator.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0198/xep_0198.dart';
import 'package:test/test.dart';

import 'helpers/logging.dart';
import 'helpers/xmpp.dart';

/// Returns true if the roster manager triggeres an event for a given stanza
Future<bool> testRosterManager(String bareJid, String resource, String stanzaString) async {
  var eventTriggered = false;
  final roster = RosterManager();
  roster.register(XmppManagerAttributes(
      sendStanza: (_, { StanzaFromType addFrom = StanzaFromType.full, bool addId = true, bool retransmitted = false, bool awaitable = true, bool encrypted = false }) async => XMLNode(tag: 'hallo'),
      sendEvent: (event) {
        eventTriggered = true;
      },
      sendNonza: (_) {},
      getConnectionSettings: () => ConnectionSettings(
        jid: JID.fromString(bareJid),
        password: 'password',
        useDirectTLS: true,
        allowPlainAuth: false,
      ),
      getManagerById: getManagerNullStub,
      getNegotiatorById: getNegotiatorNullStub,
      isFeatureSupported: (_) => false,
      getFullJID: () => JID.fromString('$bareJid/$resource'),
      getSocket: () => StubTCPSocket(play: []),
      getConnection: () => XmppConnection(TestingReconnectionPolicy()),
  ),);

  final stanza = Stanza.fromXMLNode(XMLNode.fromString(stanzaString));
  for (final handler in roster.getIncomingStanzaHandlers()) {
    if (handler.matches(stanza)) await handler.callback(stanza, StanzaHandlerData(false, false, null, stanza));
  }

  return eventTriggered;
}

void main() {
  initLogger();

  test('Test a successful login attempt with no SM', () async {
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
          /*
          Expectation(
            XMLNode.xmlns(
              tag: 'presence',
              xmlns: 'jabber:client',
              attributes: { 'from': 'polynomdivision@test.server/MU29eEZn' },
              children: [
                XMLNode(
                  tag: 'show',
                  text: 'chat',
                ),
                XMLNode.xmlns(
                  tag: 'c',
                  xmlns: 'http://jabber.org/protocol/caps',
                  attributes: {
                    // TODO: Somehow make the test ignore this attribute
                    'ver': 'QRTBC5cg/oYd+UOTYazSQR4zb/I=',
                    'node': 'http://moxxy.im',
                    'hash': 'sha-1'
                  },
                )
              ],
            ),
            XMLNode(
              tag: 'presence',
            ),
          ),
          */
        ],
      );
      // TODO: This test is broken since we query the server and enable carbons
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
        StreamManagementManager(),
      ]);
      conn.registerFeatureNegotiators(
        [
          SaslPlainNegotiator(),
          SaslScramNegotiator(10, '', '', ScramHashType.sha512),
          ResourceBindingNegotiator(),
          StreamManagementNegotiator(),
        ]
      );

      await conn.connect();
      await Future.delayed(const Duration(seconds: 3), () {
          expect(fakeSocket.getState(), /*6*/ 5);
      });
  });

  test('Test a failed SASL auth', () async {
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
            '<failure xmlns="urn:ietf:params:xml:ns:xmpp-sasl"><not-authorized /></failure>'
          ),
        ],
      );
      var receivedEvent = false;
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
      conn.registerFeatureNegotiators([
        SaslPlainNegotiator()
      ]);

      conn.asBroadcastStream().listen((event) {
        if (event is AuthenticationFailedEvent && event.saslError == 'not-authorized') {
          receivedEvent = true;
        }
      });

      await conn.connect();
      await Future.delayed(const Duration(seconds: 3), () {
          expect(receivedEvent, true);
      });
  });

  test('Test another failed SASL auth', () async {
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
            '<failure xmlns="urn:ietf:params:xml:ns:xmpp-sasl"><mechanism-too-weak /></failure>',
          ),
        ],
      );
      var receivedEvent = false;
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
      conn.registerFeatureNegotiators([
        SaslPlainNegotiator()
      ]);

      conn.asBroadcastStream().listen((event) {
          if (event is AuthenticationFailedEvent && event.saslError == 'mechanism-too-weak') {
            receivedEvent = true;
          }
      });

      await conn.connect();
      await Future.delayed(const Duration(seconds: 3), () {
          expect(receivedEvent, true);
      });
  });

  /*test('Test choosing SCRAM-SHA-1', () async {
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
      <mechanism>SCRAM-SHA-1</mechanism>
    </mechanisms>
  </stream:features>''',
          ),
          // TODO(Unknown): This test is currently broken
          StringExpectation(
            "<auth xmlns='urn:ietf:params:xml:ns:xmpp-sasl' mechanism='SCRAM-SHA-1'>AHBvbHlub21kaXZpc2lvbgBhYWFh</auth>",
            "..."
          )
        ],
      );
      final XmppConnection conn = XmppConnection(TestingReconnectionPolicy(), socket: fakeSocket);
      conn.setConnectionSettings(ConnectionSettings(
        jid: JID.fromString('polynomdivision@test.server'),
        password: 'aaaa',
        useDirectTLS: true,
        allowPlainAuth: false,
      ),);
      conn.registerManagers([
        PresenceManager(),
        RosterManager(),
        DiscoManager(),
        PingManager(),
      ]);
      conn.registerFeatureNegotiators([
        SaslPlainNegotiator(),
        SaslScramNegotiator(10, '', '', ScramHashType.sha1),
      ]);

      await conn.connect();
      await Future.delayed(const Duration(seconds: 3), () {
          expect(fakeSocket.getState(), 2);
      });
  });*/

  group('Test roster pushes', () {
      test('Test for a CVE-2015-8688 style vulnerability', () async {
          var eventTriggered = false;
          final roster = RosterManager();
          roster.register(XmppManagerAttributes(
              sendStanza: (_, { StanzaFromType addFrom = StanzaFromType.full, bool addId = true, bool retransmitted = false, bool awaitable = true, bool encrypted = false }) async => XMLNode(tag: 'hallo'),
              sendEvent: (event) {
                eventTriggered = true;
              },
              sendNonza: (_) {},
              getConnectionSettings: () => ConnectionSettings(
                jid: JID.fromString('some.user@example.server'),
                password: 'password',
                useDirectTLS: true,
                allowPlainAuth: false,
              ),
              getManagerById: getManagerNullStub,
              getNegotiatorById: getNegotiatorNullStub,
              isFeatureSupported: (_) => false,
              getFullJID: () => JID.fromString('some.user@example.server/aaaaa'),
              getSocket: () => StubTCPSocket(play: []),
              getConnection: () => XmppConnection(TestingReconnectionPolicy()),
          ),);

          // NOTE: Based on https://gultsch.de/gajim_roster_push_and_message_interception.html
          // NOTE: Added a from attribute as a server would add it itself.
          final maliciousStanza = Stanza.fromXMLNode(XMLNode.fromString("<iq type=\"set\" from=\"eve@siacs.eu/bbbbb\" to=\"some.user@example.server/aaaaa\"><query xmlns='jabber:iq:roster'><item subscription=\"both\" jid=\"eve@siacs.eu\" name=\"Bob\" /></query></iq>"));

          for (final handler in roster.getIncomingStanzaHandlers()) {
            if (handler.matches(maliciousStanza)) await handler.callback(maliciousStanza, StanzaHandlerData(false, false, null, maliciousStanza));
          }

          expect(eventTriggered, false, reason: 'Was able to inject a malicious roster push');
      });
      test('The manager should accept pushes from our bare jid', () async {
          final result = await testRosterManager('test.user@server.example', 'aaaaa', "<iq from='test.user@server.example' type='result' id='82c2aa1e-cac3-4f62-9e1f-bbe6b057daf3' to='test.user@server.example/aaaaa' xmlns='jabber:client'><query ver='64' xmlns='jabber:iq:roster'><item jid='some.other.user@server.example' subscription='to' /></query></iq>");
          expect(result, true, reason: 'Roster pushes from our bare JID should be accepted');
      });
      test('The manager should accept pushes from a jid that, if the resource is stripped, is our bare jid', () async {
          final result1 = await testRosterManager('test.user@server.example', 'aaaaa', "<iq from='test.user@server.example/aaaaa' type='result' id='82c2aa1e-cac3-4f62-9e1f-bbe6b057daf3' to='test.user@server.example/aaaaa' xmlns='jabber:client'><query ver='64' xmlns='jabber:iq:roster'><item jid='some.other.user@server.example' subscription='to' /></query></iq>");
          expect(result1, true, reason: 'Roster pushes should be accepted if the bare JIDs are the same');

          final result2 = await testRosterManager('test.user@server.example', 'aaaaa', "<iq from='test.user@server.example/bbbbb' type='result' id='82c2aa1e-cac3-4f62-9e1f-bbe6b057daf3' to='test.user@server.example/aaaaa' xmlns='jabber:client'><query ver='64' xmlns='jabber:iq:roster'><item jid='some.other.user@server.example' subscription='to' /></query></iq>");
          expect(result2, true, reason: 'Roster pushes should be accepted if the bare JIDs are the same');
      });
  });
}
