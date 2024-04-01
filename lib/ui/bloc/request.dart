import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxxyv2/i18n/strings.g.dart';

part 'request.freezed.dart';

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

@freezed
class RequestState with _$RequestState {
  const factory RequestState({
    @Default([]) List<Request> requests,
    @Default(0) int currentIndex,
    @Default(false) bool shouldShow,
  }) = _RequestState;
}

class RequestCubit extends Cubit<RequestState> {
  RequestCubit() : super(const RequestState());

  void setRequests(
    List<Request> requests,
  ) {
    emit(
      state.copyWith(
        requests: requests,
        currentIndex: 0,
        shouldShow: requests.isNotEmpty,
      ),
    );
  }

  void nextRequest() {
    if (state.currentIndex + 1 >= state.requests.length) {
      reset();
      return;
    }

    emit(
      state.copyWith(
        currentIndex: state.currentIndex + 1,
      ),
    );
  }

  void reset() {
    emit(
      state.copyWith(
        requests: [],
        currentIndex: 0,
        shouldShow: false,
      ),
    );
  }
}
