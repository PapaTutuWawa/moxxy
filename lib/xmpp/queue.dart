import "dart:collection";

import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/stanzas/stanza.dart";

//class SendQueue {
extension SendQueue on XmppConnection {
  final Queue<XMLNode> _queue;
  final bool Function() canSend;
  final bool _isRunning;
  final SocketWrapper socket;

  SendQueue({ required this.canSend, required this.socket }) : _queue = Queue(), _isRunning = false;

  void enqueue(XMLNode data) {
    this._queue.add(data);

    if (!this._isRunning) {
      this._isRunning = true;
      this._processQueue();
    }
  }

  void _processQueue() {
    while (this.canSend() && this._queue.isNotEmpty) {
      final item = this._queue.removeFirst();

      
    }
  }
}
