import "dart:collection";
import "dart:async";

import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/socket.dart";

import "xml.dart";

import "package:test/test.dart";

class Expectation {
  final XMLNode expectation;
  final XMLNode response;
  final bool ignoreId;

  Expectation(this.expectation, this.response, { this.ignoreId = true });
}

class StubTCPSocket extends BaseSocketWrapper {
  int _state = 0;
  final StreamController<String> _dataStream;
  final StreamController<Object> _errorStream;
  final List<Expectation> _play; // Request -> Response(s)

  StubTCPSocket({ required List<Expectation> play })
  : _play = play,
  _dataStream = StreamController<String>.broadcast(),
  _errorStream = StreamController<Object>.broadcast();

  @override
  Future<void> connect(String host, int port) async {}

  @override
  Stream<String> getDataStream() => this._dataStream.stream.asBroadcastStream();
  @override
  Stream<Object> getErrorStream() => this._errorStream.stream.asBroadcastStream();

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

    this._dataStream.add(expectation.response.toXml());
  }

  @override
  void close() {}
  
  int getState() => this._state;
  void resetState() => this._state = 0;
}
