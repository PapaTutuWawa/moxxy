part of 'request_bloc.dart';

@freezed
class RequestState with _$RequestState {
  const factory RequestState({
    @Default([]) List<Request> requests,
    @Default(0) int currentIndex,
    @Default(false) bool shouldShow,
  }) = _RequestState;
}
