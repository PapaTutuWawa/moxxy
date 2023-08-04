import 'package:bloc/bloc.dart';
import 'package:moxxyv2/i18n/strings.g.dart';

// TODO: Split this up into multiple files.

enum Request {
  notifications,
  batterySavingExcemption;

  /// Return a localized reason to display for a given request.
  String get reason {
    switch (this) {
      case notifications:
        return t.permissions.requests.notification.reason;
      case batterySavingExcemption:
        return t.permissions.requests.batterySaving.reason;
    }
  }
}

abstract class RequestBlocEvent {}

class RequestsSetEvent extends RequestBlocEvent {
  RequestsSetEvent(this.requests);

  final List<Request> requests;
}

class NextRequestEvent extends RequestBlocEvent {}

class ResetRequestEvent extends RequestBlocEvent {}

class RequestBlocState {
  const RequestBlocState({
    required this.requests,
    required this.currentIndex,
    required this.shouldShow,
  });

  factory RequestBlocState.initial() =>
      const RequestBlocState(requests: [], currentIndex: 0, shouldShow: false);

  final bool shouldShow;
  final List<Request> requests;
  final int currentIndex;

  RequestBlocState copyWith({
    List<Request>? requests,
    int? currentIndex,
    bool? shouldShow,
  }) {
    return RequestBlocState(
      requests: requests ?? this.requests,
      currentIndex: currentIndex ?? this.currentIndex,
      shouldShow: shouldShow ?? this.shouldShow,
    );
  }
}

class RequestBloc extends Bloc<RequestBlocEvent, RequestBlocState> {
  RequestBloc() : super(RequestBlocState.initial()) {
    on<RequestsSetEvent>(_onRequestsSet);
    on<NextRequestEvent>(_onNextRequest);
    on<ResetRequestEvent>(_onReset);
  }

  Future<void> _onRequestsSet(
    RequestsSetEvent event,
    Emitter<RequestBlocState> emit,
  ) async {
    emit(
      state.copyWith(
        requests: event.requests,
        currentIndex: 0,
        shouldShow: true,
      ),
    );
  }

  Future<void> _onNextRequest(
    NextRequestEvent event,
    Emitter<RequestBlocState> emit,
  ) async {
    if (state.currentIndex + 1 >= state.requests.length) {
      return _onReset(ResetRequestEvent(), emit);
    }

    emit(
      state.copyWith(
        currentIndex: state.currentIndex + 1,
      ),
    );
  }

  Future<void> _onReset(
    ResetRequestEvent event,
    Emitter<RequestBlocState> emit,
  ) async {
    emit(
      state.copyWith(
        requests: [],
        currentIndex: 0,
        shouldShow: false,
      ),
    );
  }
}
