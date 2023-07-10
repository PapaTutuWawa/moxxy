import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/ui/controller/sticker_pack_controller.dart';
import 'package:moxxyv2/ui/helpers.dart';

part 'stickers_bloc.freezed.dart';
part 'stickers_event.dart';
part 'stickers_state.dart';

class StickersBloc extends Bloc<StickersEvent, StickersState> {
  StickersBloc() : super(StickersState()) {
    on<StickerPackRemovedEvent>(_onStickerPackRemoved);
    on<StickerPackImportedEvent>(_onStickerPackImported);
  }

  Future<void> _onStickerPackRemoved(
    StickerPackRemovedEvent event,
    Emitter<StickersState> emit,
  ) async {
    // Remove from the UI
    BidirectionalStickerPackController.instance?.removeItem(
      (stickerPack) => stickerPack.id == event.stickerPackId,
    );

    // Notify the backend
    await MoxplatformPlugin.handler.getDataSender().sendData(
          RemoveStickerPackCommand(
            stickerPackId: event.stickerPackId,
          ),
          awaitable: false,
        );
  }

  Future<void> _onStickerPackImported(
    StickerPackImportedEvent event,
    Emitter<StickersState> emit,
  ) async {
    final pickerResult = await safePickFiles(
      FileType.any,
      allowMultiple: false,
    );
    if (pickerResult == null) return;

    emit(
      state.copyWith(
        isImportRunning: true,
      ),
    );

    final result = await MoxplatformPlugin.handler.getDataSender().sendData(
          ImportStickerPackCommand(
            path: pickerResult.files.single.path!,
          ),
        );

    emit(
      state.copyWith(
        isImportRunning: false,
      ),
    );

    if (result is StickerPackImportSuccessEvent) {
      await Fluttertoast.showToast(
        msg: t.pages.settings.stickers.importSuccess,
        gravity: ToastGravity.SNACKBAR,
        toastLength: Toast.LENGTH_SHORT,
      );
    } else {
      await Fluttertoast.showToast(
        msg: t.pages.settings.stickers.importFailure,
        gravity: ToastGravity.SNACKBAR,
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }
}
