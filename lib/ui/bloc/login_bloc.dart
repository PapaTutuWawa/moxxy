import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/ui/bloc/conversations_bloc.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/service/data.dart';

part 'login_bloc.freezed.dart';
part 'login_event.dart';
part 'login_state.dart';

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
    final jidValidity = validateJidString(state.jid);
    if (jidValidity != null) {
      return emit(
        state.copyWith(
          jidState: LoginFormState(false, error: jidValidity),
          passwordState: const LoginFormState(true),
        ),
      );
    }

    if (state.password.isEmpty) {
      return emit(
        state.copyWith(
          jidState: const LoginFormState(true),
          passwordState: const LoginFormState(false, error: 'Password cannot be empty'),
        ),
      );
    }
    
    emit(
      state.copyWith(
        working: true,
        passwordVisible: false,
        jidState: const LoginFormState(true),
        passwordState: const LoginFormState(true),
      ),
    );

    final result = await MoxplatformPlugin.handler.getDataSender().sendData(
      LoginCommand(
        jid: state.jid,
        password: state.password,
        useDirectTLS: true,
      ),
    );

    if (result is LoginSuccessfulEvent) {
      emit(state.copyWith(working: false));

      // Update the UIDataService
      GetIt.I.get<UIDataService>().processPreStartDoneEvent(result.preStart);

      // Set up BLoCs
      GetIt.I.get<ConversationsBloc>().add(
        ConversationsInitEvent(
          result.preStart.displayName!,
          state.jid,
          result.preStart.conversations!,
        ),
      );
      GetIt.I.get<NavigationBloc>().add(
        PushedNamedAndRemoveUntilEvent(
          const NavigationDestination(
            conversationsRoute,
          ),
          (_) => false,
        ),
      );
    } else if (result is LoginFailureEvent) {
      GetIt.I.get<UIDataService>().isLoggedIn = false;
      return emit(
        state.copyWith(
          working: false,
          passwordState: LoginFormState(false, error: result.reason),
        ),
      );
    }
  }
}
