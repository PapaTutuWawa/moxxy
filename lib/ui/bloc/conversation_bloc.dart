import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/ui/bloc/conversations_bloc.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/bloc/sendfiles_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';

part 'conversation_bloc.freezed.dart';
part 'conversation_event.dart';
part 'conversation_state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  ConversationBloc() : super(ConversationState()) {
    on<RequestedConversationEvent>(_onRequestedConversation);
    on<InitConversationEvent>(_onInit);
    on<JidBlockedEvent>(_onJidBlocked);
    on<JidAddedEvent>(_onJidAdded);
    on<CurrentConversationResetEvent>(_onCurrentConversationReset);
    on<ConversationUpdatedEvent>(_onConversationUpdated);
    on<BackgroundChangedEvent>(_onBackgroundChanged);
    on<ImagePickerRequestedEvent>(_onImagePickerRequested);
    on<FilePickerRequestedEvent>(_onFilePickerRequested);
    on<OmemoSetEvent>(_onOmemoSet);
  }

  bool _isSameConversation(String jid) => jid == state.conversation?.jid;

  Future<void> _onInit(
    InitConversationEvent event,
    Emitter<ConversationState> emit,
  ) async {
    emit(
      state.copyWith(backgroundPath: event.backgroundPath),
    );
  }

  Future<void> _onRequestedConversation(
    RequestedConversationEvent event,
    Emitter<ConversationState> emit,
  ) async {
    final cb = GetIt.I.get<ConversationsBloc>();
    await cb.waitUntilInitialized();
    final conversation = cb.state.conversations.firstWhereOrNull(
      (Conversation c) => c.jid == event.jid,
    )!;
    emit(
      state.copyWith(
        conversation: conversation,
        isLocked: false,
        isDragging: false,
        isRecording: false,
      ),
    );

    final navEvent = event.removeUntilConversations
        ? (PushedNamedAndRemoveUntilEvent(
            NavigationDestination(
              conversationRoute,
              arguments: event.jid,
            ),
            ModalRoute.withName(conversationsRoute),
          ))
        : (PushedNamedEvent(
            NavigationDestination(
              conversationRoute,
              arguments: event.jid,
            ),
          ));

    GetIt.I.get<NavigationBloc>().add(navEvent);

    await MoxplatformPlugin.handler.getDataSender().sendData(
          SetOpenConversationCommand(jid: event.jid),
          awaitable: false,
        );
  }

  Future<void> _onJidBlocked(
    JidBlockedEvent event,
    Emitter<ConversationState> emit,
  ) async {
    // TODO(Unknown): Maybe have some state here
    await MoxplatformPlugin.handler.getDataSender().sendData(
          BlockJidCommand(jid: state.conversation!.jid),
        );
  }

  Future<void> _onJidAdded(
    JidAddedEvent event,
    Emitter<ConversationState> emit,
  ) async {
    // Just update the state here. If it does not work, then the next conversation
    // update will fix it.
    emit(
      state.copyWith(
        conversation: state.conversation!.copyWith(
          showAddToRoster: false,
        ),
      ),
    );

    await MoxplatformPlugin.handler.getDataSender().sendData(
          AddContactCommand(jid: state.conversation!.jid),
        );
  }

  Future<void> _onCurrentConversationReset(
    CurrentConversationResetEvent event,
    Emitter<ConversationState> emit,
  ) async {
    await MoxplatformPlugin.handler.getDataSender().sendData(
          SetOpenConversationCommand(),
          awaitable: false,
        );
  }

  Future<void> _onConversationUpdated(
    ConversationUpdatedEvent event,
    Emitter<ConversationState> emit,
  ) async {
    if (!_isSameConversation(event.conversation.jid)) return;

    emit(state.copyWith(conversation: event.conversation));
  }

  Future<void> _onBackgroundChanged(
    BackgroundChangedEvent event,
    Emitter<ConversationState> emit,
  ) async {
    return emit(state.copyWith(backgroundPath: event.backgroundPath));
  }

  Future<void> _onImagePickerRequested(
    ImagePickerRequestedEvent event,
    Emitter<ConversationState> emit,
  ) async {
    GetIt.I.get<SendFilesBloc>().add(
          SendFilesPageRequestedEvent(
            [state.conversation!.jid],
            SendFilesType.image,
          ),
        );
  }

  Future<void> _onFilePickerRequested(
    FilePickerRequestedEvent event,
    Emitter<ConversationState> emit,
  ) async {
    GetIt.I.get<SendFilesBloc>().add(
          SendFilesPageRequestedEvent(
            [state.conversation!.jid],
            SendFilesType.generic,
          ),
        );
  }

  Future<void> _onOmemoSet(
    OmemoSetEvent event,
    Emitter<ConversationState> emit,
  ) async {
    emit(
      state.copyWith(
        conversation: state.conversation!.copyWith(
          encrypted: event.enabled,
        ),
      ),
    );

    await MoxplatformPlugin.handler.getDataSender().sendData(
          SetOmemoEnabledCommand(
            enabled: event.enabled,
            jid: state.conversation!.jid,
          ),
          awaitable: false,
        );
  }
}
