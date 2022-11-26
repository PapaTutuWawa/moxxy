part of 'crop_bloc.dart';

abstract class CropEvent {}

class ImageCroppedEvent extends CropEvent {}

class ResetImageEvent extends CropEvent {}

class SetImageEvent extends CropEvent {
  SetImageEvent(this.image);
  final Uint8List image;
}
