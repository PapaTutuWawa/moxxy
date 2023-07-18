import 'package:get_it/get_it.dart';
import 'package:moxlib/moxlib.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/service/preferences.dart';
import 'package:moxxyv2/shared/constants.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:share_handler/share_handler.dart';

/// The service responsible for handling the direct share feature.
class ShareService {
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
    // TODO: Use an appropriate avatar for self-chats
    final conversationImageFilePath =
        conversation.getAvatarPathWithOptionalContact(
      prefs.enableContactIntegration,
    );
    // Prevent empty JIDs as that messes with share_handler
    final conversationJid =
        conversation.isSelfChat ? selfChatShareFakeJid : conversation.jid;

    await ShareHandlerPlatform.instance.recordSentMessage(
      conversationIdentifier: conversationJid,
      conversationName: conversationName,
      conversationImageFilePath: conversationImageFilePath?.isEmpty ?? true
          ? null
          : conversationImageFilePath,
      serviceName: 'moxxy-share-recorder',
    );
  }
}
