import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxxyv2/i18n/strings.g.dart';

part 'request_bloc.freezed.dart';
part 'request_event.dart';
part 'request_state.dart';

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

class RequestBloc extends Bloc<RequestEvent, RequestState> {
  RequestBloc() : super(const RequestState()) {
    on<RequestsSetEvent>(_onRequestsSet);
    on<NextRequestEvent>(_onNextRequest);
    on<ResetRequestEvent>(_onReset);
  }

  Future<void> _onRequestsSet(
    RequestsSetEvent event,
    Emitter<RequestState> emit,
  ) async {
    emit(
      state.copyWith(
        requests: event.requests,
        currentIndex: 0,
        shouldShow: event.requests.isNotEmpty,
      ),
    );
  }

  Future<void> _onNextRequest(
    NextRequestEvent event,
    Emitter<RequestState> emit,
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
    Emitter<RequestState> emit,
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
