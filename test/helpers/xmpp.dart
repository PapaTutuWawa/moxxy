import "dart:collection";
import "dart:async";

import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/connection.dart";

import "xml.dart";

import "package:test/test.dart";

class Expectation {
  final XMLNode expectation;
  final XMLNode response;
  final bool ignoreId;

  Expectation(this.expectation, this.response, { this.ignoreId = true });
}

class StubTCPSocket implements SocketWrapper {
  int _state = 0;
  final StreamController<String> _streamController;
  final List<Expectation> _play; // Request -> Response(s)

  StubTCPSocket({ required List<Expectation> play })
  : _play = play, _streamController = StreamController<String>();

  @override
  Future<void> connect(String host, int port) async {}

  @override
  Stream<String> asBroadcastStream() => this._streamController.stream.asBroadcastStream();

  @override
  void write(Object? object) {
    String str = object as String;
    print("==> " + str);

    final expectation = this._play[this._state];
    this._state++;

    // TODO: Implement an XML matcher
    if (str.startsWith("<?xml version='1.0'?>")) {
      str = str.substring(21);
    }

    if (str.startsWith("<stream:stream")) {
      str = str + "</stream:stream>";
    } else {
      if (str.endsWith("</stream:stream>")) {
        // TODO: Maybe prepend <stream:stream> so that we can detect it within
        //       [XmppConnection]
        str = str.substring(0, str.length - 16);
      }
    }

    final recv = XMLNode.fromString(str);
    expect(
      compareXMLNodes(recv, expectation.expectation, ignoreId: expectation.ignoreId),
      true,
      reason: "Expected: ${expectation.expectation.toXml()}, Got: ${recv.toXml()}"
    );

    this._streamController.add(expectation.response.toXml());
  }

  @override
  void close() {}
  
  int getState() => this._state;
  void resetState() => this._state = 0;
}
