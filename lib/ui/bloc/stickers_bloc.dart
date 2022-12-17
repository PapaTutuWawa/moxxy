import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxxyv2/shared/models/sticker.dart';
import 'package:moxxyv2/shared/models/sticker_pack.dart';

part 'stickers_bloc.freezed.dart';
part 'stickers_event.dart';
part 'stickers_state.dart';

class StickersBloc extends Bloc<StickersEvent, StickersState> {
  StickersBloc() : super(StickersState()) {
    on<StickersSetEvent>(_onStickersSet);
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
}
