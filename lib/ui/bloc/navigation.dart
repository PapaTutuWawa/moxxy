import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'navigation.freezed.dart';

class NavigationDestination {
  const NavigationDestination(
    this.path, {
    this.arguments,
  });
  final String path;
  final Object? arguments;
}

enum NavigationStatus {
  splashscreen,
  intro,
  login
//  conversations
}

@freezed
class NavigationState with _$NavigationState {
  factory NavigationState({
    @Default(NavigationStatus.intro) NavigationStatus status,
  }) = _NavigationState;
}

class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit({required this.navigationKey}) : super(NavigationState());

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
