part of 'preferences_bloc.dart';

abstract class PreferencesEvent {}

/// Triggered by the UI when a preference has been changed.
/// If [notify] is true, then the background service will be
/// notified of this change.
class PreferencesChangedEvent extends PreferencesEvent {
  PreferencesChangedEvent(this.preferences, {
    this.notify = true,
  });
  final PreferencesState preferences;
  final bool notify;
}

/// Triggered by the UI when signing out is requested
class SignedOutEvent extends PreferencesEvent {}

/// Triggered when a background image has been set
class BackgroundImageSetEvent extends PreferencesEvent {
  BackgroundImageSetEvent(this.backgroundPath);
  final String backgroundPath;
}
