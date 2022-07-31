part of 'cropbackground_bloc.dart';

@freezed
class CropBackgroundState with _$CropBackgroundState {
  factory CropBackgroundState({
    @Default('') String imagePath,
    @Default(null) Uint8List? image,
    @Default(false) bool blurEnabled,
  }) = _CropBackgroundState;
}
