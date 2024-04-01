import 'package:bloc/bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/sticker_pack.dart';
import 'package:moxxyv2/ui/state/navigation.dart';
import 'package:moxxyv2/ui/state/stickers.dart' as stickers;
import 'package:moxxyv2/ui/constants.dart';

part 'sticker_pack.freezed.dart';

@freezed
class StickerPackState with _$StickerPackState {
  factory StickerPackState({
    StickerPack? stickerPack,
    @Default(false) bool isWorking,
    @Default(false) bool isInstalling,
  }) = _StickerPackState;
}

class StickerPackCubit extends Cubit<StickerPackState> {
  StickerPackCubit() : super(StickerPackState());

  Future<void> requestLocalStickerPack(String stickerPackId) async {
    emit(
      state.copyWith(
        isWorking: true,
        isInstalling: false,
      ),
    );

    // Navigate
    GetIt.I.get<Navigation>().pushNamed(
          const NavigationDestination(stickerPackRoute),
        );

    // Apply
    final stickerPackResult =
        // ignore: cast_nullable_to_non_nullable
        await getForegroundService().send(
      GetStickerPackByIdCommand(
        id: stickerPackId,
      ),
    ) as GetStickerPackByIdResult;
    assert(
      stickerPackResult.stickerPack != null,
      'The sticker pack must be found',
    );

    emit(
      state.copyWith(
        isWorking: false,
        stickerPack: stickerPackResult.stickerPack,
      ),
    );
  }

  Future<void> removeStickerPack(String stickerPackId) async {
    // Reset internal state
    emit(
      state.copyWith(
        stickerPack: null,
        isWorking: true,
      ),
    );

    // Leave the page
    GetIt.I.get<Navigation>().pop();

    // Remove the sticker pack
    await GetIt.I.get<stickers.StickersCubit>().remove(stickerPackId);
  }

  Future<void> requestRemoteStickerPack(
    String jid,
    String stickerPackId,
  ) async {
    final mustDoWork =
        state.stickerPack == null || state.stickerPack?.id != stickerPackId;
    if (mustDoWork) {
      emit(
        state.copyWith(
          isWorking: true,
          isInstalling: false,
        ),
      );
    }

    // Navigate
    GetIt.I.get<Navigation>().pushNamed(
          const NavigationDestination(stickerPackRoute),
        );

    if (mustDoWork) {
      final result = await getForegroundService().send(
        FetchStickerPackCommand(
          stickerPackId: stickerPackId,
          jid: jid,
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
        // Leave the page
        GetIt.I.get<Navigation>().pop();
      }
    }
  }

  Future<void> install() async {
    assert(!state.stickerPack!.local, 'Sticker pack must be remote');
    emit(
      state.copyWith(
        isInstalling: true,
      ),
    );

    final result = await getForegroundService().send(
      InstallStickerPackCommand(
        stickerPack: state.stickerPack!,
      ),
    );

    emit(
      state.copyWith(
        isInstalling: false,
      ),
    );

    // Leave the page
    GetIt.I.get<Navigation>().pop();

    // Notify on failure
    if (result is! StickerPackInstallSuccessEvent) {
      await Fluttertoast.showToast(
        msg: t.pages.stickerPack.fetchingFailure,
        gravity: ToastGravity.SNACKBAR,
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  Future<void> request(String jid, String stickerPackId) async {
    emit(
      state.copyWith(
        isWorking: true,
      ),
    );

    final stickerPackResult =
        // ignore: cast_nullable_to_non_nullable
        await getForegroundService().send(
      GetStickerPackByIdCommand(
        id: stickerPackId,
      ),
    ) as GetStickerPackByIdResult;

    // Find out if the sticker pack is locally available or not
    if (stickerPackResult.stickerPack == null) {
      await requestRemoteStickerPack(
        stickerPackId,
        jid,
      );
    } else {
      emit(
        state.copyWith(
          isWorking: false,
          stickerPack: stickerPackResult.stickerPack,
        ),
      );
    }
  }
}
