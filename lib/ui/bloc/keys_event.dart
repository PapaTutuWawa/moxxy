part of 'keys_bloc.dart';

abstract class KeysEvent {}

/// Triggered when the user requested the key page
class KeysRequestedEvent extends KeysEvent {

  KeysRequestedEvent(this.jid);
  final String jid;
}
