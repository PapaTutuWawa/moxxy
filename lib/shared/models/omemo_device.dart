import 'package:freezed_annotation/freezed_annotation.dart';

part 'omemo_device.freezed.dart';
part 'omemo_device.g.dart';

/// This model is just for communication between UI and the backend.
@freezed
class OmemoDevice with _$OmemoDevice {
  factory OmemoDevice(
    String fingerprint,
    bool trusted,
    bool verified,
    bool enabled,
    int deviceId, {
    @Default(true) bool hasSessionWith,
  }) = _OmemoDevice;

  /// JSON
  factory OmemoDevice.fromJson(Map<String, dynamic> json) =>
      _$OmemoDeviceFromJson(json);
}
