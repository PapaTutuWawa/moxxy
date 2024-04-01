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

part 'devices.freezed.dart';

@freezed
class DevicesState with _$DevicesState {
  factory DevicesState({
    @Default(false) bool working,
    @Default([]) List<OmemoDevice> devices,
    @Default('') String jid,
  }) = _DevicesState;
}

class DevicesCubit extends Cubit<DevicesState> {
  DevicesCubit() : super(DevicesState());

  Future<void> request(String jid) async {
    emit(state.copyWith(working: true, jid: jid));

    GetIt.I.get<NavigationBloc>().add(
          PushedNamedEvent(
            const NavigationDestination(devicesRoute),
          ),
        );

    // ignore: cast_nullable_to_non_nullable
    final result = await getForegroundService().send(
      GetConversationOmemoFingerprintsCommand(
        jid: jid,
      ),
    ) as GetConversationOmemoFingerprintsResult;

    emit(
      state.copyWith(
        working: false,
        devices: result.fingerprints,
      ),
    );
  }

  Future<void> setDeviceEnabled(
    int deviceId,
    bool enabled,
  ) async {
    // ignore: cast_nullable_to_non_nullable
    final result = await getForegroundService().send(
      SetOmemoDeviceEnabledCommand(
        jid: state.jid,
        deviceId: deviceId,
        enabled: enabled,
      ),
    ) as GetConversationOmemoFingerprintsResult;
    emit(state.copyWith(devices: result.fingerprints));
  }

  Future<void> recreateSessions() async {
    // ignore: cast_nullable_to_non_nullable
    await getForegroundService().send(
      RecreateSessionsCommand(jid: state.jid),
      awaitable: false,
    );
    emit(state.copyWith(devices: <OmemoDevice>[]));

    GetIt.I.get<NavigationBloc>().add(PoppedRouteEvent());
  }

  Future<void> verifyDevice(
    Uri uri,
    int deviceId,
  ) async {
    final result = isVerificationUriValid(
      state.devices,
      uri,
      state.jid,
      deviceId,
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
        deviceId: deviceId,
      ),
      awaitable: false,
    );
  }
}
