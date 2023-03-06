import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';

part 'server_info_bloc.freezed.dart';
part 'server_info_event.dart';
part 'server_info_state.dart';

class ServerInfoBloc extends Bloc<ServerInfoEvent, ServerInfoState> {
  ServerInfoBloc() : super(ServerInfoState()) {
    on<ServerInfoPageRequested>(_onServerInfoRequested);
  }

  Future<void> _onServerInfoRequested(
    ServerInfoPageRequested event,
    Emitter<ServerInfoState> emit,
  ) async {
    emit(state.copyWith(working: true));

    GetIt.I.get<NavigationBloc>().add(
          PushedNamedEvent(const NavigationDestination(serverInfoRoute)),
        );

    // ignore: cast_nullable_to_non_nullable
    final result = await MoxplatformPlugin.handler.getDataSender().sendData(
          GetFeaturesCommand(),
        ) as GetFeaturesEvent;

    emit(
      state.copyWith(
        streamManagementSupported: result.supportsStreamManagement,
        csiSupported: result.supportsCsi,
        httpFileUploadSupported: result.supportsHttpFileUpload,
        userBlockingSupported: result.supportsUserBlocking,
        carbonsSupported: result.supportsCarbons,
        working: false,
      ),
    );
  }
}
