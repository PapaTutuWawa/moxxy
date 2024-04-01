import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/ui/bloc/navigation.dart';
import 'package:moxxyv2/ui/constants.dart';

part 'blocklist.freezed.dart';

@freezed
class BlocklistState with _$BlocklistState {
  factory BlocklistState({
    @Default(<String>[]) List<String> blocklist,
    @Default(false) bool isWorking,
  }) = _BlocklistState;
}

class BlocklistCubit extends Cubit<BlocklistState> {
  BlocklistCubit() : super(BlocklistState());

  Future<void> requestBlocklist() async {
    final mustDoWork = state.blocklist.isEmpty;

    if (mustDoWork) {
      emit(
        state.copyWith(
          isWorking: true,
        ),
      );
    }

    GetIt.I.get<Navigation>().pushNamed(
          const NavigationDestination(blocklistRoute),
        );

    if (state.blocklist.isEmpty) {
      // ignore: cast_nullable_to_non_nullable
      final result = await getForegroundService().send(
        GetBlocklistCommand(),
      ) as GetBlocklistResultEvent;

      emit(
        state.copyWith(
          blocklist: result.entries,
          isWorking: false,
        ),
      );
    }
  }

  Future<void> unblockJid(
    String jid,
  ) async {
    await getForegroundService().send(
      UnblockJidCommand(
        jid: jid,
      ),
    );

    final blocklist = state.blocklist.where((String i) => i != jid).toList();
    emit(state.copyWith(blocklist: blocklist));
  }

  Future<void> unblockAll() async {
    await getForegroundService().send(
      UnblockAllCommand(),
    );

    emit(
      state.copyWith(blocklist: <String>[]),
    );
  }

  Future<void> blocklistPushed(
    List<String> added,
    List<String> removed,
  ) async {
    final blocklist = state.blocklist..addAll(added);
    emit(
      state.copyWith(
        blocklist: blocklist.where((String i) => !removed.contains(i)).toList(),
      ),
    );
  }
}
