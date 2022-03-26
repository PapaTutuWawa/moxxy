part of "preferences_bloc.dart";

abstract class PreferencesEvent {}

/// Triggered by the UI when a preference has been changed.
/// If [notify] is true, then the background service will be
/// notified of this change.
class PreferencesChangedEvent extends PreferencesEvent {
  final PreferencesState preferences;
  final bool notify;

  PreferencesChangedEvent(this.preferences, { this.notify = true });
}
