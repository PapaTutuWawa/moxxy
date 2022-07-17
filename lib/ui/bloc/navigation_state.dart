part of 'navigation_bloc.dart';

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
