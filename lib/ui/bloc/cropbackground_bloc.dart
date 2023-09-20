import 'dart:io';
import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:image/image.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:path/path.dart' as path;

part 'cropbackground_bloc.freezed.dart';
part 'cropbackground_event.dart';
part 'cropbackground_state.dart';

class CropBackgroundBloc
    extends Bloc<CropBackgroundEvent, CropBackgroundState> {
  CropBackgroundBloc() : super(CropBackgroundState()) {
    on<CropBackgroundRequestedEvent>(_onRequested);
    on<CropBackgroundResetEvent>(_onReset);
    on<BlurToggledEvent>(_onBlurToggled);
    on<BackgroundSetEvent>(_onBackgroundSet);
  }

  void _resetState(Emitter<CropBackgroundState> emit) {
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

  Future<void> _onRequested(
    CropBackgroundRequestedEvent event,
    Emitter<CropBackgroundState> emit,
  ) async {
    // Navigate to the page
    _resetState(emit);

    GetIt.I.get<NavigationBloc>().add(
          PushedNamedEvent(
            const NavigationDestination(backgroundCroppingRoute),
          ),
        );

    final data = await File(event.path).readAsBytes();
    final imageSize = (await getImageSizeFromData(data))!;
    emit(
      state.copyWith(
        image: data,
        imagePath: event.path,
        imageWidth: imageSize.width.toInt(),
        imageHeight: imageSize.height.toInt(),
      ),
    );
  }

  Future<void> _onReset(
    CropBackgroundResetEvent event,
    Emitter<CropBackgroundState> emit,
  ) async {
    _resetState(emit);
  }

  Future<void> _onBlurToggled(
    BlurToggledEvent event,
    Emitter<CropBackgroundState> emit,
  ) async {
    emit(state.copyWith(blurEnabled: !state.blurEnabled));
  }

  Future<void> _onBackgroundSet(
    BackgroundSetEvent event,
    Emitter<CropBackgroundState> emit,
  ) async {
    emit(state.copyWith(isWorking: true));

    final appDir = await MoxxyPlatformApi().getPersistentDataPath();
    final backgroundPath = path.join(appDir, 'background_image.png');

    // Compute values for cropping the image.
    final inverse = 1 / event.q;
    final xp = (event.x.abs() * inverse).toInt();
    final yp = (event.y.abs() * inverse).toInt();

    // Compute the crop and optional blur.
    final cmd = Command()
      ..decodeImageFile(state.imagePath!)
      ..copyCrop(
        x: xp,
        y: yp,
        width: (event.viewportWidth * inverse).toInt(),
        height: (event.viewportHeight * inverse).toInt(),
      );
    if (state.blurEnabled) {
      cmd.gaussianBlur(radius: 10);
    }
    cmd.writeToFile(backgroundPath);
    await cmd.executeThread();

    _resetState(emit);

    GetIt.I.get<PreferencesBloc>().add(BackgroundImageSetEvent(backgroundPath));
    GetIt.I.get<NavigationBloc>().add(PoppedRouteEvent());
  }
}
