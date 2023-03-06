part of 'cropbackground_bloc.dart';

abstract class CropBackgroundEvent {}

class CropBackgroundRequestedEvent extends CropBackgroundEvent {
  CropBackgroundRequestedEvent(this.path);
  final String path;
}

class CropBackgroundResetEvent extends CropBackgroundEvent {}

class BlurToggledEvent extends CropBackgroundEvent {}

class BackgroundSetEvent extends CropBackgroundEvent {
  BackgroundSetEvent(
      this.x, this.y, this.q, this.viewportHeight, this.viewportWidth);
  final double x;
  final double y;
  final double q;
  final double viewportHeight;
  final double viewportWidth;
}
