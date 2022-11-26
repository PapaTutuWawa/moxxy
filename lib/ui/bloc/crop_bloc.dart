import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:cropperx/cropperx.dart';
import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';

part 'crop_bloc.freezed.dart';
part 'crop_event.dart';
part 'crop_state.dart';

class CropBloc extends Bloc<CropEvent, CropState> {
  CropBloc() : super(CropState()) {
    on<ImageCroppedEvent>(_onImageCropped);
    on<ResetImageEvent>(_onImageReset);
    on<SetImageEvent>(_onImageSet);
  }
  late Completer<Uint8List?> _completer;
  final GlobalKey cropKey = GlobalKey();

  Future<void> _onImageCropped(ImageCroppedEvent event, Emitter<CropState> emit) async {
    emit(
      state.copyWith(
        isWorking: true,
      ),
    );

    final bytes = await Cropper.crop(
      cropperKey: cropKey,
    );
    _completer.complete(bytes);

    GetIt.I.get<NavigationBloc>().add(PoppedRouteEvent());

    await _onImageReset(ResetImageEvent(), emit);
  }

  Future<void> _onImageReset(ResetImageEvent event, Emitter<CropState> emit) async {
    emit(
      state.copyWith(
        image: null,
        isWorking: false,
      ),
    );
  }

  Future<void> _onImageSet(SetImageEvent event, Emitter<CropState> emit) async {
    emit(
      state.copyWith(
        image: event.image,
      ),
    );
  }
  
  Future<void> _performCropping(String path) async {
    final file = File(path);
    if (!file.existsSync()) _completer.complete(null);

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
        const NavigationDestination(cropRoute),
      ),
    );   
    _performCropping(path);

    return _completer.future;
  }

  /// User-callable function. Loads the image, navigates to the page
  /// and allows the user to crop the image. The future resolves when
  /// either an error occures or the image has been cropped.
  Future<Uint8List?> cropImageWithData(Uint8List data) {
    _completer = Completer();

    GetIt.I.get<NavigationBloc>().add(
      PushedNamedEvent(
        const NavigationDestination(cropRoute),
      ),
    );

    add(SetImageEvent(data));
    
    return _completer.future;
  }
}
