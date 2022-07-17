part of 'sharedmedia_bloc.dart';

@freezed
class SharedMediaState with _$SharedMediaState {
  factory SharedMediaState({
    @Default('') String title,
    @Default('') String jid,
    @Default(<SharedMedium>[]) List<SharedMedium> sharedMedia,
  }) = _SharedMediaState;
}
