/// Triggered when a contact is to be added to the roster
class AddContactAction {
  final String jid;

  AddContactAction({ required this.jid });
}

/// Triggered when an error message is to be displayed
class AddContactSetErrorLogin {
  final String? errorText;

  AddContactSetErrorLogin({ this.errorText });
}
