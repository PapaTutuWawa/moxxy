import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/omemo_device.dart';
import 'package:moxxyv2/ui/bloc/account.dart';
import 'package:moxxyv2/ui/bloc/navigation.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';

part 'own_devices.freezed.dart';

@freezed
class OwnDevicesState with _$OwnDevicesState {
  factory OwnDevicesState({
    @Default(false) bool working,
    @Default([]) List<OmemoDevice> keys,
    @Default(-1) int deviceId,
    @Default('') String deviceFingerprint,
  }) = _OwnDevicesState;
}

class OwnDevicesCubit extends Cubit<OwnDevicesState> {
  OwnDevicesCubit() : super(OwnDevicesState());

  Future<void> request() async {
    emit(state.copyWith(working: true));

    await GetIt.I.get<Navigation>().pushNamed(
          const NavigationDestination(ownDevicesRoute),
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

  Future<void> setDeviceEnabled(
    int deviceId,
    bool enabled,
  ) async {
    // ignore: cast_nullable_to_non_nullable
    await getForegroundService().send(
      SetOmemoDeviceEnabledCommand(
        jid: GetIt.I.get<AccountCubit>().state.account.jid,
        deviceId: deviceId,
        enabled: enabled,
      ),
      awaitable: false,
    );

    emit(
      state.copyWith(
        keys: state.keys.map((key) {
          if (key.deviceId == deviceId) {
            return key.copyWith(enabled: enabled);
          }

          return key;
        }).toList(),
      ),
    );
  }

  Future<void> recreateSessions() async {
    // ignore: cast_nullable_to_non_nullable
    await getForegroundService().send(
      RecreateSessionsCommand(
        jid: GetIt.I.get<AccountCubit>().state.account.jid,
      ),
      awaitable: false,
    );

    GetIt.I.get<Navigation>().pop();
  }

  Future<void> removeDevice(int deviceId) async {
    // ignore: cast_nullable_to_non_nullable
    await getForegroundService().send(
      RemoveOwnDeviceCommand(deviceId: deviceId),
      awaitable: false,
    );

    emit(
      state.copyWith(
        keys: List.from(
          state.keys.where((key) => key.deviceId != deviceId),
        ),
      ),
    );
  }

  Future<void> regenerateDevice() async {
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

  Future<void> verifyDevice(
    Uri uri,
    int deviceId,
  ) async {
    final ownJid = GetIt.I.get<AccountCubit>().state.account.jid;
    final result = isVerificationUriValid(
      state.keys,
      uri,
      ownJid,
      deviceId,
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
        deviceId: deviceId,
      ),
      awaitable: false,
    );
  }
}
