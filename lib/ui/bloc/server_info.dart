import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/ui/bloc/navigation.dart';
import 'package:moxxyv2/ui/constants.dart';

part 'server_info.freezed.dart';

@freezed
class ServerInfoState with _$ServerInfoState {
  factory ServerInfoState({
    @Default(true) bool working,
    @Default(false) bool streamManagementSupported,
    @Default(false) bool userBlockingSupported,
    @Default(false) bool httpFileUploadSupported,
    @Default(false) bool csiSupported,
    @Default(false) bool carbonsSupported,
  }) = _ServerInfoState;
}

class ServerInfoCubit extends Cubit<ServerInfoState> {
  ServerInfoCubit() : super(ServerInfoState());

  Future<void> request() async {
    emit(state.copyWith(working: true));

    GetIt.I.get<Navigation>().pushNamed(
          const NavigationDestination(serverInfoRoute),
        );

    // ignore: cast_nullable_to_non_nullable
    final result = await getForegroundService().send(
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
