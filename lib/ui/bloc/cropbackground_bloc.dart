import 'dart:io';
import 'dart:isolate';
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

void _blurImage(List<dynamic> values) {
  final port = values[0] as SendPort;
  final bytes = values[1] as Uint8List;
  
  final image = decodeImage(bytes)!;
  final pixels = image.data;
  stackBlurRgba(pixels, image.width, image.height, 42);

  port.send(Uint8List.fromList(encodePng(image)));
}

class CropBackgroundBloc extends Bloc<CropBackgroundEvent, CropBackgroundState> {

  CropBackgroundBloc() : super(CropBackgroundState()) {
    on<CropBackgroundRequestedEvent>(_onRequested);
    on<CropBackgroundResetEvent>(_onReset);
    on<BlurToggledEvent>(_onBlurToggled);
    on<BackgroundSetEvent>(_onBackgroundSet);
  }

  void _resetState(Emitter<CropBackgroundState> emit) {
    emit(state.copyWith(image: null, blurEnabled: false, imagePath: ''));
  }
  
  Future<void> _onRequested(CropBackgroundRequestedEvent event, Emitter<CropBackgroundState> emit) async {
    // Navigate to the page
    GetIt.I.get<NavigationBloc>().add(
      PushedNamedEvent(const NavigationDestination(backgroundCroppingRoute)),
    );

    final data = await File(event.path).readAsBytes();
    emit(state.copyWith(image: data, imagePath: event.path));
  }

  Future<void> _onReset(CropBackgroundResetEvent event, Emitter<CropBackgroundState> emit) async {
    _resetState(emit);
  }

  Future<void> _onBlurToggled(BlurToggledEvent event, Emitter<CropBackgroundState> emit) async {
    // Show the loading spinner
    final bytes = state.image!;
    final blurEnabled = state.blurEnabled;
    emit(state.copyWith(image: null, blurEnabled: !state.blurEnabled));

    if (blurEnabled) {
      final data = await File(state.imagePath).readAsBytes();
      emit(state.copyWith(image: data));
    } else {
      final port = ReceivePort();
      await Isolate.spawn(_blurImage, [ port.sendPort, bytes ]);
      final blurredData = await port.first as Uint8List;

      emit(state.copyWith(image: blurredData));
    }
  }

  Future<void> _onBackgroundSet(BackgroundSetEvent event, Emitter<CropBackgroundState> emit) async {
    // Show loading spinner
    _resetState(emit);

    // Save the image
    final appDir = await getApplicationDocumentsDirectory();
    final backgroundPath = path.join(appDir.path, 'background_image');
    await File(backgroundPath).writeAsBytes(event.image);

    // TODO(Unknown): Already cache it

    GetIt.I.get<PreferencesBloc>().add(BackgroundImageSetEvent(backgroundPath));
    GetIt.I.get<NavigationBloc>().add(PoppedRouteEvent());
  }
}
