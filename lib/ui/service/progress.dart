import 'package:logging/logging.dart';

typedef UIProgressCallback = void Function(double);

/// This class handles download progress notifications from the backend and relays them
/// to the correct ChatBubble instance so that it can update itself.
class UIProgressService {
  UIProgressService() : _callbacks = {}, _log = Logger('UIProgressService');

  final Logger _log;
  // Database message id -> callback function
  final Map<int, UIProgressCallback> _callbacks;

  void registerCallback(int id, UIProgressCallback callback) {
    _log.finest('Registering callback for $id');
    _callbacks[id] = callback;
  }

  void unregisterCallback(int id) {
    _log.finest('Unregistering callback for $id');
    _callbacks.remove(id);
  }

  void unregisterAll() {
    _log.finest('Unregistering all callbacks');
    _callbacks.clear();
  }
  
  void onProgress(int id, double progress) {
    if (_callbacks.containsKey(id)) {
      if (progress == 1.0) {
        unregisterCallback(id);
      } else {
        _callbacks[id]!(progress);
      }
    } else {
      _log.warning('Received progress callback for unregistered id $id');
    }
  }
}
