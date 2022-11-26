part of 'crop_bloc.dart';

@freezed
class CropState with _$CropState {
  factory CropState({
    @Default(null) Uint8List? image,
    @Default(false) bool isWorking,
  }) = _CropState;
}
