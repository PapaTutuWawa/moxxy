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
    on<OwnKeysRequestedEvent>(_onOwnKeysRequested);
    on<KeyEnabledSetEvent>(_onKeyEnabledSet);
    on<SessionsRecreatedEvent>(_onSessionsRecreated);
  }

  Future<void> _onRequested(KeysRequestedEvent event, Emitter<KeysState> emit) async {
    emit(state.copyWith(working: true, jid: event.jid));

    GetIt.I.get<NavigationBloc>().add(
      PushedNamedEvent(
        const NavigationDestination(keysRoute),
      ),
    );

    // ignore: cast_nullable_to_non_nullable
    final result = await MoxplatformPlugin.handler.getDataSender().sendData(
      GetConversationOmemoFingerprintsCommand(
        jid: event.jid,
      ),
    ) as GetConversationOmemoFingerprintsResult;
    
    emit(
      state.copyWith(
        working: false,
        keys: result.fingerprints,
      ),
    );
  }

  Future<void> _onOwnKeysRequested(OwnKeysRequestedEvent event, Emitter<KeysState> emit) async {
    emit(state.copyWith(working: true, jid: ''));

    GetIt.I.get<NavigationBloc>().add(
      PushedNamedEvent(
        const NavigationDestination(keysRoute),
      ),
    );

    // ignore: cast_nullable_to_non_nullable
    final result = await MoxplatformPlugin.handler.getDataSender().sendData(
      GetOwnOmemoFingerprintsCommand(),
    ) as GetOwnOmemoFingerprintsResult;

    emit(
      state.copyWith(
        working: false,
        //keys: result.fingerprints,
      ),
    );
  }
  
  Future<void> _onKeyEnabledSet(KeyEnabledSetEvent event, Emitter<KeysState> emit) async {
    // ignore: cast_nullable_to_non_nullable
    final result = await MoxplatformPlugin.handler.getDataSender().sendData(
      SetOmemoKeyEnabledCommand(
        jid: state.jid,
        deviceId: event.deviceId,
        enabled: event.enabled,
      ),
    ) as GetConversationOmemoFingerprintsResult;
    emit(state.copyWith(keys: result.fingerprints));  
  }

  Future<void> _onSessionsRecreated(SessionsRecreatedEvent event, Emitter<KeysState> emit) async {
    // ignore: cast_nullable_to_non_nullable
    await MoxplatformPlugin.handler.getDataSender().sendData(
      RecreateSessionsCommand(jid: state.jid),
    );
    emit(state.copyWith(keys: <OmemoKey>[]));

    GetIt.I.get<NavigationBloc>().add(PoppedRouteEvent());
  }
}
