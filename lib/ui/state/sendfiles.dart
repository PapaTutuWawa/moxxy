import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:move_to_background/move_to_background.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/state/navigation.dart';

part 'sendfiles.freezed.dart';
part 'sendfiles.g.dart';

enum SendFilesType {
  media,
  generic,
}

@freezed
class SendFilesRecipient with _$SendFilesRecipient {
  factory SendFilesRecipient(
    String jid,
    String title,
    String? avatar,
    String? avatarHash,
    bool hasContactId,
  ) = _SendFilesRecipient;

  /// JSON
  factory SendFilesRecipient.fromJson(Map<String, dynamic> json) =>
      _$SendFilesRecipientFromJson(json);
}

@freezed
class SendFilesState with _$SendFilesState {
  factory SendFilesState({
    // List of file paths that the user wants to send
    @Default(<String>[]) List<String> files,

    // The currently selected path
    @Default(0) int index,

    // The chat that is currently active
    @Default(<SendFilesRecipient>[]) List<SendFilesRecipient> recipients,

    // Flag indicating whether we can immediately display the conversation indicator (true)
    // or have to first fetch that data from the service (false).
    @Default(false) bool hasRecipientData,
  }) = _SendFilesState;
}

class SendFilesCubit extends Cubit<SendFilesState> {
  SendFilesCubit() : super(SendFilesState());

  // ignore: comment_references
  /// Whether a single [RemovedCacheFilesEvent] event should be ignored.
  bool _shouldIgnoreDeletionRequest = false;

  /// Logger.
  final Logger _log = Logger('SendFilesBloc');

  /// Pick files. Returns either a list of paths to attach or null if the process has
  /// been cancelled.
  Future<List<String>?> _pickFiles(SendFilesType type) async {
    final result = await safePickFiles(
      type == SendFilesType.media
          ? FilePickerType.imageAndVideo
          : FilePickerType.generic,
    );

    if (result == null) return null;

    return result.files!;
  }

  Future<void> request(
    List<SendFilesRecipient> recipients,
    SendFilesType type, {
    List<String>? paths,
    bool hasRecipientData = true,
    bool popEntireStack = false,
  }) async {
    List<String> files;
    if (paths != null) {
      files = paths;
    } else {
      final pickedFiles = await _pickFiles(type);
      if (pickedFiles == null) return;

      files = pickedFiles;
    }

    _shouldIgnoreDeletionRequest = false;
    emit(
      state.copyWith(
        files: files,
        index: 0,
        recipients: recipients,
        hasRecipientData: hasRecipientData,
      ),
    );

    final cubit = GetIt.I.get<Navigation>();
    const destination = NavigationDestination(sendFilesRoute);
    if (popEntireStack) {
      cubit.pushNamedAndRemoveUntil(
        destination,
        (_) => false,
      );
    } else {
      cubit.pushNamed(destination);
    }
  }

  void setIndex(int index) {
    emit(state.copyWith(index: index));
  }

  Future<void> addFiles() async {
    final files = await _pickFiles(SendFilesType.generic);
    if (files == null) return;

    emit(
      state.copyWith(
        files: List<String>.from(state.files)..addAll(files),
      ),
    );
  }

  Future<void> submit() async {
    await getForegroundService().send(
      SendFilesCommand(
        paths: state.files,
        recipients:
            state.recipients.map((SendFilesRecipient r) => r.jid).toList(),
      ),
      awaitable: false,
    );
    _shouldIgnoreDeletionRequest = true;

    // Return to the last page
    final cubit = GetIt.I.get<Navigation>();
    final canPop = cubit.canPop();
    if (canPop) {
      cubit.pop();
    } else {
      cubit.pushNamedAndRemoveUntil(
        const NavigationDestination(homeRoute),
        (route) => false,
      );
    }

    if (!canPop) await MoveToBackground.moveTaskToBack();
  }

  void remove(int index) {
    // Go to the last page if we would otherwise remove the last item on the
    if (state.files.length == 1) {
      GetIt.I.get<Navigation>().pop();
      return;
    }

    final files = List<String>.from(state.files)..removeAt(index);

    var i = state.index;
    if (i == 0 || i != state.files.length - 1) {
      // Do nothing to prevent out of bounds
    } else {
      i--;
    }

    emit(
      state.copyWith(
        files: files,
        index: i,
      ),
    );
  }

  Future<void> removeCacheFiles() async {
    if (_shouldIgnoreDeletionRequest) {
      _log.finest('Ignoring RemovedCacheFilesEvent.');
      _shouldIgnoreDeletionRequest = false;
      return;
    }

    await safelyRemovePickedFiles(state.files, null);
  }
}
