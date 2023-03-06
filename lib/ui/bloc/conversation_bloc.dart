import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxlib/moxlib.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/ui/bloc/conversations_bloc.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/bloc/sendfiles_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

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
    on<SendButtonDragStartedEvent>(_onDragStarted);
    on<SendButtonDragEndedEvent>(_onDragEnded);
    on<SendButtonLockedEvent>(_onSendButtonLocked);
    on<SendButtonLockPressedEvent>(_onSendButtonLockPressed);
    on<RecordingCanceledEvent>(_onRecordingCanceled);

    _audioRecorder = Record();
  }

  /// The audio recorder
  late Record _audioRecorder;
  DateTime? _recordingStart;

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
          inRoster: true,
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

  Future<void> _onDragStarted(
      SendButtonDragStartedEvent event,
      Emitter<ConversationState> emit,
    ) async {
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
    final timestamp =
        '${now.year}${now.month}${now.day}${now.hour}${now.minute}${now.second}';
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

  Future<void> _onDragEnded(
      SendButtonDragEndedEvent event,
      Emitter<ConversationState> emit,
    ) async {
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

  Future<void> _onSendButtonLocked(
      SendButtonLockedEvent event,
      Emitter<ConversationState> emit,
    ) async {
    Vibrate.feedback(FeedbackType.light);

    emit(state.copyWith(isLocked: true));
  }

  Future<void> _onSendButtonLockPressed(
      SendButtonLockPressedEvent event,
      Emitter<ConversationState> emit,
    ) async {
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

  Future<void> _onRecordingCanceled(
      RecordingCanceledEvent event,
      Emitter<ConversationState> emit,
    ) async {
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
}
