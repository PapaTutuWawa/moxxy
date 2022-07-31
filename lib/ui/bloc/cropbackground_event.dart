part of 'cropbackground_bloc.dart';

abstract class CropBackgroundEvent {}

class CropBackgroundRequestedEvent extends CropBackgroundEvent {

  CropBackgroundRequestedEvent(this.path);
  final String path;
}

class CropBackgroundResetEvent extends CropBackgroundEvent {}

class BlurToggledEvent extends CropBackgroundEvent {}

class BackgroundSetEvent extends CropBackgroundEvent {

  BackgroundSetEvent(this.image);
  final Uint8List image;
}
