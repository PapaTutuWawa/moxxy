part of "crop_bloc.dart";

abstract class CropEvent {}

class ImageCroppedEvent extends CropEvent {
  final Uint8List image;

  ImageCroppedEvent(this.image);
}

class ResetImageEvent extends CropEvent {}

class SetImageEvent extends CropEvent {
  final Uint8List image;

  SetImageEvent(this.image);
}

class CropState {
  final Uint8List? image;

  CropState(this.image);
}
