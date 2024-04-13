import 'dart:io';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:image/image.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/state/navigation.dart';
import 'package:moxxyv2/ui/state/preferences.dart';
import 'package:path/path.dart' as path;

part 'cropbackground.freezed.dart';

@freezed
class CropBackgroundState with _$CropBackgroundState {
  factory CropBackgroundState({
    String? imagePath,
    @Default(null) Uint8List? image,
    @Default(false) bool blurEnabled,
    @Default(0) int imageHeight,
    @Default(0) int imageWidth,
    @Default(false) bool isWorking,
  }) = _CropBackgroundState;
}

class CropBackgroundCubit extends Cubit<CropBackgroundState> {
  CropBackgroundCubit() : super(CropBackgroundState());

  void _resetState() {
    emit(
      state.copyWith(
        image: null,
        blurEnabled: false,
        imagePath: null,
        imageHeight: 0,
        imageWidth: 0,
        isWorking: false,
      ),
    );
  }

  Future<void> request(String path) async {
    // Navigate to the page
    _resetState();

    GetIt.I.get<Navigation>().pushNamed(
          const NavigationDestination(backgroundCroppingRoute),
        );

    final data = await File(path).readAsBytes();
    final imageSize = (await getImageSizeFromData(data))!;
    emit(
      state.copyWith(
        image: data,
        imagePath: path,
        imageWidth: imageSize.width.toInt(),
        imageHeight: imageSize.height.toInt(),
      ),
    );
  }

  void reset() {
    _resetState();
  }

  void toggleBlur() {
    emit(state.copyWith(blurEnabled: !state.blurEnabled));
  }

  Future<void> setBackground(
    double x,
    double y,
    double q,
    double viewportHeight,
    double viewportWidth,
  ) async {
    emit(state.copyWith(isWorking: true));

    final appDir = await MoxxyPlatformApi().getPersistentDataPath();
    final backgroundPath = path.join(appDir, 'background_image.png');

    // Compute values for cropping the image.
    final inverse = 1 / q;
    final xp = (x.abs() * inverse).toInt();
    final yp = (y.abs() * inverse).toInt();

    // Compute the crop and optional blur.
    final cmd = Command()
      ..decodeImageFile(state.imagePath!)
      ..copyCrop(
        x: xp,
        y: yp,
        width: (viewportWidth * inverse).toInt(),
        height: (viewportHeight * inverse).toInt(),
      );
    if (state.blurEnabled) {
      cmd.gaussianBlur(radius: 10);
    }
    cmd.writeToFile(backgroundPath);
    await cmd.executeThread();

    _resetState();

    await GetIt.I.get<PreferencesCubit>().setBackgroundImage(backgroundPath);
    GetIt.I.get<Navigation>().pop();
  }
}
