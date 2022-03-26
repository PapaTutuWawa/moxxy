import "package:moxxyv2/shared/preferences.dart";
import "package:moxxyv2/shared/commands.dart";
import "package:moxxyv2/shared/backgroundsender.dart";

import "package:bloc/bloc.dart";
import "package:get_it/get_it.dart";

part "preferences_event.dart";

class PreferencesBloc extends Bloc<PreferencesEvent, PreferencesState> {
  PreferencesBloc() : super(PreferencesState()) {
    on<PreferencesChangedEvent>(_onPreferencesChanged);
  }

  Future<void> _onPreferencesChanged(PreferencesChangedEvent event, Emitter<PreferencesState> emit) async {
    GetIt.I.get<BackgroundServiceDataSender>().sendData(
      SetPreferencesCommand(
        preferences: state
      ),
      awaitable: false
    );

    emit(event.preferences);
  }
}
