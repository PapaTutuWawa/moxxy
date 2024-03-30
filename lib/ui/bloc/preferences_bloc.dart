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
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';

part 'preferences_event.dart';

class PreferencesBloc extends Bloc<PreferencesEvent, PreferencesState> {
  PreferencesBloc()
      : _log = Logger('PreferencesBloc'),
        super(PreferencesState()) {
    on<PreferencesChangedEvent>(_onPreferencesChanged);
    on<SignedOutEvent>(_onSignedOut);
    on<BackgroundImageSetEvent>(_onBackgroundImageSet);
  }
  final Logger _log;

  Future<void> _onPreferencesChanged(
    PreferencesChangedEvent event,
    Emitter<PreferencesState> emit,
  ) async {
    if (event.notify) {
      await getForegroundService().send(
        SetPreferencesCommand(
          preferences: event.preferences,
        ),
        awaitable: false,
      );
    }

    // Notify the conversation UI if we changed the background
    if (event.preferences.backgroundPath != state.backgroundPath) {
      GetIt.I.get<ConversationBloc>().add(
            BackgroundChangedEvent(event.preferences.backgroundPath),
          );
    }

    if (!kDebugMode) {
      final enableDebug = event.preferences.debugEnabled;
      Logger.root.level = enableDebug ? Level.ALL : Level.INFO;
    }

    emit(event.preferences);
  }

  Future<void> _onSignedOut(
    SignedOutEvent event,
    Emitter<PreferencesState> emit,
  ) async {
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

  Future<void> _onBackgroundImageSet(
    BackgroundImageSetEvent event,
    Emitter<PreferencesState> emit,
  ) async {
    if (state.backgroundPath != null) {
      // Invalidate the old entry
      _log.finest('Invalidating cache entry for ${state.backgroundPath}');
      await FileImage(File(state.backgroundPath!)).evict();
    }

    add(
      PreferencesChangedEvent(
        state.copyWith(backgroundPath: event.backgroundPath),
      ),
    );
  }
}
