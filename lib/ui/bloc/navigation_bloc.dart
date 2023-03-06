import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'navigation_bloc.freezed.dart';
part 'navigation_event.dart';
part 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc({required this.navigationKey}) : super(NavigationState()) {
    on<PushedNamedEvent>(_onPushedNamed);
    on<PushedNamedAndRemoveUntilEvent>(_onPushedNamedAndRemoveUntil);
    on<PushedNamedReplaceEvent>(_onPushedNamedReplaceEvent);
    on<PoppedRouteEvent>(_onPoppedRoute);
  }
  final GlobalKey<NavigatorState> navigationKey;

  Future<void> _onPushedNamed(
      PushedNamedEvent event,
      Emitter<NavigationState> emit,
    ) async {
    await navigationKey.currentState!.pushNamed(
      event.destination.path,
      arguments: event.destination.arguments,
    );
  }

  Future<void> _onPushedNamedAndRemoveUntil(
      PushedNamedAndRemoveUntilEvent event,
      Emitter<NavigationState> emit,
    ) async {
    await navigationKey.currentState!.pushNamedAndRemoveUntil(
      event.destination.path,
      event.predicate,
      arguments: event.destination.arguments,
    );
  }

  Future<void> _onPushedNamedReplaceEvent(
      PushedNamedReplaceEvent event,
      Emitter<NavigationState> emit,
    ) async {
    await navigationKey.currentState!.pushReplacementNamed(
      event.destination.path,
      arguments: event.destination.arguments,
    );
  }

  Future<void> _onPoppedRoute(
      PoppedRouteEvent event,
      Emitter<NavigationState> emit,
    ) async {
    navigationKey.currentState!.pop();
  }

  bool canPop() {
    return navigationKey.currentState!.canPop();
  }
}
