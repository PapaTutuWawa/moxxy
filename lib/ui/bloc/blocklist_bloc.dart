import "package:moxxyv2/shared/commands.dart";
import "package:moxxyv2/shared/backgroundsender.dart";

import "package:bloc/bloc.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:get_it/get_it.dart";

part "blocklist_state.dart";
part "blocklist_event.dart";
part "blocklist_bloc.freezed.dart";

class BlocklistBloc extends Bloc<BlocklistEvent, BlocklistState> {
  BlocklistBloc() : super(BlocklistState()) {
    on<UnblockedJidEvent>(_onJidUnblocked);
    on<UnblockedAllEvent>(_onUnblockedAll);
    on<BlocklistPushedEvent>(_onBlocklistPushed);
  }

  Future<void> _onJidUnblocked(UnblockedJidEvent event, Emitter<BlocklistState> emit) async {
    GetIt.I.get<BackgroundServiceDataSender>().sendData(
      UnblockJidCommand(
        jid: event.jid
      )
    );

    emit(
      state.copyWith(blocklist: state.blocklist.where((i) => i != event.jid))
    );
  }

  Future<void> _onUnblockedAll(UnblockedAllEvent event, Emitter<BlocklistState> emit) async {
    GetIt.I.get<BackgroundServiceDataSender>().sendData(
      UnblockAllCommand()
    );

    emit(
      state.copyWith(blocklist: [])
    );
  }

  Future<void> _onBlocklistPushed(BlocklistPushedEvent event, Emitter<BlocklistState> emit) async {
    final blocklist = state.blocklist..add(event.added);
    emit(
      state.copyWith(
        blocklist: blocklist.where((i) => !event.removed.contains(i))
      )
    );
  }
}
