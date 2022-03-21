import "package:moxxyv2/shared/helpers.dart";
import "package:moxxyv2/shared/commands.dart";
import "package:moxxyv2/shared/events.dart";
import "package:moxxyv2/shared/backgroundsender.dart";

import "package:get_it/get_it.dart";
import "package:bloc/bloc.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "login_state.dart";
part "login_event.dart";
part "login_bloc.freezed.dart";

/// Returns an error string if [jid] is not a valid JID. Returns null if everything
/// appears okay.
String? _validateJid(String jid) {
  switch (validateJid(jid)) {
    case JidFormatError.empty: return "XMPP-Address cannot be empty";
    case JidFormatError.noSeparator:
    case JidFormatError.tooManySeparators: return "XMPP-Address must contain exactly one @";
    // TODO: Find a better text
    case JidFormatError.noDomain: return "A domain must follow the @";
    case JidFormatError.noLocalpart: return "Your username must preceed the @";
    case JidFormatError.none: return null;
  }
}

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginState()) {
    on<LoginJidChangedEvent>(_onJidChanged);
    on<LoginPasswordChangedEvent>(_onPasswordChanged);
    on<LoginPasswordVisibilityToggledEvent>(_onPasswordVisibilityToggled);
    on<LoginSubmittedEvent>(_onSubmitted);
  }

  Future<void> _onJidChanged(LoginJidChangedEvent event, Emitter<LoginState> emit) async {
    emit(state.copyWith(jid: event.jid));
  }

  Future<void> _onPasswordChanged(LoginPasswordChangedEvent event, Emitter<LoginState> emit) async {
    emit(state.copyWith(password: event.password));
  }

  Future<void> _onPasswordVisibilityToggled(LoginPasswordVisibilityToggledEvent event, Emitter<LoginState> emit) async {
    emit(state.copyWith(passwordVisible: !state.passwordVisible));
  }
  
  Future<void> _onSubmitted(LoginSubmittedEvent event, Emitter<LoginState> emit) async {
    final jidValidity = _validateJid(state.jid);
    if (jidValidity != null) {
      return emit(
        state.copyWith(
          jidState: LoginFormState(false, error: jidValidity),
          passwordState: LoginFormState(true)
        )
      );
    }

    if (state.password.isEmpty) {
      return emit(
        state.copyWith(
          jidState: LoginFormState(true),
          passwordState: LoginFormState(false, error: "Password cannot be empty")
        )
      );
    }
    
    emit(
      state.copyWith(
        working: true,
        jidState: LoginFormState(true),
        passwordState: LoginFormState(true)
      )
    );

    // TODO: Actually perform the login
    // TODO: Maybe let [LoginSuccessfulEvent] and [LoginFailureEvent] have a common
    //       super-class such that we can imediately cast it up to that and then see
    //       if it was successful and cast accordingly.
    final result = await GetIt.I.get<BackgroundServiceDataSender>().sendData(
      LoginCommand(
        jid: state.jid,
        password: state.password,
        useDirectTLS: true
      )
    ) as LoginSuccessfulEvent;

    print(result.displayName);
  }
}
