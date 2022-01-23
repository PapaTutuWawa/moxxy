import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/stanzas/stanza.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/nonzas/sm.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/managers/handlers.dart";
import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";

const xmlUintMax = 4294967296; // 2**32

// TODO: We need to save both the client and server h values and send them accordingly
class StreamManagementManager extends XmppManagerBase {
  // NOTE: _{client,server}StanzaSeq is the next sequence number to use
  int _clientStanzaSeq;
  int _serverStanzaSeq;
  final Map<int, Stanza> _unackedStanzas;
  String? _streamResumptionId;
  bool _streamManagementEnabled;

  StreamManagementManager() : _clientStanzaSeq = 0, _serverStanzaSeq = 0, _unackedStanzas = {}, _streamResumptionId = null, _streamManagementEnabled = false;

  /// Functions for testing
  int getClientStanzaSeq() => _clientStanzaSeq;
  int getServerStanzaSeq() => _serverStanzaSeq;
  Map<int, Stanza> getUnackedStanzas() => _unackedStanzas;

  /// May be overwritten by a subclass. Should save [_clientStanzaSeq] and [_serverStanzaSeq]
  /// so that they can be loaded again with [this.loadSequenceCounters].
  Future<void> commitClientSeq() async {}
  Future<void> loadClientSeq() async {}

  void setClientSeq(int h) {
    // Prevent this being called multiple times
    assert(_clientStanzaSeq == 0);

    _clientStanzaSeq = h;
  }

  /// May be overwritten by a subclass. Should save and load [_streamResumptionId].
  Future<void> commitStreamResumptionId() async {}
  Future<void> loadStreamResumptionId() async {}

  void setStreamResumptionId(String id) {
    // Prevent this being called multiple times
    assert(_streamResumptionId == null);

    _streamResumptionId = id;
  }

  @override
  String getId() => smManager;

  @override
  List<NonzaHandler> getNonzaHandlers() => [
    NonzaHandler(
      nonzaTag: "r",
      nonzaXmlns: smXmlns,
      callback: _handleAckRequest
    ),
    NonzaHandler(
      nonzaTag: "a",
      nonzaXmlns: smXmlns,
      callback: _handleAckResponse
    )
  ];

  @override
  List<StanzaHandler> getStanzaHandlers() => [
    StanzaHandler(
      callback: _serverStanzaReceived
    )
  ];

  @override
  void onXmppEvent(XmppEvent event) {
    if (event is StanzaSentEvent) {
      _onClientStanzaSent(event.stanza);
    } else if (event is SendPingEvent) {
      if (isStreamManagementEnabled()) {
        _sendAckRequestPing();
      } else {
        getAttributes().sendRawXml("");
      }
    } else if (event is StreamResumedEvent) {
      _enableStreamManagement();
      _onStreamResumed(event.h);
    } else if (event is StreamManagementEnabledEvent) {
      _streamResumptionId = event.id;
      commitStreamResumptionId();
      _enableStreamManagement();

      // TODO: Can we handle this more elegantly?
      _onStreamResumed(0);
    }
  }

  /// Enables support for XEP-0198 stream management
  void _enableStreamManagement() {
    _streamManagementEnabled = true;
  }
  
  /// Returns whether XEP-0198 stream management is enabled
  bool isStreamManagementEnabled() => _streamManagementEnabled;

  /// To be called when receiving a <a /> nonza.
  Future<bool> _handleAckRequest(XMLNode nonza) async {
    final attrs = getAttributes();
    attrs.log("Sending ack response");
    attrs.sendEvent(StreamManagementAckSentEvent(h: _serverStanzaSeq - 1));
    attrs.sendNonza(StreamManagementAckNonza(_serverStanzaSeq - 1));

    return true;
  }

  /// To be called when we receive a <r /> nonza from the server.
  Future<bool> _handleAckResponse(XMLNode nonza) async {
    final h = int.parse(nonza.attributes["h"]!);
    
    _removeHandledStanzas(h);

    // TODO: Set clientSequence
    
    if (_unackedStanzas.isNotEmpty) {
      _clientStanzaSeq = h + 1;
      getAttributes().log("QUEUE NOT EMPTY. FLUSHING");
      _flushStanzaQueue();
    }

    return true;
  }
   
  /// To be called whenever we receive a stanza from the server.
  Future<bool> _serverStanzaReceived(stanza) async {
    if (_serverStanzaSeq + 1 == xmlUintMax) {
      _serverStanzaSeq = 0;
    } else {
      _serverStanzaSeq++;
    }

    return false;
  }

  /// To be called whenever we send a stanza.
  void _onClientStanzaSent(Stanza stanza) {
    _unackedStanzas[_clientStanzaSeq] = stanza;

    if (_clientStanzaSeq + 1 == xmlUintMax) {
      _clientStanzaSeq = 0;
    } else {
      _clientStanzaSeq++;
    }

    getAttributes().log("Queue after sending: " + _unackedStanzas.toString());

    if (isStreamManagementEnabled()) {
      getAttributes().sendNonza(StreamManagementRequestNonza());
    }

    commitClientSeq();
  }

  /// Removes all stanzas in the unacked queue that have a sequence number less-than or
  /// equal to [h].
  void _removeHandledStanzas(int h) {
    _unackedStanzas.removeWhere(
      (key, _) => key <= h
    );
    getAttributes().log("Queue after cleaning: " + _unackedStanzas.toString());
  }

  /// To be called when the stream has been resumed
  void _onStreamResumed(int h) {
    _removeHandledStanzas(h);
    
    //_clientStanzaSeq = 0;
    _serverStanzaSeq = h == 0 ? 0 : h + 1;

    _flushStanzaQueue();
  }

  /// This empties the unacked queue by sending the items out again.
  void _flushStanzaQueue() {
    List<Stanza> stanzas = _unackedStanzas.values.toList();
    // TODO: Maybe don't do this
    //       What we should do: Set our h counter to what the server has sent, kill all those   //       received stanzas from the unacked queue and send the unacked ones again.
    _unackedStanzas.clear();

    final attrs = getAttributes();
    for (var stanza in stanzas) {
      attrs.sendStanza(stanza);
    }
  }

  /// Pings the connection open by send an ack request
  void _sendAckRequestPing() {
    getAttributes().sendNonza(StreamManagementRequestNonza());
  }

  /// Returns the stream resumption id we have
  String? getStreamResumptionId() {
    return _streamResumptionId;
  }
}
