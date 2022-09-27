import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/omemo_key.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/service/data.dart';

part 'own_keys_bloc.freezed.dart';
part 'own_keys_event.dart';
part 'own_keys_state.dart';

class OwnKeysBloc extends Bloc<OwnKeysEvent, OwnKeysState> {

  OwnKeysBloc() : super(OwnKeysState()) {
    on<OwnKeysRequestedEvent>(_onRequested);
    on<OwnKeyEnabledSetEvent>(_onKeyEnabledSet);
    on<OwnSessionsRecreatedEvent>(_onSessionsRecreated);
    on<OwnDeviceRemovedEvent>(_onDeviceRemoved);
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
    // ignore: cast_nullable_to_non_nullable
    await MoxplatformPlugin.handler.getDataSender().sendData(
      SetOmemoKeyEnabledCommand(
        jid: GetIt.I.get<UIDataService>().ownJid!,
        deviceId: event.deviceId,
        enabled: event.enabled,
      ),
      awaitable: false,
    );

    emit(
      state.copyWith(
        keys: state.keys.map((key) {
          if (key.deviceId == event.deviceId) {
            return key.copyWith(enabled: event.enabled);
          }

          return key;
        }).toList(),
      ),
    );
  }

  Future<void> _onSessionsRecreated(OwnSessionsRecreatedEvent event, Emitter<OwnKeysState> emit) async {
    // ignore: cast_nullable_to_non_nullable
    await MoxplatformPlugin.handler.getDataSender().sendData(
      RecreateSessionsCommand(jid: GetIt.I.get<UIDataService>().ownJid!),
      awaitable: false,
    );
    emit(
      state.copyWith(
        keys: List.from(
          state.keys.map((key) => key.copyWith(
            hasSessionWith: false,
          ),),
        ),
      ),
    );

    GetIt.I.get<NavigationBloc>().add(PoppedRouteEvent());
  }

  Future<void> _onDeviceRemoved(OwnDeviceRemovedEvent event, Emitter<OwnKeysState> emit) async {
    // ignore: cast_nullable_to_non_nullable
    await MoxplatformPlugin.handler.getDataSender().sendData(
      RemoveOwnDeviceCommand(deviceId: event.deviceId),
      awaitable: false,
    );

    emit(
      state.copyWith(
        keys: List.from(
          state.keys
            .where((key) => key.deviceId != event.deviceId),
        ),
      ),
    );
  }
}
