import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/ui/bloc/account.dart';
import 'package:moxxyv2/ui/bloc/navigation.dart';
import 'package:moxxyv2/ui/bloc/request.dart';
import 'package:moxxyv2/ui/constants.dart';

part 'login.freezed.dart';

class LoginFormState {
  const LoginFormState(this.isOkay, {this.error});
  final bool isOkay;
  final String? error;
}

@freezed
class LoginState with _$LoginState {
  factory LoginState({
    @Default('') String jid,
    @Default('') String password,
    @Default(false) bool working,
    @Default(false) bool passwordVisible,
    @Default(LoginFormState(true)) LoginFormState jidState,
    @Default(LoginFormState(true)) LoginFormState passwordState,
  }) = _LoginState;
}

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(LoginState());

  void onJidChanged(String jid) {
    emit(state.copyWith(jid: jid));
  }

  void onPasswordChanged(String password) {
    emit(state.copyWith(password: password));
  }

  void onPasswordVisibilityToggled() {
    emit(state.copyWith(passwordVisible: !state.passwordVisible));
  }

  Future<void> submit() async {
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
          passwordState:
              const LoginFormState(false, error: 'Password cannot be empty'),
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

    final result = await getForegroundService().send(
      LoginCommand(
        jid: state.jid,
        password: state.password,
        useDirectTLS: true,
      ),
    );

    if (result is LoginSuccessfulEvent) {
      emit(state.copyWith(working: false));

      // Set up BLoCs
      // TODO(Unknown): Use addAccount?
      GetIt.I.get<AccountCubit>().setAccounts(
        [
          Account(
            displayName: result.preStart.displayName!,
            avatarPath: result.preStart.avatarUrl,
            avatarHash: result.preStart.avatarHash,
            jid: result.preStart.jid!,
          ),
        ],
        0,
      );
      GetIt.I.get<Navigation>().pushNamedAndRemoveUntil(
            const NavigationDestination(
              homeRoute,
            ),
            (_) => false,
          );
      GetIt.I.get<RequestCubit>().setRequests(
        [
          if (result.preStart.requestNotificationPermission)
            Request.notifications,
          if (result.preStart.excludeFromBatteryOptimisation)
            Request.batterySavingExcemption,
        ],
      );
    } else if (result is LoginFailureEvent) {
      return emit(
        state.copyWith(
          working: false,
          passwordState: LoginFormState(
            false,
            error: result.reason ?? 'Failed to connect',
          ),
        ),
      );
    }
  }
}
