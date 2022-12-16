import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxxyv2/shared/models/sticker_pack.dart';

part 'stickers_bloc.freezed.dart';
part 'stickers_event.dart';
part 'stickers_state.dart';

class StickersBloc extends Bloc<StickersEvent, StickersState> {
  StickersBloc() : super(StickersState([])) {
    on<StickersSetEvent>(_onStickersSet);
  }

  Future<void> _onStickersSet(StickersSetEvent event, Emitter<StickersState> emit) async {
    emit(
      state.copyWith(
        stickerPacks: event.stickerPacks,
      ),
    );
  }
}
