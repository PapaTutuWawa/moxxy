import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/xeps/xep_0198/xep_0198.dart";

class PingManager extends XmppManagerBase {
  @override
  String getId() => pingManager;

  @override
  String getName() => "PingManager";

  void _logWarning() {
    logger.warning("Cannot send keepalives as SM is not available, the socket disallows whitespace pings and does not manage its own keepalives. Cannot guarantee that the connection survives.");
  }
  
  @override
  Future<void> onXmppEvent(XmppEvent event) async {
    if (event is SendPingEvent) {
      final attrs = getAttributes();
      final socket = attrs.getSocket();

      if (socket.managesKeepalives()) return;
      
      final stream = attrs.getManagerById(smManager) as StreamManagementManager?;
      if (stream != null) {
        if (stream.isStreamManagementEnabled() /*&& stream.getUnackedStanzaCount() > 0*/) {
          stream.sendAckRequestPing();
        } else if (attrs.getSocket().whitespacePingAllowed()) {
          attrs.sendRawXml("");
        } else {
          _logWarning();
        }
      } else {
        if (attrs.getSocket().whitespacePingAllowed()) {
          attrs.sendRawXml("");
        } else {
          _logWarning();
        }
      }
    } else if (event is AckRequestResponseTimeoutEvent) {
      getAttributes().getConnection().handleError(event);
    }
  }
}
