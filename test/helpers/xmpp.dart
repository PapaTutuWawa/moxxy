import 'dart:async';

import 'package:moxxyv2/xmpp/managers/base.dart';
import 'package:moxxyv2/xmpp/negotiators/negotiator.dart';
import 'package:moxxyv2/xmpp/socket.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';
import 'package:test/test.dart';

import 'xml.dart';

T? getNegotiatorNullStub<T extends XmppFeatureNegotiatorBase>(String id) {
  return null;
}

T? getManagerNullStub<T extends XmppManagerBase>(String id) {
  return null;
}

abstract class ExpectationBase {

  ExpectationBase(this.expectation, this.response);
  final String expectation;
  final String response;

  /// Return true if [input] matches the expectation
  bool matches(String input);
}

/// Literally compare the input with the expectation
class StringExpectation extends ExpectationBase {
  StringExpectation(String expectation, String response) : super(expectation, response);

  @override
  bool matches(String input) => input == expectation;
}

/// 
class StanzaExpectation extends ExpectationBase {
  StanzaExpectation(String expectation, String response, {this.ignoreId = false, this.adjustId = false }) : super(expectation, response);
  final bool ignoreId;
  final bool adjustId;
  
  @override
  bool matches(String input) {
    final ex = XMLNode.fromString(expectation);
    final recv = XMLNode.fromString(expectation);

    return compareXMLNodes(recv, ex, ignoreId: ignoreId);
  }
}

class StubTCPSocket extends BaseSocketWrapper { // Request -> Response(s)

  StubTCPSocket({ required List<ExpectationBase> play })
    : _play = play,
      _dataStream = StreamController<String>.broadcast(),
      _eventStream = StreamController<XmppSocketEvent>.broadcast();
  int _state = 0;
  final StreamController<String> _dataStream;
  final StreamController<XmppSocketEvent> _eventStream;
  final List<ExpectationBase> _play;
  String? lastId;

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

  /// Let the "connection" receive [data].
  void injectRawXml(String data) {
    print('<== $data');
    _dataStream.add(data);
  }
  
  @override
  void write(Object? object, { String? redact }) {
    var str = object as String;
    // ignore: avoid_print
    print('==> $str');

    if (_state >= _play.length) {
      _state++;
      return;
    }

    final expectation = _play[_state];

    // TODO: Implement an XML matcher
    if (str.startsWith("<?xml version='1.0'?>")) {
      str = str.substring(21);
    }

    if (str.endsWith('</stream:stream>')) {
      str = str.substring(0, str.length - 16);
    }

    if (!expectation.matches(str)) {
      expect(true, false, reason: 'Expected ${expectation.expectation}, got $str');
    }

    // Make sure to only progress if everything passed so far
    _state++;

    var response = expectation.response;
    if (expectation is StanzaExpectation) {
      final inputNode = XMLNode.fromString(str);
      lastId = inputNode.attributes['id'];

      if (expectation.adjustId) {
        final outputNode = XMLNode.fromString(response);

        outputNode.attributes['id'] = inputNode.attributes['id']!;
        response = outputNode.toXml();
      }
    }
    
    print("<== $response");
    _dataStream.add(response);
  }

  @override
  void close() {}
  
  int getState() => _state;
  void resetState() => _state = 0;

  @override
  bool whitespacePingAllowed() => true;

  @override
  bool managesKeepalives() => false;
}
