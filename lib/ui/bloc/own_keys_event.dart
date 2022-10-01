part of 'own_keys_bloc.dart';

abstract class OwnKeysEvent {}

/// Triggered when the user requested the own keys page
class OwnKeysRequestedEvent extends OwnKeysEvent {}

/// Triggered by the UI when we want to enable or disable a key
class OwnKeyEnabledSetEvent extends OwnKeysEvent {

 OwnKeyEnabledSetEvent(this.deviceId, this.enabled);
 final int deviceId;
 final bool enabled;
}

/// Triggered by the UI when all OMEMO sessions should be recreated
class OwnSessionsRecreatedEvent extends OwnKeysEvent {}

/// Triggered by the UI when the OMEMO device should be regenerated
class OwnDeviceRegeneratedEvent extends OwnKeysEvent {}

/// Triggered by the UI when the device with id [deviceId] should be removed.
class OwnDeviceRemovedEvent extends OwnKeysEvent {

  OwnDeviceRemovedEvent(this.deviceId);
  final int deviceId;
}
