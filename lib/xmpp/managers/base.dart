import 'package:logging/logging.dart';
import 'package:moxxyv2/xmpp/events.dart';
import 'package:moxxyv2/xmpp/managers/attributes.dart';
import 'package:moxxyv2/xmpp/managers/handlers.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';

abstract class XmppManagerBase {
  late final XmppManagerAttributes _managerAttributes;
  late final Logger _log;

  /// Registers the callbacks from XmppConnection with the manager
  void register(XmppManagerAttributes attributes) {
    _managerAttributes = attributes;
    _log = Logger(getName());
  }
  
  /// Returns the attributes that are registered with the manager.
  /// Must only be called after register has been called on it.
  XmppManagerAttributes getAttributes() {
    return _managerAttributes;
  }

  /// Return the StanzaHandlers associated with this manager that deal with stanzas we
  /// send. These are run before the stanza is sent.
  List<StanzaHandler> getOutgoingPreStanzaHandlers() => [];

  /// Return the StanzaHandlers associated with this manager that deal with stanzas we
  /// send. These are run after the stanza is sent.
  List<StanzaHandler> getOutgoingPostStanzaHandlers() => [];
  
  /// Return the StanzaHandlers associated with this manager that deal with stanzas we
  /// receive.
  List<StanzaHandler> getIncomingStanzaHandlers() => [];
  
  /// Return the NonzaHandlers associated with this manager.
  List<NonzaHandler> getNonzaHandlers() => [];

  /// Return a list of features that should be included in a disco response.
  List<String> getDiscoFeatures() => [];
  
  /// Return the Id (akin to xmlns) of this manager.
  String getId();

  /// Return a name that will be used for logging.
  String getName();

  /// Return the logger for this manager.
  Logger get logger => _log;
  
  /// Called when XmppConnection triggers an event
  Future<void> onXmppEvent(XmppEvent event) async {}

  /// Runs all NonzaHandlers of this Manager which match the nonza. Resolves to true if
  /// the nonza has been handled by one of the handlers. Resolves to false otherwise.
  Future<bool> runNonzaHandlers(XMLNode nonza) async {
    var handled = false;
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
}
