import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/omemo_device.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';

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

  Future<void> _onRequested(DevicesRequestedEvent event, Emitter<DevicesState> emit) async {
    emit(state.copyWith(working: true, jid: event.jid));

    GetIt.I.get<NavigationBloc>().add(
      PushedNamedEvent(
        const NavigationDestination(devicesRoute),
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
        devices: result.fingerprints,
      ),
    );
  }

  Future<void> _onDeviceEnabledSet(DeviceEnabledSetEvent event, Emitter<DevicesState> emit) async {
    // ignore: cast_nullable_to_non_nullable
    final result = await MoxplatformPlugin.handler.getDataSender().sendData(
      SetOmemoDeviceEnabledCommand(
        jid: state.jid,
        deviceId: event.deviceId,
        enabled: event.enabled,
      ),
    ) as GetConversationOmemoFingerprintsResult;
    emit(state.copyWith(devices: result.fingerprints));  
  }

  Future<void> _onSessionsRecreated(SessionsRecreatedEvent event, Emitter<DevicesState> emit) async {
    // ignore: cast_nullable_to_non_nullable
    await MoxplatformPlugin.handler.getDataSender().sendData(
      RecreateSessionsCommand(jid: state.jid),
      awaitable: false,
    );
    emit(state.copyWith(devices: <OmemoDevice>[]));

    GetIt.I.get<NavigationBloc>().add(PoppedRouteEvent());
  }

  Future<void> _onDeviceVerified(DeviceVerifiedEvent event, Emitter<DevicesState> emit) async {
    if (event.uri.queryParameters.isEmpty) {
      // No query parameters
      // TODO(PapaTutuWawa): Show a toast
      return;
    }

    final jid = event.uri.path;
    if (state.jid != jid) {
      // The Jid is wrong
      // TODO(PapaTutuWawa): Show a toast
      return;
    }

    // TODO(PapaTutuWawa): Use an exception safe version of firstWhere
    // TODO(PapaTutuWawa): Is omemo-sid-xxxxxx correct? Siacs OMEMO uses this
    final sidParam = event.uri.queryParameters
      .keys
      .firstWhere((param) => param.startsWith('omemo-sid-'));
    final deviceId = int.parse(sidParam.replaceFirst('omemo-sid-', ''));
    final fp = event.uri.queryParameters[sidParam];

    if (deviceId != event.deviceId) {
      // The scanned device has the wrong Id
      // TODO(PapaTutuWawa): Show a toast
      return;
    }

    final index = state.devices.indexWhere((device) => device.deviceId == deviceId);
    if (index == -1) {
      // The device is not in the list
      // TODO(PapaTutuWawa): Show a toast
      return;
    }

    final device = state.devices[index];
    if (device.fingerprint != fp) {
      // The fingerprint is not what we expected
      // TODO(PapaTutuWawa): Show a toast
      return;
    }

    final devices = List<OmemoDevice>.from(state.devices);
    devices[index] = devices[index].copyWith(
      verified: true,
    );
    emit(state.copyWith(devices: devices));
    
    await MoxplatformPlugin.handler.getDataSender().sendData(
      MarkOmemoDeviceAsVerifiedCommand(
        jid: state.jid,
        deviceId: event.deviceId,
      ),
      awaitable: false,
    );
  }
}
