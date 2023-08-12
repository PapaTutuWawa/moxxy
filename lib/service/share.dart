import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxlib/moxlib.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/service/preferences.dart';
import 'package:moxxyv2/shared/constants.dart';
import 'package:moxxyv2/shared/models/conversation.dart';

/// The service responsible for handling the direct share feature.
class ShareService {
  /// Logging.
  final Logger _log = Logger('ShareService');

  /// Updates the share shortcuts for [conversation]. If a message was received or
  /// sent in [conversation], this method should be called.
  Future<void> recordSentMessage(
    Conversation conversation,
  ) async {
    assert(
      implies(!conversation.isSelfChat, conversation.jid.isNotEmpty),
      'Only self-chats can have an empty JID',
    );
    final prefs = await GetIt.I.get<PreferencesService>().getPreferences();

    // Use the correct title if we share to the note-to-self chat.
    final conversationName = conversation.isSelfChat
        ? t.pages.conversations.speeddialAddNoteToSelf
        : conversation.getTitleWithOptionalContact(
            prefs.enableContactIntegration,
          );
    final conversationImageFilePath =
        conversation.getAvatarPathWithOptionalContact(
      prefs.enableContactIntegration,
    );
    // Prevent empty JIDs as that messes with share_handler
    final conversationJid =
        conversation.isSelfChat ? selfChatShareFakeJid : conversation.jid;

    _log.finest(
      'Creating direct share target "$conversationName" (jid=$conversationJid, avatarPath=$conversationImageFilePath)',
    );

    // Tell the system to create a direct share shortcut
    await MoxplatformPlugin.contacts.recordSentMessage(
      conversationName,
      conversationJid,
      avatarPath:
          conversationImageFilePath.isEmpty ? null : conversationImageFilePath,
      fallbackIcon: conversation.isSelfChat
          ? FallbackIconType.notes
          : FallbackIconType.person,
    );
  }
}
