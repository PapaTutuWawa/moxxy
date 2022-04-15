import "dart:async";
import "dart:io";
import "dart:typed_data";

import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/bloc/navigation_bloc.dart";

import "package:get_it/get_it.dart";
import "package:bloc/bloc.dart";

part "crop_event.dart";

class CropBloc extends Bloc<CropEvent, CropState> {
  late Completer<Uint8List?> _completer;

  CropBloc() : super(CropState(null)) {
    on<ImageCroppedEvent>(_onImageCropped);
    on<ResetImageEvent>(_onImageReset);
    on<SetImageEvent>(_onImageSet);
  }

  Future<void> _onImageCropped(ImageCroppedEvent event, Emitter<CropState> emit) async {
    _completer.complete(event.image);

    GetIt.I.get<NavigationBloc>().add(PoppedRouteEvent());
    
    emit(CropState(null));
  }

  Future<void> _onImageReset(ResetImageEvent event, Emitter<CropState> emit) async {
    emit(CropState(null));
  }

  Future<void> _onImageSet(SetImageEvent event, Emitter<CropState> emit) async {
    emit(CropState(event.image));
  }
  
  Future<void> _performCropping(String path) async {
    final file = File(path);
    if (!await file.exists()) _completer.complete(null);

    final bytes = await file.readAsBytes();

    add(SetImageEvent(bytes));
  }

  /// User-callable function. Loads the image, navigates to the page
  /// and allows the user to crop the image. The future resolves when
  /// either an error occures or the image has been cropped.
  /// [path] is the path to the file to load.
  Future<Uint8List?> cropImage(String path) {
    _completer = Completer();

    add(ResetImageEvent());
    GetIt.I.get<NavigationBloc>().add(
      PushedNamedEvent(
        const NavigationDestination(cropRoute)
      )
    );   
    _performCropping(path);

    return _completer.future;
  }

  /// User-callable function. Loads the image, navigates to the page
  /// and allows the user to crop the image. The future resolves when
  /// either an error occures or the image has been cropped.
  /// [path] is the path to the file to load.
  Future<Uint8List?> cropImageWithData(Uint8List data) {
    _completer = Completer();

    GetIt.I.get<NavigationBloc>().add(
      PushedNamedEvent(
        const NavigationDestination(cropRoute)
      )
    );

    add(SetImageEvent(data));
    
    return _completer.future;
  }
}
