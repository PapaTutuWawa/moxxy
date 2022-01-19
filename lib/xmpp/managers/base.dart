import "dart:collection";

import "package:moxxyv2/xmpp/managers/handlers.dart";
import "package:moxxyv2/xmpp/managers/attributes.dart";
import "package:moxxyv2/xmpp/events.dart";

abstract class XmppManagerBase {
  late final XmppManagerAttributes _managerAttributes;

  /// Registers the callbacks from [XmppConnection] with the manager
  void register(XmppManagerAttributes attributes) {
    this._managerAttributes = attributes;
  }

  /// Returns the attributes that are registered with the manager.
  /// Must only be called after register has been called on it.
  XmppManagerAttributes getAttributes() {
    return this._managerAttributes;
  }

  /// Return the [StanzaHandler]s associated with this manager.
  List<StanzaHandler> getStanzaHandlers() => [];

  /// Return the [NonzaHandler]s associated with this manager.
  List<NonzaHandler> getNonzaHandlers() => [];

  /// Return the Id (akin to xmlns) of this manager.
  String getId();

  /// Called when [XmppConnection] triggers an event
  void onXmppEvent(XmppEvent event) {}
}
