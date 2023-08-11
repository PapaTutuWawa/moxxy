import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';

/// A UI service that is responsible for managing whether a read marker should
/// get sent for a given message and, if all checks are green, actually send the
/// read marker.
class UIReadMarkerService {
  /// The Logger.
  final Logger _log = Logger('UIReadMarkerService');

  /// The cache of messages we already processed.
  final Map<MessageKey, bool> _messages = {};

  /// Checks if we should send a read marker for [message]. If we should, tells
  /// the backend to actually send it.
  void handleMarker(Message message) {
    if (_messages.containsKey(message.messageKey)) return;

    // Make sure we don't reach here anymore.
    _messages[message.messageKey] = true;

    // Only send this for messages we have not yet marked as read.
    if (message.displayed) return;

    // Check if we should send markers.
    if (!GetIt.I.get<PreferencesBloc>().state.sendChatMarkers) return;

    final id = message.originId ?? message.sid;
    _log.finest('Sending chat marker for ${message.conversationJid}:$id');
    MoxplatformPlugin.handler.getDataSender().sendData(
          MarkMessageAsReadCommand(
            sid: message.sid,
            conversationJid: message.conversationJid,
            sendMarker: true,
          ),
          awaitable: false,
        );
  }

  /// Empties the internal cache.
  void clear() {
    _messages.clear();
  }
}
