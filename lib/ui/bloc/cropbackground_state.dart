part of 'cropbackground_bloc.dart';

@freezed
class CropBackgroundState with _$CropBackgroundState {
  factory CropBackgroundState({
    @Default('') String imagePath,
    @Default(null) Uint8List? image,
    @Default(false) bool blurEnabled,
    @Default(0) int imageHeight,
    @Default(0) int imageWidth,
  }) = _CropBackgroundState;
}
