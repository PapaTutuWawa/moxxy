part of "preferences_bloc.dart";

abstract class PreferencesEvent {}

/// Triggered by the UI when a preference has been changed
class PreferencesChangedEvent extends PreferencesEvent {
  final PreferencesState preferences;

  PreferencesChangedEvent(this.preferences);
}
