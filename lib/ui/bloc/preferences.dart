import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/models/preferences.dart';
import 'package:moxxyv2/ui/bloc/account.dart';
import 'package:moxxyv2/ui/bloc/conversation.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';

class PreferencesCubit extends Cubit<PreferencesState> {
  PreferencesCubit()
      : _log = Logger('PreferencesBloc'),
        super(PreferencesState());
  final Logger _log;

  Future<void> change(
    PreferencesState preferences, {
    bool notify = true,
  }) async {
    if (notify) {
      await getForegroundService().send(
        SetPreferencesCommand(
          preferences: preferences,
        ),
        awaitable: false,
      );
    }

    // Notify the conversation UI if we changed the background
    if (preferences.backgroundPath != state.backgroundPath) {
      GetIt.I
          .get<ConversationCubit>()
          .onBackgroundChanged(preferences.backgroundPath);
    }

    if (!kDebugMode) {
      final enableDebug = preferences.debugEnabled;
      Logger.root.level = enableDebug ? Level.ALL : Level.INFO;
    }

    emit(preferences);
  }

  Future<void> signOut() async {
    // TODO(Unknown): Only remove the current account
    GetIt.I.get<AccountCubit>().clearAccounts();
    await getForegroundService().send(
      SignOutCommand(),
    );

    // Navigate to the login page but keep the intro page behind it
    GetIt.I.get<NavigationBloc>().add(
          PushedNamedAndRemoveUntilEvent(
            const NavigationDestination(introRoute),
            (_) => false,
          ),
        );
    GetIt.I.get<NavigationBloc>().add(
          PushedNamedEvent(
            const NavigationDestination(loginRoute),
          ),
        );
  }

  Future<void> setBackgroundImage(String path) async {
    if (state.backgroundPath != null) {
      // Invalidate the old entry
      _log.finest('Invalidating cache entry for ${state.backgroundPath}');
      await FileImage(File(state.backgroundPath!)).evict();
    }

    await change(
      state.copyWith(
        backgroundPath: path,
      ),
    );
  }
}
