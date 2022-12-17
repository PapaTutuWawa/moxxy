import 'package:bloc/bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxlib/moxlib.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/sticker.dart';
import 'package:moxxyv2/shared/models/sticker_pack.dart';

part 'stickers_bloc.freezed.dart';
part 'stickers_event.dart';
part 'stickers_state.dart';

class StickersBloc extends Bloc<StickersEvent, StickersState> {
  StickersBloc() : super(StickersState()) {
    on<StickersSetEvent>(_onStickersSet);
    on<StickerPackRemovedEvent>(_onStickerPackRemoved);
    on<StickerPackImportedEvent>(_onStickerPackImported);
  }

  Future<void> _onStickersSet(StickersSetEvent event, Emitter<StickersState> emit) async {
    // Also store a mapping of (pack Id, sticker Id) -> Sticker to allow fast lookup
    // of the sticker in the UI.
    final map = <StickerKey, Sticker>{};
    for (final pack in event.stickerPacks) {
      for (final sticker in pack.stickers) {
        map[StickerKey(pack.id, sticker.id)] = sticker;
      }
    }
    
    emit(
      state.copyWith(
        stickerPacks: event.stickerPacks,
        stickerMap: map,
      ),
    );
  }

  Future<void> _onStickerPackRemoved(StickerPackRemovedEvent event, Emitter<StickersState> emit) async {
    final stickerPack = firstWhereOrNull(
      state.stickerPacks,
      (StickerPack sp) => sp.id == event.stickerPackId,
    )!;
    final sm = Map<StickerKey, Sticker>.from(state.stickerMap);
    for (final sticker in stickerPack.stickers) {
      sm.remove(StickerKey(stickerPack.id, sticker.id));
    }

    emit(
      state.copyWith(
        stickerPacks: List.from(
          state.stickerPacks.where((sp) => sp.id != event.stickerPackId),
        ),
        stickerMap: sm,
      ),
    );

    await MoxplatformPlugin.handler.getDataSender().sendData(
      RemoveStickerPackCommand(
        stickerPackId: event.stickerPackId,
      ),
      awaitable: false,
    );
  }

  Future<void> _onStickerPackImported(StickerPackImportedEvent event, Emitter<StickersState> emit) async {
    final file = await FilePicker.platform.pickFiles();
    if (file == null) return;

    final result = await MoxplatformPlugin.handler.getDataSender().sendData(
      ImportStickerPackCommand(
        path: file.files.single.path!,
      ),
    );

    if (result is StickerPackImportSuccessEvent) {
      final sm = Map<StickerKey, Sticker>.from(state.stickerMap);
      for (final sticker in result.stickerPack.stickers) {
        sm[StickerKey(result.stickerPack.id, sticker.id)] = sticker;
      }
      emit(
        state.copyWith(
          stickerPacks: List<StickerPack>.from([
            ...state.stickerPacks,
            result.stickerPack,
          ]),
          stickerMap: sm,
        ),
      );
    }
  }
}
