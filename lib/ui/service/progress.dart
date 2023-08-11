import 'package:logging/logging.dart';
import 'package:moxxyv2/shared/models/message.dart';

typedef UIProgressCallback = void Function(double?);

/// This class handles download progress notifications from the backend and relays them
/// to the correct ChatBubble instance so that it can update itself.
class UIProgressService {
  UIProgressService()
      : _callbacks = {},
        _log = Logger('UIProgressService');

  final Logger _log;
  // Database message id -> callback function
  final Map<MessageKey, UIProgressCallback> _callbacks;

  void registerCallback(MessageKey key, UIProgressCallback callback) {
    _log.finest('Registering callback for $key');
    _callbacks[key] = callback;
  }

  void unregisterCallback(MessageKey key) {
    _log.finest('Unregistering callback for $key');
    _callbacks.remove(key);
  }

  void unregisterAll() {
    _log.finest('Unregistering all callbacks');
    _callbacks.clear();
  }

  void onProgress(MessageKey key, double? progress) {
    if (_callbacks.containsKey(key)) {
      if (progress == 1.0) {
        unregisterCallback(key);
      } else {
        _callbacks[key]!(progress);
      }
    } else {
      _log.warning('Received progress callback for unregistered key $key');
    }
  }
}
