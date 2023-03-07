import 'package:bloc/bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:move_to_background/move_to_background.dart';
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
    on<ItemRemovedEvent>(_onItemRemoved);
  }

  /// Pick files. Returns either a list of paths to attach or null if the process has
  /// been cancelled.
  Future<List<String>?> _pickFiles(SendFilesType type) async {
    final fileType =
        type == SendFilesType.image ? FileType.image : FileType.any;
    final result = await FilePicker.platform
        .pickFiles(type: fileType, allowMultiple: true);

    if (result == null) return null;

    return result.files.map((PlatformFile file) => file.path!).toList();
  }

  Future<void> _sendFilesRequested(
    SendFilesPageRequestedEvent event,
    Emitter<SendFilesState> emit,
  ) async {
    List<String> files;
    if (event.paths != null) {
      files = event.paths!;
    } else {
      final pickedFiles = await _pickFiles(event.type);
      if (pickedFiles == null) return;

      files = pickedFiles;
    }

    emit(
      state.copyWith(
        files: files,
        index: 0,
        recipients: event.recipients,
      ),
    );

    NavigationEvent navEvent;
    if (event.popEntireStack) {
      navEvent = PushedNamedAndRemoveUntilEvent(
        const NavigationDestination(sendFilesRoute),
        (_) => false,
      );
    } else {
      navEvent = PushedNamedEvent(
        const NavigationDestination(
          sendFilesRoute,
        ),
      );
    }

    GetIt.I.get<NavigationBloc>().add(navEvent);
  }

  Future<void> _onIndexSet(
    IndexSetEvent event,
    Emitter<SendFilesState> emit,
  ) async {
    emit(state.copyWith(index: event.index));
  }

  Future<void> _onAddFilesRequested(
    AddFilesRequestedEvent event,
    Emitter<SendFilesState> emit,
  ) async {
    final files = await _pickFiles(SendFilesType.generic);
    if (files == null) return;

    emit(
      state.copyWith(
        files: List.from(state.files)..addAll(files),
      ),
    );
  }

  Future<void> _onFileSendingRequested(
    FileSendingRequestedEvent event,
    Emitter<SendFilesState> emitter,
  ) async {
    await MoxplatformPlugin.handler.getDataSender().sendData(
          SendFilesCommand(
            paths: state.files,
            recipients: state.recipients,
          ),
          awaitable: false,
        );

    // Return to the last page
    final bloc = GetIt.I.get<NavigationBloc>();
    final canPop = bloc.canPop();
    NavigationEvent navEvent;
    if (canPop) {
      navEvent = PoppedRouteEvent();
    } else {
      navEvent = PushedNamedAndRemoveUntilEvent(
        const NavigationDestination(conversationsRoute),
        (_) => false,
      );
    }

    bloc.add(navEvent);
    if (!canPop) await MoveToBackground.moveTaskToBack();
  }

  Future<void> _onItemRemoved(
    ItemRemovedEvent event,
    Emitter<SendFilesState> emit,
  ) async {
    // Go to the last page if we would otherwise remove the last item on the
    if (state.files.length == 1) {
      GetIt.I.get<NavigationBloc>().add(PoppedRouteEvent());
      return;
    }

    final files = List<String>.from(state.files)..removeAt(event.index);

    var index = state.index;
    if (index == 0 || index != state.files.length - 1) {
      // Do nothing to prevent out of bounds
    } else {
      index--;
    }

    emit(
      state.copyWith(
        files: files,
        index: index,
      ),
    );
  }
}
