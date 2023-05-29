import 'package:logging/logging.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';

class UIAvatarsService {
  /// Logger
  final Logger _log = Logger('UIAvatarsService');

  /// Mapping between a JID and whether we have requested an avatar for the
  /// JID already in the session (from login until stream resumption failure).
  final Map<String, bool> _avatarRequested = {};

  void requestAvatarIfRequired(String jid, String? hash) {
    if (_avatarRequested[jid] ?? false) return;

    _log.finest('Requesting avatar for $jid');
    _avatarRequested[jid] = true;
    MoxplatformPlugin.handler.getDataSender().sendData(
      RequestAvatarForJidCommand(jid: jid, hash: hash),
    );
  }
}
