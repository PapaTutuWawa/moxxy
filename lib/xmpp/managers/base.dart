import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/stanzas/stanza.dart";
import "package:moxxyv2/xmpp/managers/handlers.dart";
import "package:moxxyv2/xmpp/managers/attributes.dart";

abstract class XmppManagerBase {
  late final XmppManagerAttributes _managerAttributes;

  /// Registers the callbacks from [XmppConnection] with the manager
  void register(XmppManagerAttributes attributes) {
    _managerAttributes = attributes;
  }

  /// Returns the attributes that are registered with the manager.
  /// Must only be called after register has been called on it.
  XmppManagerAttributes getAttributes() {
    return _managerAttributes;
  }

  /// Return the [StanzaHandler]s associated with this manager.
  List<StanzaHandler> getStanzaHandlers() => [];

  /// Return the [NonzaHandler]s associated with this manager.
  List<NonzaHandler> getNonzaHandlers() => [];

  /// Return a list of features that should be included in a disco response
  List<String> getDiscoFeatures() => [];
  
  /// Return the Id (akin to xmlns) of this manager.
  String getId();

  /// Called when [XmppConnection] triggers an event
  void onXmppEvent(XmppEvent event) {}

  /// Runs all [NonzaHandler]s of this Manager which match the nonza. Resolves to true if
  /// the nonza has been handled by one of the handlers. Resolves to false otherwise.
  Future<bool> runNonzaHandlers(XMLNode nonza) async {
    bool handled = false;
    await Future.forEach(
      getNonzaHandlers(),
      (NonzaHandler handler) async {
        if (handler.matches(nonza)) {
          handled = true;
          await handler.callback(nonza);
        }
      }
    );

    return handled;
  }

  /// Runs all [StanzaHandlers] of this Manager which match the nonza. Resolves to true if
  /// the nonza has been handled by one of the handlers. Resolves to false otherwise.
  Future<bool> runStanzaHandlers(Stanza stanza) async {
    bool handled = false;
    await Future.forEach(
      getStanzaHandlers(),
      (StanzaHandler handler) async {
        if (handler.matches(stanza)) {
          handled = true;
          await handler.callback(stanza);
        }
      }
    );

    return handled;
  }
}
