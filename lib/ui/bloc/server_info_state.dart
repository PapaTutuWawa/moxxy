part of 'server_info_bloc.dart';

@freezed
class ServerInfoState with _$ServerInfoState {
  factory ServerInfoState({
    @Default(true) bool working,
    @Default(false) bool streamManagementSupported,
    @Default(false) bool userBlockingSupported,
    @Default(false) bool httpFileUploadSupported,
    @Default(false) bool csiSupported,
  }) = _ServerInfoState;
}
