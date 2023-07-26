import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
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
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/pages/startgroupchat.dart';

part 'startchat_bloc.freezed.dart';
part 'startchat_event.dart';
part 'startchat_state.dart';

class StartChatBloc extends Bloc<StartChatEvent, StartChatState> {
  StartChatBloc() : super(StartChatState()) {
    on<AddedContactEvent>(_onContactAdded);
    on<JidChangedEvent>(_onJidChanged);
    on<PageResetEvent>(_onPageReset);
  }

  Future<void> _onContactAdded(
    AddedContactEvent event,
    Emitter<StartChatState> emit,
  ) async {
    final validation = validateJidString(state.jid);
    if (validation != null) {
      emit(state.copyWith(jidError: validation));
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
          AddContactCommand(
            jid: state.jid,
          ),
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
    } else if (result is JidIsGroupchatEvent) {
      if (kDebugMode) {
        GetIt.I.get<NavigationBloc>().add(
              PushedNamedAndRemoveUntilEvent(
                NavigationDestination(
                  joinGroupchatRoute,
                  arguments: JoinGroupchatArguments(result.jid),
                ),
                (_) => false,
              ),
            );
      } else {
        emit(
          state.copyWith(
            jidError: t.errors.newChat.groupchatUnsupported,
            isWorking: false,
          ),
        );
      }
      return;
    }

    await _onPageReset(PageResetEvent(), emit);

    final addResult = result! as AddContactResultEvent;
    if (addResult.conversation != null) {
      if (addResult.added) {
        GetIt.I.get<ConversationsBloc>().add(
              ConversationsAddedEvent(addResult.conversation!),
            );
      } else {
        GetIt.I.get<ConversationsBloc>().add(
              ConversationsUpdatedEvent(addResult.conversation!),
            );
      }
    }

    assert(
      addResult.conversation != null,
      'RequestedConversationEvent must contain a not null conversation',
    );
    GetIt.I.get<ConversationBloc>().add(
          RequestedConversationEvent(
            addResult.conversation!.jid,
            addResult.conversation!.title,
            addResult.conversation!.avatarPath,
            removeUntilConversations: true,
          ),
        );
  }

  Future<void> _onJidChanged(
    JidChangedEvent event,
    Emitter<StartChatState> emit,
  ) async {
    emit(
      state.copyWith(
        jid: event.jid,
      ),
    );
  }

  Future<void> _onPageReset(
    PageResetEvent event,
    Emitter<StartChatState> emit,
  ) async {
    emit(
      state.copyWith(
        jidError: null,
        jid: '',
        isWorking: false,
      ),
    );
  }
}
