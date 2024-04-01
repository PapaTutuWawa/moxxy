import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:cropperx/cropperx.dart';
import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/ui/bloc/navigation.dart';
import 'package:moxxyv2/ui/constants.dart';

part 'crop.freezed.dart';

@freezed
class CropState with _$CropState {
  factory CropState({
    @Default(null) Uint8List? image,
    @Default(false) bool isWorking,
  }) = _CropState;
}

class CropCubit extends Cubit<CropState> {
  CropCubit() : super(CropState());
  late Completer<Uint8List?> _completer;
  final GlobalKey cropKey = GlobalKey();

  Future<void> croppedImage() async {
    emit(
      state.copyWith(
        isWorking: true,
      ),
    );

    final bytes = await Cropper.crop(
      cropperKey: cropKey,
    );
    _completer.complete(bytes);

    GetIt.I.get<NavigationCubit>().pop();

    await resetImage();
  }

  Future<void> resetImage() async {
    emit(
      state.copyWith(
        image: null,
        isWorking: false,
      ),
    );
  }

  Future<void> setImage(Uint8List image) async {
    emit(
      state.copyWith(
        image: image,
      ),
    );
  }

  Future<void> _performCropping(String path) async {
    final file = File(path);
    if (!file.existsSync()) _completer.complete(null);

    final bytes = await file.readAsBytes();

    return setImage(bytes);
  }

  /// User-callable function. Loads the image, navigates to the page
  /// and allows the user to crop the image. The future resolves when
  /// either an error occures or the image has been cropped.
  /// [path] is the path to the file to load.
  Future<Uint8List?> cropImage(String path) {
    _completer = Completer();

    resetImage();
    GetIt.I.get<NavigationCubit>().pushNamed(
          const NavigationDestination(cropRoute),
        );
    _performCropping(path);

    return _completer.future;
  }

  /// User-callable function. Loads the image, navigates to the page
  /// and allows the user to crop the image. The future resolves when
  /// either an error occures or the image has been cropped.
  Future<Uint8List?> cropImageWithData(Uint8List data) {
    _completer = Completer();

    GetIt.I.get<NavigationCubit>().pushNamed(
          const NavigationDestination(cropRoute),
        );

    setImage(data);

    return _completer.future;
  }
}
