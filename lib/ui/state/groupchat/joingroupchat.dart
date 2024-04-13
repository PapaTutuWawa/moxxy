import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/error_types.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/ui/state/conversation.dart';
import 'package:moxxyv2/ui/state/conversations.dart';

part 'joingroupchat.freezed.dart';

@freezed
class JoinGroupchatState with _$JoinGroupchatState {
  factory JoinGroupchatState({
    @Default('') String nick,
    @Default(null) String? nickError,
    @Default(false) bool isWorking,
  }) = _JoinGroupchatState;
}

class JoinGroupchatCubit extends Cubit<JoinGroupchatState> {
  JoinGroupchatCubit() : super(JoinGroupchatState());

  void onNickChanged(String nick) {
    emit(
      state.copyWith(
        nick: nick,
      ),
    );
  }

  void reset() {
    emit(
      state.copyWith(
        nick: '',
        nickError: null,
        isWorking: false,
      ),
    );
  }

  Future<void> startGroupchat(String jid) async {
    // Assuming that the JID has been validated before this step

    if (state.nick.isEmpty) {
      emit(state.copyWith(nickError: t.pages.newconversation.nullNickname));
      return;
    }

    emit(
      state.copyWith(
        isWorking: true,
      ),
    );

    // ignore: cast_nullable_to_non_nullable
    final result = await getForegroundService().send(
      JoinGroupchatCommand(
        jid: jid,
        nick: state.nick,
      ),
    );
    if (result is ErrorEvent) {
      final error = result.errorId == ErrorType.remoteServerNotFound.value ||
              result.errorId == ErrorType.remoteServerTimeout.value
          ? t.errors.newChat.remoteServerError
          : t.errors.newChat.unknown;
      emit(
        state.copyWith(
          nickError: error,
          isWorking: false,
        ),
      );
      return;
    }

    reset();
    final joinEvent = result! as JoinGroupchatResult;

    await GetIt.I.get<ConversationsCubit>().addConversation(
          joinEvent.conversation,
        );

    await GetIt.I.get<ConversationCubit>().request(
          joinEvent.conversation.jid,
          joinEvent.conversation.title,
          joinEvent.conversation.avatarPath,
          removeUntilConversations: true,
        );
  }
}
