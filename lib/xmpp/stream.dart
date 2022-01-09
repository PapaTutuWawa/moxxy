import "dart:collection";
import "dart:math";

import "package:moxxyv2/xmpp/stanzas/stanza.dart";
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
  Map<int, Stanza> _unackedStanzas;
  bool _streamManagementEnabled;
  XmppConnection connection;

  StreamManager({ required this.connection }) : _clientStanzaSeq = 0, _serverStanzaSeq = 0, _unackedStanzas = Map(), _streamManagementEnabled = false;

  /// Enables support for XEP-0198 stream management
  void enableStreamManagement() {
    this._streamManagementEnabled = true;
  }

  /// Returns whether XEP-0198 stream management is enabled
  bool streamManagementEnabled() => this._streamManagementEnabled;
  
  /// To be called when receiving a <a /> nonza.
  void handleAckRequest() {
    this.connection.sendEvent(StreamManagementAckSentEvent(h: this._serverStanzaSeq - 1));
    this.connection.sendRawXML(StreamManagementAckNonza(this._serverStanzaSeq - 1));
  }

  /// To be called whenever we receive a stanza from the server.
  void serverStanzaReceived() {
    if (this._serverStanzaSeq + 1 == XML_UINT_MAX) {
      this._serverStanzaSeq = 0;
    } else {
      this._serverStanzaSeq++;
    }
  }

  /// To be called whenever we send a stanza.
  void clientStanzaSent(Stanza stanza) {
    this._unackedStanzas[this._clientStanzaSeq] = stanza;

    if (this._clientStanzaSeq + 1 == XML_UINT_MAX) {
      this._clientStanzaSeq = 0;
    } else {
      this._clientStanzaSeq++;
    }

    print("Queue after sending: " + this._unackedStanzas.toString());
  }

  /// Removes all stanzas in the unacked queue that have a sequence number less-than or
  /// equal to [h].
  void _removeHandledStanzas(int h) {
    this._unackedStanzas.removeWhere(
      (key, _) => key <= h
    );
    print("Queue after cleaning: " + this._unackedStanzas.toString());
  }

  /// To be called when we receive a <r /> nonza from the server.
  void handleAckResponse(int h) {
    this._removeHandledStanzas(h);
    
    if (this._unackedStanzas.isNotEmpty) {
      this._clientStanzaSeq = h + 1;
      print("QUEUE NOT EMPTY. FLUSHING");
      this._flushStanzaQueue();
    }
  }

  /// To be called when the stream has been resumed
  void onStreamResumed(int h) {
    this._removeHandledStanzas(h);
    
    this._clientStanzaSeq = 0;
    this._serverStanzaSeq = 0;

    this._flushStanzaQueue();
  }

  /// This empties the unacked queue by sending the items out again.
  void _flushStanzaQueue() {
    List<Stanza> stanzas = this._unackedStanzas.values.toList();
    // TODO: Maybe don't do this
    //       What we should do: Set our h counter to what the server has sent, kill all those   //       received stanzas from the unacked queue and send the unacked ones again.
    this._unackedStanzas.clear();

    stanzas.forEach((stanza) => this.connection.sendStanza(stanza));
  }
}
