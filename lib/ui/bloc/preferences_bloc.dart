import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/models/preferences.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/service/data.dart';

part 'preferences_event.dart';

class PreferencesBloc extends Bloc<PreferencesEvent, PreferencesState> {
  PreferencesBloc() : _log = Logger('PreferencesBloc'), super(PreferencesState()) {
    on<PreferencesChangedEvent>(_onPreferencesChanged);
    on<SignedOutEvent>(_onSignedOut);
    on<BackgroundImageSetEvent>(_onBackgroundImageSet);
  }
  final Logger _log;
  
  Future<void> _onPreferencesChanged(PreferencesChangedEvent event, Emitter<PreferencesState> emit) async {
    if (event.notify) {
      await MoxplatformPlugin.handler.getDataSender().sendData(
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

  Future<void> _onSignedOut(SignedOutEvent event, Emitter<PreferencesState> emit) async {
    GetIt.I.get<UIDataService>().isLoggedIn = false;

    await MoxplatformPlugin.handler.getDataSender().sendData(
      SignOutCommand(),
    );

    GetIt.I.get<NavigationBloc>().add(
      PushedNamedAndRemoveUntilEvent(
        const NavigationDestination(loginRoute),
        (_) => false,
      ),
    );
  }

  Future<void> _onBackgroundImageSet(BackgroundImageSetEvent event, Emitter<PreferencesState> emit) async {
    if (state.backgroundPath.isNotEmpty) {
      // Invalidate the old entry
      _log.finest('Invalidating cache entry for ${state.backgroundPath}');
      await FileImage(File(state.backgroundPath)).evict();
    }
    
    add(
      PreferencesChangedEvent(
        state.copyWith(backgroundPath: event.backgroundPath),
      ),
    );
  }
}
