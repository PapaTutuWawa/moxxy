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

  Future<void> pushNamed(
    NavigationDestination destination,
  ) async {
    await navigationKey.currentState!.pushNamed(
      destination.path,
      arguments: destination.arguments,
    );
  }

  Future<void> pushNamedAndRemoveUntil(
    NavigationDestination destination,
    RoutePredicate predicate,
  ) async {
    await navigationKey.currentState!.pushNamedAndRemoveUntil(
      destination.path,
      predicate,
      arguments: destination.arguments,
    );
  }

  Future<void> pushNamedReplace(
    NavigationDestination destination,
  ) async {
    await navigationKey.currentState!.pushReplacementNamed(
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

  Future<void> popWithSystemNavigator() async {
    if (!canPop()) {
      await SystemNavigator.pop();
      return;
    }

    pop();
  }
}
