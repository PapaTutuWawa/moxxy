import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/ui/bloc/conversations.dart';
import 'package:moxxyv2/ui/bloc/navigation.dart';
import 'package:moxxyv2/ui/bloc/sendfiles.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/pages/conversation/conversation.dart';

part 'conversation.freezed.dart';

enum SendButtonState {
  /// Open the speed dial when tapped.
  multi,

  /// Send the current message when tapped.
  send,

  /// Send the currently recorded voice message,
  sendVoiceMessage,

  /// Cancel the current correction when tapped.
  cancelCorrection,
}

const defaultSendButtonState = SendButtonState.multi;

@freezed
class ConversationState with _$ConversationState {
  factory ConversationState({
    @Default(null) Conversation? conversation,
    // TODO(Unknown): Just replace this with a separate BlocBuilder
    String? backgroundPath,

    // For recording
    @Default(false) bool isDragging,
    @Default(false) bool isLocked,
    @Default(false) bool isRecording,
  }) = _ConversationState;
}

class ConversationCubit extends Cubit<ConversationState> {
  ConversationCubit() : super(ConversationState());

  bool _isSameConversation(String jid) => jid == state.conversation?.jid;

  Future<void> init(
    String backgroundPath,
  ) async {
    emit(
      state.copyWith(backgroundPath: backgroundPath),
    );
  }

  Future<void> request(
    String jid,
    String title,
    String? avatarUrl, {
    bool removeUntilConversations = false,
    String? initialText,
  }) async {
    final cb = GetIt.I.get<ConversationsCubit>();
    await cb.waitUntilInitialized();
    final conversation = cb.getConversationByJid(jid)!;
    emit(
      state.copyWith(
        conversation: conversation,
        isLocked: false,
        isDragging: false,
        isRecording: false,
      ),
    );

    final cubit = GetIt.I.get<Navigation>();
    final destination = NavigationDestination(
      conversationRoute,
      arguments: ConversationPageArguments(
        jid,
        initialText,
        conversation.type,
      ),
    );
    if (removeUntilConversations) {
      await cubit.pushNamedAndRemoveUntil(
        destination,
        (route) => false,
      );
    } else {
      await cubit.pushNamed(destination);
    }

    await getForegroundService().send(
      SetOpenConversationCommand(jid: jid),
      awaitable: false,
    );
  }

  Future<void> block(String jid) async {
    // TODO(Unknown): Maybe have some state here
    await getForegroundService().send(
      BlockJidCommand(jid: state.conversation!.jid),
    );
  }

  Future<void> add(String jid) async {
    // Just update the state here. If it does not work, then the next conversation
    // update will fix it.
    emit(
      state.copyWith(
        conversation: state.conversation!.copyWith(
          showAddToRoster: false,
        ),
      ),
    );

    await getForegroundService().send(
      AddContactCommand(jid: state.conversation!.jid),
    );
  }

  Future<void> reset() async {
    await getForegroundService().send(
      SetOpenConversationCommand(),
      awaitable: false,
    );
  }

  void update(Conversation newConversation) {
    if (!_isSameConversation(newConversation.jid)) return;

    emit(state.copyWith(conversation: newConversation));
  }

  void onBackgroundChanged(String? backgroundPath) {
    return emit(state.copyWith(backgroundPath: backgroundPath));
  }

  Future<void> requestImagePicker() async {
    return GetIt.I.get<SendFilesCubit>().request(
      [
        SendFilesRecipient(
          state.conversation!.jid,
          state.conversation!.titleWithOptionalContact,
          state.conversation!.avatarPath,
          state.conversation!.avatarHash,
          state.conversation!.contactId != null,
        ),
      ],
      SendFilesType.media,
    );
  }

  Future<void> requestFilePicker() async {
    return GetIt.I.get<SendFilesCubit>().request(
      [
        SendFilesRecipient(
          state.conversation!.jid,
          state.conversation!.titleWithOptionalContact,
          state.conversation!.avatarPath,
          state.conversation!.avatarHash,
          state.conversation!.contactId != null,
        ),
      ],
      SendFilesType.generic,
    );
  }

  Future<void> setOmemo(bool enabled) async {
    emit(
      state.copyWith(
        conversation: state.conversation!.copyWith(
          encrypted: enabled,
        ),
      ),
    );

    await getForegroundService().send(
      SetOmemoEnabledCommand(
        enabled: enabled,
        jid: state.conversation!.jid,
      ),
      awaitable: false,
    );
  }
}
