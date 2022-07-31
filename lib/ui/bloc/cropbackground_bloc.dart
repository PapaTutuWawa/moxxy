import 'dart:io';
import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:image/image.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:stack_blur/stack_blur.dart';

part 'cropbackground_bloc.freezed.dart';
part 'cropbackground_event.dart';
part 'cropbackground_state.dart';

class CropBackgroundBloc extends Bloc<CropBackgroundEvent, CropBackgroundState> {

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
      ),
    );
  }
  
  Future<void> _onRequested(CropBackgroundRequestedEvent event, Emitter<CropBackgroundState> emit) async {
    // Navigate to the page
    GetIt.I.get<NavigationBloc>().add(
      PushedNamedEvent(const NavigationDestination(backgroundCroppingRoute)),
    );

    final data = await File(event.path).readAsBytes();
    final image = decodeImage(data)!;
    emit(
      state.copyWith(
        image: data,
        imagePath: event.path,
        imageWidth: image.width,
        imageHeight: image.height,
      ),
    );
  }

  Future<void> _onReset(CropBackgroundResetEvent event, Emitter<CropBackgroundState> emit) async {
    _resetState(emit);
  }

  Future<void> _onBlurToggled(BlurToggledEvent event, Emitter<CropBackgroundState> emit) async {
    emit(state.copyWith(blurEnabled: !state.blurEnabled));
  }

  Future<void> _onBackgroundSet(BackgroundSetEvent event, Emitter<CropBackgroundState> emit) async {
    final appDir = await getApplicationDocumentsDirectory();
    final backgroundPath = path.join(appDir.path, 'background_image.png');

    // TODO(PapaTutuWawa): Do this in a separate isolate
    // Transform the values back down to the original image
    final inverse = 1 / event.q;
    final xp = (event.x.abs() * inverse).toInt();
    final yp = (event.y.abs() * inverse).toInt();
    final image = decodeImage(await File(state.imagePath).readAsBytes())!;
    final cropped = copyCrop(
      image,
      xp,
      yp,
      (event.viewportWidth * inverse).toInt(),
      (event.viewportHeight * inverse).toInt(),
    );

    // NOTE: Technically, ImageFilter.blur implements a Gaussian blur, but I would have
    //       implement it myself...
    if (state.blurEnabled) {
      stackBlurRgba(cropped.data, cropped.width, cropped.height, 20);
    }

    // Save it
    await File(backgroundPath).writeAsBytes(encodePng(cropped));

    _resetState(emit);

    GetIt.I.get<PreferencesBloc>().add(BackgroundImageSetEvent(backgroundPath));
    GetIt.I.get<NavigationBloc>().add(PoppedRouteEvent());
  }
}
