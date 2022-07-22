import 'package:logging/logging.dart';

typedef UIDownloadCallback = void Function(double);

/// This class handles download progress notifications from the backend and relays them
/// to the correct ChatBubble instance so that it can update itself.
class UIDownloadService {
  UIDownloadService() : _callbacks = {}, _log = Logger('UIDownloadService');

  final Logger _log;
  // Database message id -> callback function
  final Map<int, UIDownloadCallback> _callbacks;

  void registerCallback(int id, UIDownloadCallback callback) {
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
