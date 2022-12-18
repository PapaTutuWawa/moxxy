import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxlib/moxlib.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/sticker_pack.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/bloc/stickers_bloc.dart' as stickers;
import 'package:moxxyv2/ui/constants.dart';

part 'sticker_pack_bloc.freezed.dart';
part 'sticker_pack_event.dart';
part 'sticker_pack_state.dart';

class StickerPackBloc extends Bloc<StickerPackEvent, StickerPackState> {
  StickerPackBloc() : super(StickerPackState()) {
    on<LocallyAvailableStickerPackRequested>(_onLocalStickerPackRequested);
    on<StickerPackRemovedEvent>(_onStickerPackRemoved);
    on<RemoteStickerPackRequested>(_onRemoteStickerPackRequested);
    on<StickerPackInstalledEvent>(_onStickerPackInstalled);
    on<StickerPackRequested>(_onStickerPackRequested);
  }

  Future<void> _onLocalStickerPackRequested(LocallyAvailableStickerPackRequested event, Emitter<StickerPackState> emit) async {
    emit(
      state.copyWith(
        isWorking: true,
        isInstalling: false,
      ),
    );

    // Navigate
    GetIt.I.get<NavigationBloc>().add(
      PushedNamedEvent(
        const NavigationDestination(stickerPackRoute),
      ),
    );

    // Apply
    final stickerPack = firstWhereOrNull(
      GetIt.I.get<stickers.StickersBloc>().state.stickerPacks,
      (StickerPack pack) => pack.id == event.stickerPackId,
    );
    assert(stickerPack != null, 'The sticker pack must be found');
    emit(
      state.copyWith(
        isWorking: false,
        stickerPack: stickerPack,
      ),
    );
  }

  Future<void> _onStickerPackRemoved(StickerPackRemovedEvent event, Emitter<StickerPackState> emit) async {
    // Reset internal state
    emit(
      state.copyWith(
        stickerPack: null,
        isWorking: true,
      ),
    );

    // Leave the page
    GetIt.I.get<NavigationBloc>().add(
      PoppedRouteEvent(),
    );
    
    // Remove the sticker pack
    GetIt.I.get<stickers.StickersBloc>().add(
      stickers.StickerPackRemovedEvent(event.stickerPackId),
    );
  }

  Future<void> _onRemoteStickerPackRequested(RemoteStickerPackRequested event, Emitter<StickerPackState> emit) async {
    final mustDoWork = state.stickerPack == null || state.stickerPack?.id != event.stickerPackId;
    if (mustDoWork) {
      emit(
        state.copyWith(
          isWorking: true,
          isInstalling: false,
        ),
      );
    }

    // Navigate
    GetIt.I.get<NavigationBloc>().add(
      PushedNamedEvent(
        const NavigationDestination(stickerPackRoute),
      ),
    );

    if (mustDoWork) {
      final result = await MoxplatformPlugin.handler.getDataSender().sendData(
        FetchStickerPackCommand(
          stickerPackId: event.stickerPackId,
          jid: event.jid,
        ),
      );

      if (result is FetchStickerPackSuccessResult) {
        emit(
          state.copyWith(
            isWorking: false,
            stickerPack: result.stickerPack,
          ),
        );
      } else {
        // TODO(PapaTutuWawa): Show a toast
        // Leave the page
        GetIt.I.get<NavigationBloc>().add(
          PoppedRouteEvent(),
        );
      }
    }
  }

  Future<void> _onStickerPackInstalled(StickerPackInstalledEvent event, Emitter<StickerPackState> emit) async {
    assert(!state.stickerPack!.local, 'Sticker pack must be remote');
    emit(
      state.copyWith(
        isInstalling: true,
      ),
    );

    final result = await MoxplatformPlugin.handler.getDataSender().sendData(
      InstallStickerPackCommand(
        stickerPack: state.stickerPack!,
      ),
    );

    emit(
      state.copyWith(
        isInstalling: false,
      ),
    );
    
    if (result is StickerPackInstallSuccessEvent) {
      GetIt.I.get<stickers.StickersBloc>().add(
        stickers.StickerPackAddedEvent(result.stickerPack),
      );

      // Leave the page
      GetIt.I.get<NavigationBloc>().add(
        PoppedRouteEvent(),
      );
    } else {
      // TODO(PapaTutuWawa): Show a toast (and maybe don't leave the page)
      // Leave the page
      GetIt.I.get<NavigationBloc>().add(
        PoppedRouteEvent(),
      );
    }
  }

  Future<void> _onStickerPackRequested(StickerPackRequested event, Emitter<StickerPackState> emit) async {
    // Find out if the sticker pack is locally available or not
    final stickerPack = firstWhereOrNull(
      GetIt.I.get<stickers.StickersBloc>().state.stickerPacks,
      (StickerPack pack) => pack.id == event.stickerPackId,
    );

    if (stickerPack == null) {
      await _onRemoteStickerPackRequested(
        RemoteStickerPackRequested(
          event.stickerPackId,
          event.jid,
        ),
        emit,
      );
    } else {
      await _onLocalStickerPackRequested(
        LocallyAvailableStickerPackRequested(event.stickerPackId),
        emit,
      );
    }
  }
}
