import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/ui/controller/sticker_pack_controller.dart';
import 'package:moxxyv2/ui/helpers.dart';

part 'stickers.freezed.dart';

@immutable
class StickerKey {
  const StickerKey(this.packId, this.stickerHashKey);
  final String packId;
  final String stickerHashKey;

  @override
  int get hashCode => packId.hashCode ^ stickerHashKey.hashCode;

  @override
  bool operator ==(Object other) {
    return other is StickerKey &&
        other.packId == packId &&
        other.stickerHashKey == stickerHashKey;
  }
}

@freezed
class StickersState with _$StickersState {
  factory StickersState({
    @Default(false) bool isImportRunning,
  }) = _StickersState;
}

class StickersCubit extends Cubit<StickersState> {
  StickersCubit() : super(StickersState());

  Future<void> remove(String stickerPackId) async {
    // Remove from the UI
    BidirectionalStickerPackController.instance?.removeItem(
      (stickerPack) => stickerPack.id == stickerPackId,
    );

    // Notify the backend
    await getForegroundService().send(
      RemoveStickerPackCommand(
        stickerPackId: stickerPackId,
      ),
      awaitable: false,
    );
  }

  Future<void> import() async {
    final pickerResult = await safePickFiles(
      FilePickerType.generic,
      allowMultiple: false,
    );
    if (pickerResult == null) return;

    emit(
      state.copyWith(
        isImportRunning: true,
      ),
    );

    final result = await getForegroundService().send(
      ImportStickerPackCommand(
        path: pickerResult.files!.first,
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
