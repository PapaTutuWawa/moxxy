part of "navigation_bloc.dart";

class NavigationDestination {
  final String path;
  final Object? arguments;

  const NavigationDestination(
    this.path,
    {
      this.arguments
    }
  );
}

abstract class NavigationEvent {}

class PushedNamedEvent extends NavigationEvent {
  final NavigationDestination destination;

  PushedNamedEvent(this.destination);
}

class PushedNamedAndRemoveUntilEvent extends NavigationEvent {
  final NavigationDestination destination;
  final RoutePredicate predicate;

  PushedNamedAndRemoveUntilEvent(this.destination, this.predicate);
}

class PushedNamedReplaceEvent extends NavigationEvent {
  final NavigationDestination destination;

  PushedNamedReplaceEvent(this.destination);
}
