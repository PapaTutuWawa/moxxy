part of 'login_bloc.dart';

abstract class LoginEvent {}

/// Triggered when the login is to be performed
class LoginSubmittedEvent extends LoginEvent {}

/// Triggered when the content of the JID textfield has changed.
class LoginJidChangedEvent extends LoginEvent {
  LoginJidChangedEvent(this.jid);
  final String jid;
}

/// Triggered when the content of the password textfield has changed.
class LoginPasswordChangedEvent extends LoginEvent {
  LoginPasswordChangedEvent(this.password);
  final String password;
}

/// Triggered when the password visibility is to be toggled
class LoginPasswordVisibilityToggledEvent extends LoginEvent {}
