import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/omemo_key.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';


part 'keys_bloc.freezed.dart';
part 'keys_event.dart';
part 'keys_state.dart';

class KeysBloc extends Bloc<KeysEvent, KeysState> {

  KeysBloc() : super(KeysState()) {
    on<KeysRequestedEvent>(_onRequested);
  }

  Future<void> _onRequested(KeysRequestedEvent event, Emitter<KeysState> emit) async {
    emit(state.copyWith(working: true));

    GetIt.I.get<NavigationBloc>().add(
      PushedNamedEvent(
        const NavigationDestination(keysRoute),
      ),
    );
    
    emit(
      state.copyWith(
        working: false,
        keys: <OmemoKey>[
          OmemoKey('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'),
          OmemoKey('bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'),
        ],
      ),
    );
  }
}
