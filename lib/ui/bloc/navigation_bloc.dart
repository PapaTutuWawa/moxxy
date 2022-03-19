import "package:bloc/bloc.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "navigation_state.dart";
part "navigation_event.dart";
part "navigation_bloc.freezed.dart";

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc() : super(NavigationState()) {
    on<NavigatedToEvent>(_onNavigatedTo);
  }

  Future<void> _onNavigatedTo(NavigatedToEvent event, Emitter<NavigationState> emit) async {
    return emit(state.copyWith(status: event.status));
  }
}
