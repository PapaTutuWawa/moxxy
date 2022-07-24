import 'package:bloc/bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';

part 'sendfiles_bloc.freezed.dart';
part 'sendfiles_event.dart';
part 'sendfiles_state.dart';

class SendFilesBloc extends Bloc<SendFilesEvent, SendFilesState> {
  SendFilesBloc() : super(SendFilesState()) {
    on<SendFilesPageRequestedEvent>(_sendFilesRequested);
    on<IndexSetEvent>(_onIndexSet);
    on<AddFilesRequestedEvent>(_onAddFilesRequested);
    on<FileSendingRequestedEvent>(_onFileSendingRequested);
  }

  Future<void> _sendFilesRequested(SendFilesPageRequestedEvent event, Emitter<SendFilesState> emit) async {
    emit(
      state.copyWith(
        files: event.files,
        index: 0,
        conversationJid: event.jid,
      ),
    );
    GetIt.I.get<NavigationBloc>().add(
      PushedNamedEvent(
        const NavigationDestination(
          sendFilesRoute,
        ),
      ),
    );
  }

  Future<void> _onIndexSet(IndexSetEvent event, Emitter<SendFilesState> emit) async {
    emit(state.copyWith(index: event.index));
  }

  Future<void> _onAddFilesRequested(AddFilesRequestedEvent event, Emitter<SendFilesState> emit) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: true);

    if (result != null) {
      emit(
        state.copyWith(
          files: List.from(state.files)
            ..addAll(
              result.files.map((PlatformFile file) => file.path!).toList(),
            ),
        ),
      );
    }
  }

  Future<void> _onFileSendingRequested(FileSendingRequestedEvent event, Emitter<SendFilesState> emitter) async {
    await MoxplatformPlugin.handler.getDataSender().sendData(
      SendFilesCommand(
        paths: state.files,
        jid: state.conversationJid!,
      ),
      awaitable: false,
    );

    // Return to the last page
    GetIt.I.get<NavigationBloc>().add(PoppedRouteEvent());
  }
}
