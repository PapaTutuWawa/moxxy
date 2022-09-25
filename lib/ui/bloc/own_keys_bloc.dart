import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/omemo_key.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';

part 'own_keys_bloc.freezed.dart';
part 'own_keys_event.dart';
part 'own_keys_state.dart';

class OwnKeysBloc extends Bloc<OwnKeysEvent, OwnKeysState> {

  OwnKeysBloc() : super(OwnKeysState()) {
    on<OwnKeysRequestedEvent>(_onRequested);
    on<OwnKeyEnabledSetEvent>(_onKeyEnabledSet);
    on<OwnSessionsRecreatedEvent>(_onSessionsRecreated);
  }

  Future<void> _onRequested(OwnKeysRequestedEvent event, Emitter<OwnKeysState> emit) async {
    emit(state.copyWith(working: true));

    GetIt.I.get<NavigationBloc>().add(
      PushedNamedEvent(
        const NavigationDestination(ownKeysRoute),
      ),
    );

    // ignore: cast_nullable_to_non_nullable
    final result = await MoxplatformPlugin.handler.getDataSender().sendData(
      GetOwnOmemoFingerprintsCommand(),
    ) as GetOwnOmemoFingerprintsResult;
    
    emit(
      state.copyWith(
        working: false,
        deviceFingerprint: result.ownDeviceFingerprint,
        deviceId: result.ownDeviceId,
        keys: result.fingerprints,
      ),
    );
  }
  
  Future<void> _onKeyEnabledSet(OwnKeyEnabledSetEvent event, Emitter<OwnKeysState> emit) async {
    /*
    // ignore: cast_nullable_to_non_nullable
    final result = await MoxplatformPlugin.handler.getDataSender().sendData(
      SetOmemoKeyEnabledCommand(
        jid: state.jid,
        deviceId: event.deviceId,
        enabled: event.enabled,
      ),
    ) as GetConversationOmemoFingerprintsResult;
    emit(state.copyWith(keys: result.fingerprints));
    */
  }

  Future<void> _onSessionsRecreated(OwnSessionsRecreatedEvent event, Emitter<OwnKeysState> emit) async {
    /*
    // ignore: cast_nullable_to_non_nullable
    await MoxplatformPlugin.handler.getDataSender().sendData(
      RecreateSessionsCommand(jid: state.jid),
    );
    emit(state.copyWith(keys: <OmemoKey>[]));

    GetIt.I.get<NavigationBloc>().add(PoppedRouteEvent());
    */
  }
}
