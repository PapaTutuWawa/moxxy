import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NavigationDestination {
  const NavigationDestination(
    this.path, {
    this.arguments,
  });
  final String path;
  final Object? arguments;
}

class Navigation {
  Navigation({required this.navigationKey});

  final GlobalKey<NavigatorState> navigationKey;

  void pushNamed(NavigationDestination destination) {
    navigationKey.currentState!.pushNamed(
      destination.path,
      arguments: destination.arguments,
    );
  }

  void pushNamedAndRemoveUntil(
    NavigationDestination destination,
    RoutePredicate predicate,
  ) {
    navigationKey.currentState!.pushNamedAndRemoveUntil(
      destination.path,
      predicate,
      arguments: destination.arguments,
    );
  }

  void pushNamedReplace(
    NavigationDestination destination,
  ) {
    navigationKey.currentState!.pushReplacementNamed(
      destination.path,
      arguments: destination.arguments,
    );
  }

  void pop() {
    navigationKey.currentState!.pop();
  }

  bool canPop() {
    return navigationKey.currentState!.canPop();
  }

  void popWithSystemNavigator() {
    if (!canPop()) {
      SystemNavigator.pop();
      return;
    }

    pop();
  }
}
