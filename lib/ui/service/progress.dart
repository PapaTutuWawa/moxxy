import 'package:logging/logging.dart';

typedef UIProgressCallback = void Function(double?);

/// This class handles download progress notifications from the backend and relays them
/// to the correct ChatBubble instance so that it can update itself.
class UIProgressService {
  /// Logger.
  final Logger _log = Logger('UIProgressService');

  // Database message id -> callback function
  final Map<String, UIProgressCallback> _callbacks = {};

  void registerCallback(String id, UIProgressCallback callback) {
    _log.finest('Registering callback for $id');
    _callbacks[id] = callback;
  }

  void unregisterCallback(String id) {
    _log.finest('Unregistering callback for $id');
    _callbacks.remove(id);
  }

  void unregisterAll() {
    _log.finest('Unregistering all callbacks');
    _callbacks.clear();
  }

  void onProgress(String id, double? progress) {
    if (_callbacks.containsKey(id)) {
      if (progress == 1.0) {
        unregisterCallback(id);
      } else {
        _callbacks[id]!(progress);
      }
    } else {
      _log.warning('Received progress callback for unregistered key $id');
    }
  }
}
