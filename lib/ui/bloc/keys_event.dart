part of 'keys_bloc.dart';

abstract class KeysEvent {}

/// Triggered when the user requested the key page
class KeysRequestedEvent extends KeysEvent {

  KeysRequestedEvent(this.jid);
  final String jid;
}

/// Triggered by the UI when we want to enable or disable a key
class KeyEnabledSetEvent extends KeysEvent {

 KeyEnabledSetEvent(this.deviceId, this.enabled);
 final int deviceId;
 final bool enabled;
}
