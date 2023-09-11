import 'dart:async';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';

class StorageState {
  const StorageState(
    this.mediaUsage,
    this.stickersUsage,
  );

  /// The storage usage of sticker packs in bytes.
  final int stickersUsage;

  /// The storage usage of media files in bytes.
  final int mediaUsage;

  /// The total used storage.
  int get totalUsage => stickersUsage + mediaUsage;
}

/// A controller class for managing requesting the storage usage and handling changes
/// to the storage usage induced by UI actions.
class StorageController {
  StorageController()
      : assert(
          instance == null,
          'Only one instance of StorageController can exist',
        ) {
    StorageController.instance = this;
  }

  // ignore: prefer_final_fields
  StorageState _state = const StorageState(
    0,
    0,
  );

  /// The stream controller.
  final StreamController<StorageState> _controller =
      StreamController<StorageState>.broadcast();
  Stream<StorageState> get stream => _controller.stream;

  /// Singleton instance
  static StorageController? instance;

  /// Fetches the total storage usage from the service and triggers an event on the
  /// event stream.
  Future<void> fetchStorageUsage() async {
    // ignore: cast_nullable_to_non_nullable
    final result = await getForegroundService().send(
      GetStorageUsageCommand(),
    ) as GetStorageUsageEvent;

    _state = StorageState(
      result.mediaUsage,
      result.stickerUsage,
    );
    _controller.add(_state);
  }

  /// Updates the state by replacing the storage usage with [newUsage].
  void mediaUsageUpdated(int newUsage) {
    _state = StorageState(
      newUsage,
      _state.stickersUsage,
    );
    _controller.add(_state);
  }

  /// Updates the state by subtracting [size] from the stickersUsage.
  void stickerPackRemoved(int size) {
    _state = StorageState(
      _state.mediaUsage,
      _state.stickersUsage - size,
    );
    _controller.add(_state);
  }

  /// Disposes of the singleton
  void dispose() {
    StorageController.instance = null;
  }
}
