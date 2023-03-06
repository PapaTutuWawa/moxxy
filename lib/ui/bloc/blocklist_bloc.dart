import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';

part 'blocklist_bloc.freezed.dart';
part 'blocklist_event.dart';
part 'blocklist_state.dart';

class BlocklistBloc extends Bloc<BlocklistEvent, BlocklistState> {
  BlocklistBloc() : super(BlocklistState()) {
    on<BlocklistRequestedEvent>(_onBlocklistRequested);
    on<UnblockedJidEvent>(_onJidUnblocked);
    on<UnblockedAllEvent>(_onUnblockedAll);
    on<BlocklistPushedEvent>(_onBlocklistPushed);
  }

  Future<void> _onBlocklistRequested(
    BlocklistRequestedEvent event,
    Emitter<BlocklistState> emit,
  ) async {
    final mustDoWork = state.blocklist.isEmpty;

    if (mustDoWork) {
      emit(
        state.copyWith(
          isWorking: true,
        ),
      );
    }

    GetIt.I.get<NavigationBloc>().add(
          PushedNamedEvent(
            const NavigationDestination(blocklistRoute),
          ),
        );

    if (state.blocklist.isEmpty) {
      // ignore: cast_nullable_to_non_nullable
      final result = await MoxplatformPlugin.handler.getDataSender().sendData(
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

  Future<void> _onJidUnblocked(
    UnblockedJidEvent event,
    Emitter<BlocklistState> emit,
  ) async {
    await MoxplatformPlugin.handler.getDataSender().sendData(
          UnblockJidCommand(
            jid: event.jid,
          ),
        );

    final blocklist =
        state.blocklist.where((String i) => i != event.jid).toList();
    emit(state.copyWith(blocklist: blocklist));
  }

  Future<void> _onUnblockedAll(
    UnblockedAllEvent event,
    Emitter<BlocklistState> emit,
  ) async {
    await MoxplatformPlugin.handler.getDataSender().sendData(
          UnblockAllCommand(),
        );

    emit(
      state.copyWith(blocklist: <String>[]),
    );
  }

  Future<void> _onBlocklistPushed(
    BlocklistPushedEvent event,
    Emitter<BlocklistState> emit,
  ) async {
    final blocklist = state.blocklist..addAll(event.added);
    emit(
      state.copyWith(
        blocklist:
            blocklist.where((String i) => !event.removed.contains(i)).toList(),
      ),
    );
  }
}
