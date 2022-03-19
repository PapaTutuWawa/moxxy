part of "navigation_bloc.dart";

abstract class NavigationEvent {}

class NavigatedToEvent extends NavigationEvent {
  final NavigationStatus status;

  NavigatedToEvent(this.status);
}
