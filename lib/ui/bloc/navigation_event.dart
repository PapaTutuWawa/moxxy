part of 'navigation_bloc.dart';

class NavigationDestination {

  const NavigationDestination(
    this.path,
    {
      this.arguments,
    }
  );
  final String path;
  final Object? arguments;
}

abstract class NavigationEvent {}

class PushedNamedEvent extends NavigationEvent {

  PushedNamedEvent(this.destination);
  final NavigationDestination destination;
}

class PushedNamedAndRemoveUntilEvent extends NavigationEvent {

  PushedNamedAndRemoveUntilEvent(this.destination, this.predicate);
  final NavigationDestination destination;
  final RoutePredicate predicate;
}

class PushedNamedReplaceEvent extends NavigationEvent {

  PushedNamedReplaceEvent(this.destination);
  final NavigationDestination destination;
}

class PoppedRouteEvent extends NavigationEvent {}
