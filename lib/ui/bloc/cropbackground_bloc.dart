import 'dart:io';
import 'dart:isolate';
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

// This function in an isolate allows to perform the cropping without blocking the UI
// at all. Sending the image data to the isolate would result in UI blocking.
// TODO(Unknown): Maybe make use of image's executeThread method to replace our own
//                isolate code.
Future<void> _cropImage(List<dynamic> data) async {
  final port = data[0] as SendPort;
  final originalPath = data[1] as String;
  final destination = data[2] as String;
  final q = data[3] as double;
  final x = data[4] as double;
  final y = data[5] as double;
  final vw = data[6] as double;
  final vh = data[7] as double;
  final blur = data[8] as bool;

  final inverse = 1 / q;
  final xp = (x.abs() * inverse).toInt();
  final yp = (y.abs() * inverse).toInt();

  final cmd = Command()
      ..decodeImageFile(originalPath)
      ..copyCrop(x: xp, y: yp, width: (vw * inverse).toInt(), height: (vh * inverse).toInt());

  if (blur) {
    cmd.gaussianBlur(radius: 10);
  }

  cmd.writeToFile(destination);

  await cmd.execute();
  port.send(true);
}

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
        imagePath: '',
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

    final port = ReceivePort();
    await Isolate.spawn(
      _cropImage,
      [
        port.sendPort,
        state.imagePath,
        backgroundPath,
        event.q,
        event.x,
        event.y,
        event.viewportWidth,
        event.viewportHeight,
        state.blurEnabled,
      ],
    );
    await port.first;

    _resetState(emit);

    GetIt.I.get<PreferencesBloc>().add(BackgroundImageSetEvent(backgroundPath));
    GetIt.I.get<NavigationBloc>().add(PoppedRouteEvent());
  }
}
