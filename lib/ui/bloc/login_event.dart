part of "login_bloc.dart";

abstract class LoginEvent {}

/// Triggered when the login is to be performed
class LoginSubmittedEvent extends LoginEvent {}

/// Triggered when the content of the JID textfield has changed.
class LoginJidChangedEvent extends LoginEvent {
  final String jid;

  LoginJidChangedEvent(this.jid);
}

/// Triggered when the content of the password textfield has changed.
class LoginPasswordChangedEvent extends LoginEvent {
  final String password;

  LoginPasswordChangedEvent(this.password);
}

/// Triggered when the password visibility is to be toggled
class LoginPasswordVisibilityToggledEvent extends LoginEvent {}
