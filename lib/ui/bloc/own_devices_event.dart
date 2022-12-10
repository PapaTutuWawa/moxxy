part of 'own_devices_bloc.dart';

abstract class OwnDevicesEvent {}

/// Triggered when the user requested the own keys page
class OwnDevicesRequestedEvent extends OwnDevicesEvent {}

/// Triggered by the UI when we want to enable or disable a key
class OwnDeviceEnabledSetEvent extends OwnDevicesEvent {

 OwnDeviceEnabledSetEvent(this.deviceId, this.enabled);
 final int deviceId;
 final bool enabled;
}

/// Triggered by the UI when all OMEMO sessions should be recreated
class OwnSessionsRecreatedEvent extends OwnDevicesEvent {}

/// Triggered by the UI when the OMEMO device should be regenerated
class OwnDeviceRegeneratedEvent extends OwnDevicesEvent {}

/// Triggered by the UI when the device with id [deviceId] should be removed.
class OwnDeviceRemovedEvent extends OwnDevicesEvent {
  OwnDeviceRemovedEvent(this.deviceId);
  final int deviceId;
}

/// Triggered by the UI when a device has been verified using the QR code
class DeviceVerifiedEvent extends OwnDevicesEvent {
  DeviceVerifiedEvent(this.uri, this.deviceId);
  final Uri uri;
  final int deviceId;
}
