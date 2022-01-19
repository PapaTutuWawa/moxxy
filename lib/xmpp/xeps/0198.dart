import "dart:collection";
import "dart:math";

import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/stanzas/stanza.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/stanzas/stanza.dart";
import "package:moxxyv2/xmpp/nonzas/sm.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/managers/handlers.dart";
import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";

const XML_UINT_MAX = 4294967296; // 2**32

// TODO: We need to save both the client and server h values and send them accordingly
class StreamManagementManager extends XmppManagerBase {
  // NOTE: _{client,server}StanzaSeq is the next sequence number to use
  int _clientStanzaSeq;
  int _serverStanzaSeq;
  Map<int, Stanza> _unackedStanzas;
  bool _streamManagementEnabled;

  StreamManagementManager() : _clientStanzaSeq = 0, _serverStanzaSeq = 0, _unackedStanzas = Map(), _streamManagementEnabled = false;

  /// Functions for testing
  int getClientStanzaSeq() => this._clientStanzaSeq;
  int getServerStanzaSeq() => this._serverStanzaSeq;
  Map<int, Stanza> getUnackedStanzas() => this._unackedStanzas;

  /// May be overwritten by a subclass. Should save [_clientStanzaSeq] and [_serverStanzaSeq]
  /// so that they can be loaded again with [this.loadSequenceCounters].
  /* TODO
  Future<void> commitSequenceCounters() async {}
  Future<void> loadSequenceCounters() async {}
  */
  
  @override
  String getId() => SM_MANAGER;

  @override
  List<NonzaHandler> getNonzaHandlers() => [
    NonzaHandler(
      nonzaTag: "r",
      nonzaXmlns: SM_XMLNS,
      callback: this._handleAckRequest
    ),
    NonzaHandler(
      nonzaTag: "a",
      nonzaXmlns: SM_XMLNS,
      callback: this._handleAckResponse
    )
  ];

  @override
  List<StanzaHandler> getStanzaHandlers() => [
    StanzaHandler(
      callback: this._serverStanzaReceived
    )
  ];

  @override
  void onXmppEvent(XmppEvent event) {
    if (event is StanzaSentEvent) {
      this._onClientStanzaSent(event.stanza);
    } else if (event is SendPingEvent) {
      if (this.isStreamManagementEnabled()) {
        this._sendAckRequestPing();
      } else {
        this.getAttributes().sendRawXml("");
      }
    } else if (event is StreamResumedEvent) {
      this._enableStreamManagement();
      this._onStreamResumed(event.h);
    } else if (event is StreamManagementEnabledEvent) {
      this._enableStreamManagement();
      // TODO: Can we handle this more elegantly?
      this._onStreamResumed(0);
    }
  }

  /// Enables support for XEP-0198 stream management
  void _enableStreamManagement() {
    this._streamManagementEnabled = true;
  }
  
  /// Returns whether XEP-0198 stream management is enabled
  bool isStreamManagementEnabled() => this._streamManagementEnabled;

  /// To be called when receiving a <a /> nonza.
  bool _handleAckRequest(XMLNode nonza) {
    this.getAttributes().log("Sending ack response");
    this.getAttributes().sendEvent(StreamManagementAckSentEvent(h: this._serverStanzaSeq - 1));
    this.getAttributes().sendNonza(StreamManagementAckNonza(this._serverStanzaSeq - 1));

    return true;
  }

  /// To be called when we receive a <r /> nonza from the server.
  bool _handleAckResponse(XMLNode nonza) {
    final h = int.parse(nonza.attributes["h"]!);
    
    this._removeHandledStanzas(h);

    // TODO: Set clientSequence
    
    if (this._unackedStanzas.isNotEmpty) {
      this._clientStanzaSeq = h + 1;
      print("QUEUE NOT EMPTY. FLUSHING");
      this._flushStanzaQueue();
    }

    return true;
  }
   
  /// To be called whenever we receive a stanza from the server.
  bool _serverStanzaReceived(stanza) {
    print("called");
    if (this._serverStanzaSeq + 1 == XML_UINT_MAX) {
      this._serverStanzaSeq = 0;
    } else {
      this._serverStanzaSeq++;
    }

    return false;
  }

  /// To be called whenever we send a stanza.
  void _onClientStanzaSent(Stanza stanza) {
    this._unackedStanzas[this._clientStanzaSeq] = stanza;

    if (this._clientStanzaSeq + 1 == XML_UINT_MAX) {
      this._clientStanzaSeq = 0;
    } else {
      this._clientStanzaSeq++;
    }

    print("Queue after sending: " + this._unackedStanzas.toString());

    if (this.isStreamManagementEnabled()) {
      this.getAttributes().sendNonza(StreamManagementRequestNonza());
    }
  }

  /// Removes all stanzas in the unacked queue that have a sequence number less-than or
  /// equal to [h].
  void _removeHandledStanzas(int h) {
    this._unackedStanzas.removeWhere(
      (key, _) => key <= h
    );
    print("Queue after cleaning: " + this._unackedStanzas.toString());
  }

  /// To be called when the stream has been resumed
  void _onStreamResumed(int h) {
    this._removeHandledStanzas(h);
    
    //this._clientStanzaSeq = 0;
    this._serverStanzaSeq = h == 0 ? 0 : h + 1;

    this._flushStanzaQueue();
  }

  /// This empties the unacked queue by sending the items out again.
  void _flushStanzaQueue() {
    List<Stanza> stanzas = this._unackedStanzas.values.toList();
    // TODO: Maybe don't do this
    //       What we should do: Set our h counter to what the server has sent, kill all those   //       received stanzas from the unacked queue and send the unacked ones again.
    this._unackedStanzas.clear();

    final attributes = this.getAttributes();
    stanzas.forEach((stanza) => attributes.sendStanza(stanza));
  }

  /// Pings the connection open by send an ack request
  void _sendAckRequestPing() {
    this.getAttributes().sendNonza(StreamManagementRequestNonza());
  }
}
