import "dart:collection";
import "dart:math";

import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/stanzas/stanza.dart";
import "package:moxxyv2/xmpp/nonzas/sm.dart";
import "package:moxxyv2/xmpp/connection.dart";

const XML_UINT_MAX = 4294967296; // 2**32

// TODO: Store them somewhere in case the app get's killed
class StreamManager {
  // NOTE: _{client,server}StanzaSeq is the next sequence number to use
  int _clientStanzaSeq;
  int _serverStanzaSeq;
  Map<int, String> _unackedStanzas;
  XmppConnection connection;
  String streamResumptionId;

  StreamManager({ required this.connection, required this.streamResumptionId }) : _clientStanzaSeq = 0, _serverStanzaSeq = 0, _unackedStanzas = Map();

  bool canResume() => this.streamResumptionId != "";
  
  void handleAckRequest() {
    this.connection.sendEvent(StreamManagementAckSentEvent(h: this._serverStanzaSeq - 1));
    this.connection.sendRawXML(StreamManagementAckNonza(this._serverStanzaSeq - 1));
  }
  
  void serverStanzaReceived() {
    if (this._serverStanzaSeq + 1 == XML_UINT_MAX) {
      this._serverStanzaSeq = 0;
    } else {
      this._serverStanzaSeq++;
    }
  }

  void clientStanzaSent(String stanzaString) {
    this._unackedStanzas[this._clientStanzaSeq] = stanzaString;

    if (this._clientStanzaSeq + 1 == XML_UINT_MAX) {
      this._clientStanzaSeq = 0;
    } else {
      this._clientStanzaSeq++;
    }

    print("Queue after sending: " + this._unackedStanzas.toString());
  }

  void handleAckResponse(int h) {
    this._unackedStanzas.removeWhere(
      (key, _) => key <= h
    );
    print("Queue after cleaning: " + this._unackedStanzas.toString());

    if (this._unackedStanzas.isNotEmpty) {
      this._clientStanzaSeq = h + 1;
      print("QUEUE NOT EMPTY. FLUSHING");
      this._flushStanzaQueue();
    }
  }

  void _flushStanzaQueue() {
    List<String> stanzas = this._unackedStanzas.values.toList();
    this._unackedStanzas.clear();

    stanzas.forEach((stanza) => this.connection.smResend(stanza));
  }
}
