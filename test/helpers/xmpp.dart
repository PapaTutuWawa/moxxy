import "dart:async";

import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/socket.dart";

import "xml.dart";

import "package:test/test.dart";

// TODO: Turn this into multiple Expectation classes
class Expectation {
  final XMLNode expectation;
  final XMLNode response;
  final bool ignoreId;
  final String? containsTag;
  final Map<String, String>? justCheckAttributes;

  Expectation(this.expectation, this.response, { this.ignoreId = true, this.containsTag, this.justCheckAttributes });
}

class StubTCPSocket extends BaseSocketWrapper {
  int _state = 0;
  final StreamController<String> _dataStream;
  final StreamController<XmppSocketEvent> _eventStream;
  final List<Expectation> _play; // Request -> Response(s)

  StubTCPSocket({ required List<Expectation> play })
  : _play = play,
  _dataStream = StreamController<String>.broadcast(),
  _eventStream = StreamController<XmppSocketEvent>.broadcast();

  @override
  bool isSecure() => true;

  @override
  Future<bool> secure(String domain) async => true;
  
  @override
  Future<bool> connect(String domain, { String? host, int? port }) async => true;

  @override
  Stream<String> getDataStream() => _dataStream.stream.asBroadcastStream();
  @override
  Stream<XmppSocketEvent> getEventStream() => _eventStream.stream.asBroadcastStream();

  @override
  void write(Object? object) {
    String str = object as String;
    // ignore: avoid_print
    print("==> " + str);

    if (_state >= _play.length) {
      return;
    }

    final expectation = _play[_state];

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
    if (expectation.justCheckAttributes != null) {
      expectation.justCheckAttributes!.forEach((key, value) {
          expect(recv.attributes[key] == value, true);
      });
    } else {
      expect(
        compareXMLNodes(recv, expectation.expectation, ignoreId: expectation.ignoreId),
        true,
        reason: "Expected: ${expectation.expectation.toXml()}, Got: ${recv.toXml()}"
      );

      if (expectation.containsTag != null) {
        expect(recv.firstTag(expectation.containsTag!) != null, true, reason: "Tag ${expectation.containsTag!} not found");
      }
    }

    // Make sure to only progress if everything passed so far
    _state++;
    _dataStream.add(expectation.response.toXml());
  }

  @override
  void close() {}
  
  int getState() => _state;
  void resetState() => _state = 0;
}
