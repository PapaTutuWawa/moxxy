import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';

part 'blocklist_bloc.freezed.dart';
part 'blocklist_event.dart';
part 'blocklist_state.dart';

class BlocklistBloc extends Bloc<BlocklistEvent, BlocklistState> {
  BlocklistBloc() : super(BlocklistState()) {
    on<UnblockedJidEvent>(_onJidUnblocked);
    on<UnblockedAllEvent>(_onUnblockedAll);
    on<BlocklistPushedEvent>(_onBlocklistPushed);
  }

  Future<void> _onJidUnblocked(UnblockedJidEvent event, Emitter<BlocklistState> emit) async {
    await MoxplatformPlugin.handler.getDataSender().sendData(
      UnblockJidCommand(
        jid: event.jid,
      ),
    );

    final blocklist = state.blocklist
      .where((String i) => i != event.jid)
      .toList();
    emit(state.copyWith(blocklist: blocklist));
  }

  Future<void> _onUnblockedAll(UnblockedAllEvent event, Emitter<BlocklistState> emit) async {
    await MoxplatformPlugin.handler.getDataSender().sendData(
      UnblockAllCommand(),
    );

    emit(
      state.copyWith(blocklist: <String>[]),
    );
  }

  Future<void> _onBlocklistPushed(BlocklistPushedEvent event, Emitter<BlocklistState> emit) async {
    final blocklist = state.blocklist..addAll(event.added);
    emit(
      state.copyWith(
        blocklist: blocklist.where((String i) => !event.removed.contains(i)).toList(),
      ),
    );
  }
}
