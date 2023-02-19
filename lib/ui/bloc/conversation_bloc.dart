import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxlib/moxlib.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart' as events;
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/shared/models/reaction.dart';
import 'package:moxxyv2/ui/bloc/conversations_bloc.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/bloc/sendfiles_bloc.dart';
import 'package:moxxyv2/ui/bloc/sharedmedia_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

part 'conversation_bloc.freezed.dart';
part 'conversation_event.dart';
part 'conversation_state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  ConversationBloc()
    : _currentChatState = ChatState.gone,
      _lastChangeTimestamp = 0,
      super(ConversationState()) {
    on<RequestedConversationEvent>(_onRequestedConversation);
    on<InitConversationEvent>(_onInit);
    on<JidBlockedEvent>(_onJidBlocked);
    on<JidAddedEvent>(_onJidAdded);
    on<CurrentConversationResetEvent>(_onCurrentConversationReset);
    on<MessageUpdatedEvent>(_onMessageUpdated);
    on<ConversationUpdatedEvent>(_onConversationUpdated);
    on<AppStateChanged>(_onAppStateChanged);
    on<BackgroundChangedEvent>(_onBackgroundChanged);
    on<ImagePickerRequestedEvent>(_onImagePickerRequested);
    on<FilePickerRequestedEvent>(_onFilePickerRequested);
    on<OmemoSetEvent>(_onOmemoSet);
    on<MessageRetractedEvent>(_onMessageRetracted);
    on<SendButtonDragStartedEvent>(_onDragStarted);
    on<SendButtonDragEndedEvent>(_onDragEnded);
    on<SendButtonLockedEvent>(_onSendButtonLocked);
    on<SendButtonLockPressedEvent>(_onSendButtonLockPressed);
    on<RecordingCanceledEvent>(_onRecordingCanceled);
    on<ReactionAddedEvent>(_onReactionAdded);
    on<ReactionRemovedEvent>(_onReactionRemoved);
    on<StickerSentEvent>(_onStickerSent);

    _audioRecorder = Record();
  }
  /// The current chat state with the conversation partner
  ChatState _currentChatState;
  /// Timer to be able to send <paused /> notifications
  Timer? _composeTimer;
  /// The last time the text has been changed
  int _lastChangeTimestamp;

  /// The audio recorder
  late Record _audioRecorder;
  DateTime? _recordingStart;
  
  void _setLastChangeTimestamp() {
    _lastChangeTimestamp = DateTime.now().millisecondsSinceEpoch;
  }
  
  void _startComposeTimer() {
    if (_composeTimer != null) return;

    _composeTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - _lastChangeTimestamp >= 3000) {
          // No change since 5 seconds
          _updateChatState(ChatState.paused);
          _stopComposeTimer();
        }
      }
    );
  }

  void _stopComposeTimer() {
    if (_composeTimer == null) return;

    _composeTimer!.cancel();
    _composeTimer = null;
  }
  
  bool _isSameConversation(String jid) => jid == state.conversation?.jid;
  
  /// Returns true if [msg] is meant for the open conversation. False otherwise.
  bool _isMessageForConversation(Message msg) => msg.conversationJid == state.conversation?.jid;

  /// Updates the local chat state and sends a chat state notification to the conversation
  /// partner.
  void _updateChatState(ChatState s) {
    if (s == _currentChatState) return;

    _currentChatState = s;
    MoxplatformPlugin.handler.getDataSender().sendData(
      SendChatStateCommand(
        state: s.toString().split('.').last,
        jid: state.conversation!.jid,
      ),
      awaitable: false,
    );
  }
  
  Future<void> _onInit(InitConversationEvent event, Emitter<ConversationState> emit) async {
    emit(
      state.copyWith(backgroundPath: event.backgroundPath),
    );
  }
  
  Future<void> _onRequestedConversation(RequestedConversationEvent event, Emitter<ConversationState> emit) async {
    final cb = GetIt.I.get<ConversationsBloc>();
    await cb.waitUntilInitialized();
    final conversation = firstWhereOrNull(
      cb.state.conversations,
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

    _updateChatState(ChatState.active);

    final navEvent = event.removeUntilConversations ? (
      PushedNamedAndRemoveUntilEvent(
        NavigationDestination(
          conversationRoute,
          arguments: event.jid,
        ),
        ModalRoute.withName(conversationsRoute),
      )
    ) : (
      PushedNamedEvent(
        NavigationDestination(
          conversationRoute,
          arguments: event.jid,
        ),
      )
    );

    GetIt.I.get<NavigationBloc>().add(navEvent);

    await MoxplatformPlugin.handler.getDataSender().sendData(
      SetOpenConversationCommand(jid: event.jid),
      awaitable: false,
    );
    GetIt.I.get<SharedMediaBloc>().add(
      SetSharedMedia(
        conversation.title,
        conversation.jid,
        conversation.sharedMedia,
      ),
    );
  }

  Future<void> _onJidBlocked(JidBlockedEvent event, Emitter<ConversationState> emit) async {
    // TODO(Unknown): Maybe have some state here
    await MoxplatformPlugin.handler.getDataSender().sendData(
      BlockJidCommand(jid: state.conversation!.jid),
    );
  }

  Future<void> _onJidAdded(JidAddedEvent event, Emitter<ConversationState> emit) async {
    // Just update the state here. If it does not work, then the next conversation
    // update will fix it.
    emit(
      state.copyWith(
        conversation: state.conversation!.copyWith(
          inRoster: true,
        ),
      ),
    );

    await MoxplatformPlugin.handler.getDataSender().sendData(
      AddContactCommand(jid: state.conversation!.jid),
    );
  }

  Future<void> _onCurrentConversationReset(CurrentConversationResetEvent event, Emitter<ConversationState> emit) async {
    GetIt.I.get<SharedMediaBloc>().add(JidRemovedEvent());
    _updateChatState(ChatState.gone);

    // Reset conversation so that we don't accidentally send chat states to chats
    // that are not currently focused.
    emit(
      state.copyWith(
        conversation: null,
      ),
    );

    await MoxplatformPlugin.handler.getDataSender().sendData(
      SetOpenConversationCommand(),
      awaitable: false,
    );
  }

  Future<void> _onMessageUpdated(MessageUpdatedEvent event, Emitter<ConversationState> emit) async {
    if (!_isMessageForConversation(event.message)) return;

    // TODO(Unknown): Check if we are iterating the correct wa
    // Small trick: The newer messages are much more likely to be updated than
    // older messages.
    /*
    final messages = state.messages;
    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i].id == event.message.id) {
        print("Found message to update");
        messages[i] = event.message;
        break;
      }
    }
    */
  }

  Future<void> _onConversationUpdated(ConversationUpdatedEvent event, Emitter<ConversationState> emit) async {
    if (!_isSameConversation(event.conversation.jid)) return;

    emit(state.copyWith(conversation: event.conversation));
  }

  Future<void> _onAppStateChanged(AppStateChanged event, Emitter<ConversationState> emit) async {
    if (state.conversation == null) return;

    if (event.open) {
      _updateChatState(ChatState.active);
    } else {
      _stopComposeTimer();
      _updateChatState(ChatState.gone);
    }
  }

  Future<void> _onBackgroundChanged(BackgroundChangedEvent event, Emitter<ConversationState> emit) async {
    return emit(state.copyWith(backgroundPath: event.backgroundPath));
  }

  Future<void> _onImagePickerRequested(ImagePickerRequestedEvent event, Emitter<ConversationState> emit) async {
    GetIt.I.get<SendFilesBloc>().add(
      SendFilesPageRequestedEvent([state.conversation!.jid], SendFilesType.image),
    );
  }

  Future<void> _onFilePickerRequested(FilePickerRequestedEvent event, Emitter<ConversationState> emit) async {
    GetIt.I.get<SendFilesBloc>().add(
      SendFilesPageRequestedEvent([state.conversation!.jid], SendFilesType.generic),
    );
  }

  Future<void> _onOmemoSet(OmemoSetEvent event, Emitter<ConversationState> emit) async {
    emit(
      state.copyWith(
        conversation: state.conversation!.copyWith(
          encrypted: event.enabled,
        ),
      ),
    );

    await MoxplatformPlugin.handler.getDataSender().sendData(
      SetOmemoEnabledCommand(enabled: event.enabled, jid: state.conversation!.jid),
      awaitable: false,
    );
  }

  Future<void> _onMessageRetracted(MessageRetractedEvent event, Emitter<ConversationState> emit) async {
    await MoxplatformPlugin.handler.getDataSender().sendData(
      RetractMessageCommentCommand(
        originId: event.id,
        conversationJid: state.conversation!.jid,
      ),
      awaitable: false,
    );
  }

  Future<void> _onDragStarted(SendButtonDragStartedEvent event, Emitter<ConversationState> emit) async {
    final status = await Permission.speech.status;
    if (status.isDenied) {
      await Permission.speech.request();
      return;
    }

    emit(
      state.copyWith(
        isDragging: true,
        isRecording: true,
      ),
    );
    
    final now = DateTime.now();
    _recordingStart = now;
    final tempDir = await getTemporaryDirectory();
    final timestamp = '${now.year}${now.month}${now.day}${now.hour}${now.minute}${now.second}';
    final tempFile = path.join(tempDir.path, 'audio_$timestamp.aac');
    await _audioRecorder.start(
      path: tempFile,
    );
  }

  Future<void> _handleRecordingEnd() async {
    // Prevent messages of really short duration being sent
    final now = DateTime.now();
    if (now.difference(_recordingStart!).inSeconds < 1) {
      await Fluttertoast.showToast(
        msg: t.warnings.conversation.holdForLonger,
        gravity: ToastGravity.SNACKBAR,
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    // Warn if something unexpected happened
    final recordingPath = await _audioRecorder.stop();
    if (recordingPath == null) {
      await Fluttertoast.showToast(
        msg: t.errors.conversation.audioRecordingError,
        gravity: ToastGravity.SNACKBAR,
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    // Send the file
    await MoxplatformPlugin.handler.getDataSender().sendData(
      SendFilesCommand(
        paths: [recordingPath],
        recipients: [state.conversation!.jid],
      ),
      awaitable: false,
    );
  }
  
  Future<void> _onDragEnded(SendButtonDragEndedEvent event, Emitter<ConversationState> emit) async {
    final recording = state.isRecording;
    emit(
      state.copyWith(
        isDragging: false,
        isLocked: false,
        isRecording: false,
      ),
    );

    if (recording) {
      await _handleRecordingEnd();
    }
  }

  Future<void> _onSendButtonLocked(SendButtonLockedEvent event, Emitter<ConversationState> emit) async {
    Vibrate.feedback(FeedbackType.light);

    emit(state.copyWith(isLocked: true));
  }

  Future<void> _onSendButtonLockPressed(SendButtonLockPressedEvent event, Emitter<ConversationState> emit) async {
    final recording = state.isRecording;
    emit(
      state.copyWith(
        isLocked: false,
        isDragging: false,
        isRecording: false,
      ),
    );

    if (recording) {
      await _handleRecordingEnd();
    }
  }

  Future<void> _onRecordingCanceled(RecordingCanceledEvent event, Emitter<ConversationState> emit) async {
    Vibrate.feedback(FeedbackType.heavy);

    emit(
      state.copyWith(
        isLocked: false,
        isDragging: false,
        isRecording: false,
      ),
    );

    final file = await _audioRecorder.stop();
    unawaited(File(file!).delete());
  }

  Future<void> _onReactionAdded(ReactionAddedEvent event, Emitter<ConversationState> emit) async {
    // TODO: Fix
    // Check if such a reaction already exists
    // final message = state.messages[event.index];
    // final msgs = List<Message>.from(state.messages);
    // final reactionIndex = message.reactions.indexWhere(
    //   (Reaction r) => r.emoji == event.emoji,
    // );
    // if (reactionIndex != -1) {
    //   // Ignore the request when the reaction would be invalid
    //   final reaction = message.reactions[reactionIndex];
    //   if (reaction.reactedBySelf) return;

    //   final reactions = List<Reaction>.from(message.reactions);
    //   reactions[reactionIndex] = reaction.copyWith(
    //     reactedBySelf: true,
    //   );
    //   msgs[event.index] = message.copyWith(
    //     reactions: reactions,
    //   );
    // } else {
    //   // The reaction is new
    //   msgs[event.index] = message.copyWith(
    //     reactions: [
    //       ...message.reactions,
    //       Reaction(
    //         [],
    //         event.emoji,
    //         true,
    //       ),
    //     ],
    //   );
    // }
    
    // emit(
    //   state.copyWith(
    //     messages: msgs, 
    //   ),
    // );

    // await MoxplatformPlugin.handler.getDataSender().sendData(
    //   AddReactionToMessageCommand(
    //     messageId: message.id,
    //     emoji: event.emoji,
    //     conversationJid: message.conversationJid,
    //   ),
    //   awaitable: false,
    // );
  }

  Future<void> _onReactionRemoved(ReactionRemovedEvent event, Emitter<ConversationState> emit) async {
    // TODO
    // final message = state.messages[event.index];
    // final msgs = List<Message>.from(state.messages);
    // final reactionIndex = message.reactions.indexWhere(
    //   (Reaction r) => r.emoji == event.emoji,
    // );

    // // We assume that reactionIndex >= 0
    // assert(reactionIndex >= 0, 'The reaction must be found');
    // final reactions = List<Reaction>.from(message.reactions);
    // if (message.reactions[reactionIndex].senders.isEmpty) {
    //   reactions.removeAt(reactionIndex);
    // } else {
    //   reactions[reactionIndex] = reactions[reactionIndex].copyWith(
    //     reactedBySelf: false,
    //   );
    // }
    // msgs[event.index] = message.copyWith(reactions: reactions);
    // emit(
    //   state.copyWith(
    //     messages: msgs,
    //   ),
    // );

    // await MoxplatformPlugin.handler.getDataSender().sendData(
    //   RemoveReactionFromMessageCommand(
    //     messageId: message.id,
    //     emoji: event.emoji,
    //     conversationJid: message.conversationJid,
    //   ),
    //   awaitable: false,
    // );
  }

  Future<void> _onStickerSent(StickerSentEvent event, Emitter<ConversationState> emit) async {
    await MoxplatformPlugin.handler.getDataSender().sendData(
      SendStickerCommand(
        stickerPackId: event.stickerPackId,
        stickerHashKey: event.stickerHashKey,
        recipient: state.conversation!.jid,
      ),
      awaitable: false,
    );
    
    // Close the picker
  }
}
