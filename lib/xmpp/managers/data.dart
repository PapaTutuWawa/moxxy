import "package:freezed_annotation/freezed_annotation.dart";

import "package:moxxyv2/xmpp/stanza.dart";
import "package:moxxyv2/xmpp/xeps/xep_0066.dart";
import "package:moxxyv2/xmpp/xeps/xep_0359.dart";
import "package:moxxyv2/xmpp/xeps/xep_0385.dart";
import "package:moxxyv2/xmpp/xeps/xep_0447.dart";

part "data.freezed.dart";

@freezed
class StanzaHandlerData with _$StanzaHandlerData {
  factory StanzaHandlerData(
    // Indicates to the runner that processing is now done. This means that all
    // pre-processing is done and no other handlers should be consulted.
    bool done,
    // The stanza that is being dealt with
    Stanza stanza,
    {
      StatelessMediaSharingData? sims,
      StatelessFileSharingData? sfs,
      OOBData? oob,
      StableStanzaId? stableId,
      @Default(false) bool isCarbon,
      @Default(false) bool deliveryReceiptRequested,
      @Default(false) bool isMarkable
    }
  ) = _StanzaHandlerData;
}
