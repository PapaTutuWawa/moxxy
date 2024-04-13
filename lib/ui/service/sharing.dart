import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxyv2/shared/constants.dart';
import 'package:moxxyv2/ui/state/account.dart';
import 'package:moxxyv2/ui/state/conversation.dart';
import 'package:moxxyv2/ui/state/sendfiles.dart';
import 'package:moxxyv2/ui/state/share_selection.dart';
import 'package:share_handler/share_handler.dart';

/// This service is responsible for storing a sharing request and or executing it.
class UISharingService {
  /// A possible media object that was shared to Moxxy while the app was closed.
  SharedMedia? _media;

  /// Flag indicating whether the service has already been initialized or not.
  bool _initialized = false;

  /// Logger
  final Logger _log = Logger('UISharingService');

  /// If [media] is non-null, forwards the metadata to the ShareSelectionBloc, which
  /// will open the share dialog.
  /// If [media] is null, then nothing will happen.
  Future<void> _handleSharedMedia(SharedMedia? media) async {
    if (media == null) return;

    _log.finest('Handling media (identifier: ${media.conversationIdentifier})');
    final attachments = media.attachments ?? [];

    if (media.conversationIdentifier != null) {
      _log.finest('Treating share as direct share');

      // Handle shares to the self-chat
      final conversationJid =
          media.conversationIdentifier == selfChatShareFakeJid
              ? ''
              : media.conversationIdentifier;

      // Handle direct shares
      if (media.content != null) {
        await GetIt.I.get<ConversationCubit>().request(
              conversationJid!,
              '',
              null,
              removeUntilConversations: true,
              initialText: media.content,
            );
      } else {
        final isMedia = attachments.every(
          (attachment) =>
              attachment!.type == SharedAttachmentType.image ||
              attachment.type == SharedAttachmentType.video,
        );
        await GetIt.I.get<SendFilesCubit>().request(
          [
            // NOTE: We put in some stub values (except for the JID) as the UI will fetch it.
            SendFilesRecipient(
              conversationJid!,
              conversationJid,
              null,
              null,
              false,
            ),
          ],
          isMedia ? SendFilesType.media : SendFilesType.generic,
          paths: attachments.map((attachment) => attachment!.path).toList(),
          hasRecipientData: false,
          popEntireStack: true,
        );
      }
    } else {
      GetIt.I.get<ShareSelectionCubit>().request(
            attachments.map((a) => a!.path).toList(),
            media.content,
            media.content != null
                ? ShareSelectionType.text
                : ShareSelectionType.media,
          );
    }

    await clearSharedMedia();
  }

  /// Clears all shared media data we (and the share_handler plugin has) have.
  Future<void> clearSharedMedia() async {
    _log.finest('Clearing media');
    await ShareHandlerPlatform.instance.resetInitialSharedMedia();
    _media = null;
  }

  /// True if we have early media. False if not.
  bool get hasEarlyMedia => _media != null;

  /// If Moxxy was started with a share intent, then this function is equivalent to
  /// [UISharingService._handleSharedMedia] but called with said share intent's metadata.
  Future<void> handleEarlySharedMedia() async {
    await _handleSharedMedia(_media);
  }

  /// Sets up streams for reacting to share intents. Also stores an initial shared media
  /// object for later retrieval, if available.
  Future<void> initialize() async {
    if (_initialized) return;

    final media = await ShareHandlerPlatform.instance.getInitialSharedMedia();
    if (media != null) {
      _log.finest('initialize: Early media is not null');
      _media = media;
    }

    ShareHandlerPlatform.instance.sharedMediaStream
        .listen((SharedMedia media) async {
      if (GetIt.I.get<AccountCubit>().hasActiveAccount()) {
        _log.finest('stream: Handle shared media via stream');
        await _handleSharedMedia(media);
      }

      await ShareHandlerPlatform.instance.resetInitialSharedMedia();
    });

    _initialized = true;
  }
}
