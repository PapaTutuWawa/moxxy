typedef UIDownloadCallback = void Function(double);

/// This class handles download progress notifications from the backend and relays them
/// to the correct [ChatBubble] instance so that it can update itself.
class UIDownloadService {
  final Map<int, UIDownloadCallback> _callbacks; // Database message id -> callback function

  UIDownloadService() : _callbacks = {};

  void registerCallback(int id, UIDownloadCallback callback) {
    _callbacks[id] = callback;
  }

  void unregisterCallback(int id) {
    _callbacks.remove(id);
  }

  void onProgress(int id, double progress) {
    if (_callbacks.containsKey(id)) {
      if (progress == 1.0) {
        unregisterCallback(id);
      } else {
        _callbacks[id]!(progress);
      }
    } else {
      // TODO: Log
    }
  }
}
