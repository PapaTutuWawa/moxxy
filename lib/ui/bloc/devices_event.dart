part of 'devices_bloc.dart';

abstract class DevicesEvent {}

/// Triggered when the user requested the key page
class DevicesRequestedEvent extends DevicesEvent {

  DevicesRequestedEvent(this.jid);
  final String jid;
}

/// Triggered by the UI when we want to enable or disable a key
class DeviceEnabledSetEvent extends DevicesEvent {

 DeviceEnabledSetEvent(this.deviceId, this.enabled);
 final int deviceId;
 final bool enabled;
}

/// Triggered by the UI when all OMEMO sessions should be recreated
class SessionsRecreatedEvent extends DevicesEvent {}
