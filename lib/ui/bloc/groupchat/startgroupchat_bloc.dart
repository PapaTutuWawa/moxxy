import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/error_types.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/bloc/conversations_bloc.dart';

part 'startgroupchat_bloc.freezed.dart';
part 'startgroupchat_event.dart';
part 'startgroupchat_state.dart';

class StartGroupchatBloc
    extends Bloc<StartGroupchatEvent, StartGroupchatState> {
  StartGroupchatBloc() : super(StartGroupchatState()) {
    on<JidChangedEvent>(_onJidChanged);
    on<PageResetEvent>(_onPageReset);
    on<JoinGroupchatEvent>(_onJoinGroupchat);
    on<NickChangedEvent>(_onNickChanged);
  }

  Future<void> _onJidChanged(
    JidChangedEvent event,
    Emitter<StartGroupchatState> emit,
  ) async {
    emit(
      state.copyWith(
        jid: event.jid,
      ),
    );
  }

  Future<void> _onNickChanged(
    NickChangedEvent event,
    Emitter<StartGroupchatState> emit,
  ) async {
    emit(
      state.copyWith(nick: event.nick),
    );
  }

  Future<void> _onPageReset(
    PageResetEvent event,
    Emitter<StartGroupchatState> emit,
  ) async {
    emit(
      state.copyWith(
        jidError: null,
        jid: '',
        nick: '',
        nickError: null,
        isWorking: false,
      ),
    );
  }

  Future<void> _onJoinGroupchat(
    JoinGroupchatEvent event,
    Emitter<StartGroupchatState> emit,
  ) async {
    final validation = validateJidString(state.jid);
    if (validation != null) {
      emit(state.copyWith(jidError: validation));
      return;
    } else if (state.nick.isEmpty) {
      emit(state.copyWith(nickError: 'Nickname cannot be null!'));
      return;
    }

    emit(
      state.copyWith(
        isWorking: true,
        jidError: null,
      ),
    );

    // ignore: cast_nullable_to_non_nullable
    final result = await MoxplatformPlugin.handler.getDataSender().sendData(
          JoinGroupchatCommand(jid: state.jid, nick: state.nick),
        );
    if (result is ErrorEvent) {
      final error = result.errorId == ErrorType.remoteServerNotFound.value ||
              result.errorId == ErrorType.remoteServerTimeout.value
          ? t.errors.newChat.remoteServerError
          : t.errors.newChat.unknown;
      emit(
        state.copyWith(
          jidError: error,
          isWorking: false,
        ),
      );
      return;
    }
    await _onPageReset(PageResetEvent(), emit);
    final joinEvent = result! as JoinGroupchatResultEvent;
    if (joinEvent.conversation != null) {
      if (joinEvent.added) {
        GetIt.I.get<ConversationsBloc>().add(
              ConversationsAddedEvent(joinEvent.conversation!),
            );
      } else {
        GetIt.I.get<ConversationsBloc>().add(
              ConversationsUpdatedEvent(joinEvent.conversation!),
            );
      }
    }

    assert(
      joinEvent.conversation != null,
      'RequestedConversationEvent must contain a not null conversation',
    );
    GetIt.I.get<ConversationBloc>().add(
          RequestedConversationEvent(
            joinEvent.conversation!.jid,
            joinEvent.conversation!.title,
            joinEvent.conversation!.avatarPath,
            removeUntilConversations: true,
          ),
        );
  }
}
