import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/omemo_device.dart';
import 'package:moxxyv2/ui/bloc/account.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';

part 'own_devices_bloc.freezed.dart';
part 'own_devices_event.dart';
part 'own_devices_state.dart';

class OwnDevicesBloc extends Bloc<OwnDevicesEvent, OwnDevicesState> {
  OwnDevicesBloc() : super(OwnDevicesState()) {
    on<OwnDevicesRequestedEvent>(_onRequested);
    on<OwnDeviceEnabledSetEvent>(_onDeviceEnabledSet);
    on<OwnSessionsRecreatedEvent>(_onSessionsRecreated);
    on<OwnDeviceRemovedEvent>(_onDeviceRemoved);
    on<OwnDeviceRegeneratedEvent>(_onDeviceRegenerated);
    on<DeviceVerifiedEvent>(_onDeviceVerified);
  }

  Future<void> _onRequested(
    OwnDevicesRequestedEvent event,
    Emitter<OwnDevicesState> emit,
  ) async {
    emit(state.copyWith(working: true));

    GetIt.I.get<NavigationBloc>().add(
          PushedNamedEvent(
            const NavigationDestination(ownDevicesRoute),
          ),
        );

    // ignore: cast_nullable_to_non_nullable
    final result = await getForegroundService().send(
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

  Future<void> _onDeviceEnabledSet(
    OwnDeviceEnabledSetEvent event,
    Emitter<OwnDevicesState> emit,
  ) async {
    // ignore: cast_nullable_to_non_nullable
    await getForegroundService().send(
      SetOmemoDeviceEnabledCommand(
        jid: GetIt.I.get<AccountCubit>().state.account.jid,
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

  Future<void> _onSessionsRecreated(
    OwnSessionsRecreatedEvent event,
    Emitter<OwnDevicesState> emit,
  ) async {
    // ignore: cast_nullable_to_non_nullable
    await getForegroundService().send(
      RecreateSessionsCommand(
        jid: GetIt.I.get<AccountCubit>().state.account.jid,
      ),
      awaitable: false,
    );

    GetIt.I.get<NavigationBloc>().add(PoppedRouteEvent());
  }

  Future<void> _onDeviceRemoved(
    OwnDeviceRemovedEvent event,
    Emitter<OwnDevicesState> emit,
  ) async {
    // ignore: cast_nullable_to_non_nullable
    await getForegroundService().send(
      RemoveOwnDeviceCommand(deviceId: event.deviceId),
      awaitable: false,
    );

    emit(
      state.copyWith(
        keys: List.from(
          state.keys.where((key) => key.deviceId != event.deviceId),
        ),
      ),
    );
  }

  Future<void> _onDeviceRegenerated(
    OwnDeviceRegeneratedEvent event,
    Emitter<OwnDevicesState> emit,
  ) async {
    emit(state.copyWith(working: true));

    // ignore: cast_nullable_to_non_nullable
    final result = await getForegroundService().send(
      RegenerateOwnDeviceCommand(),
    ) as RegenerateOwnDeviceResult;

    // Update the UI state
    emit(
      state.copyWith(
        deviceId: result.device.deviceId,
        deviceFingerprint: result.device.fingerprint,
        working: false,
      ),
    );
  }

  Future<void> _onDeviceVerified(
    DeviceVerifiedEvent event,
    Emitter<OwnDevicesState> emit,
  ) async {
    final ownJid = GetIt.I.get<AccountCubit>().state.account.jid;
    final result = isVerificationUriValid(
      state.keys,
      event.uri,
      ownJid,
      event.deviceId,
    );
    if (result == -1) return;

    final newDevices = List<OmemoDevice>.from(state.keys);
    newDevices[result] = newDevices[result].copyWith(
      verified: true,
    );
    emit(state.copyWith(keys: newDevices));

    await getForegroundService().send(
      MarkOmemoDeviceAsVerifiedCommand(
        jid: ownJid,
        deviceId: event.deviceId,
      ),
      awaitable: false,
    );
  }
}
