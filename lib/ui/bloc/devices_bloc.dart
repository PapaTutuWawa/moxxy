import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/omemo_device.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';

part 'devices_bloc.freezed.dart';
part 'devices_event.dart';
part 'devices_state.dart';

class DevicesBloc extends Bloc<DevicesEvent, DevicesState> {
  DevicesBloc() : super(DevicesState()) {
    on<DevicesRequestedEvent>(_onRequested);
    on<DeviceEnabledSetEvent>(_onDeviceEnabledSet);
    on<SessionsRecreatedEvent>(_onSessionsRecreated);
    on<DeviceVerifiedEvent>(_onDeviceVerified);
  }

  Future<void> _onRequested(
    DevicesRequestedEvent event,
    Emitter<DevicesState> emit,
  ) async {
    emit(state.copyWith(working: true, jid: event.jid));

    GetIt.I.get<NavigationBloc>().add(
          PushedNamedEvent(
            const NavigationDestination(devicesRoute),
          ),
        );

    // ignore: cast_nullable_to_non_nullable
    final result = await getForegroundService().send(
      GetConversationOmemoFingerprintsCommand(
        jid: event.jid,
      ),
    ) as GetConversationOmemoFingerprintsResult;

    emit(
      state.copyWith(
        working: false,
        devices: result.fingerprints,
      ),
    );
  }

  Future<void> _onDeviceEnabledSet(
    DeviceEnabledSetEvent event,
    Emitter<DevicesState> emit,
  ) async {
    // ignore: cast_nullable_to_non_nullable
    final result = await getForegroundService().send(
      SetOmemoDeviceEnabledCommand(
        jid: state.jid,
        deviceId: event.deviceId,
        enabled: event.enabled,
      ),
    ) as GetConversationOmemoFingerprintsResult;
    emit(state.copyWith(devices: result.fingerprints));
  }

  Future<void> _onSessionsRecreated(
    SessionsRecreatedEvent event,
    Emitter<DevicesState> emit,
  ) async {
    // ignore: cast_nullable_to_non_nullable
    await getForegroundService().send(
      RecreateSessionsCommand(jid: state.jid),
      awaitable: false,
    );
    emit(state.copyWith(devices: <OmemoDevice>[]));

    GetIt.I.get<NavigationBloc>().add(PoppedRouteEvent());
  }

  Future<void> _onDeviceVerified(
    DeviceVerifiedEvent event,
    Emitter<DevicesState> emit,
  ) async {
    final result = isVerificationUriValid(
      state.devices,
      event.uri,
      state.jid,
      event.deviceId,
    );
    if (result == -1) return;

    final devices = List<OmemoDevice>.from(state.devices);
    devices[result] = devices[result].copyWith(
      verified: true,
    );
    emit(state.copyWith(devices: devices));

    await getForegroundService().send(
      MarkOmemoDeviceAsVerifiedCommand(
        jid: state.jid,
        deviceId: event.deviceId,
      ),
      awaitable: false,
    );
  }
}
