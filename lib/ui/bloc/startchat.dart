import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/error_types.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/ui/bloc/conversation.dart';
import 'package:moxxyv2/ui/bloc/conversations.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/pages/startgroupchat.dart';

part 'startchat.freezed.dart';

@freezed
class StartChatState with _$StartChatState {
  factory StartChatState({
    @Default('') String jid,
    @Default(null) String? jidError,
    @Default(false) bool isWorking,
  }) = _StartChatState;
}

class StartChatCubit extends Cubit<StartChatState> {
  StartChatCubit() : super(StartChatState());

  Future<void> addContact() async {
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
    final result = await getForegroundService().send(
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

    reset();

    final addResult = result! as AddContactResultEvent;
    if (addResult.conversation != null) {
      final cubit = GetIt.I.get<ConversationsCubit>();
      if (addResult.added) {
        await cubit.addConversation(addResult.conversation!);
      } else {
        await cubit.updateConversation(addResult.conversation!);
      }
    }

    assert(
      addResult.conversation != null,
      'RequestedConversationEvent must contain a not null conversation',
    );
    await GetIt.I.get<ConversationCubit>().request(
          addResult.conversation!.jid,
          addResult.conversation!.title,
          addResult.conversation!.avatarPath,
          removeUntilConversations: true,
        );
  }

  void onJidChanged(String jid) {
    emit(
      state.copyWith(
        jid: jid,
      ),
    );
  }

  void reset() {
    emit(
      state.copyWith(
        jidError: null,
        jid: '',
        isWorking: false,
      ),
    );
  }
}
