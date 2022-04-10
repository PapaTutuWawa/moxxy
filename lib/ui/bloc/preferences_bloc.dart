import "package:moxxyv2/ui/bloc/conversation_bloc.dart";
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
    if (event.notify) {
      GetIt.I.get<BackgroundServiceDataSender>().sendData(
        SetPreferencesCommand(
          preferences: event.preferences
        ),
        awaitable: false
      );
    }

    // Notify the conversation UI if we changed the background
    if (event.preferences.backgroundPath != state.backgroundPath) {
      GetIt.I.get<ConversationBloc>().add(
        BackgroundChangedEvent(event.preferences.backgroundPath)
      );
    }

    emit(event.preferences);
  }
}
