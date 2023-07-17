import 'package:get_it/get_it.dart';
import 'package:moxxyv2/service/preferences.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:share_handler/share_handler.dart';

/// The service responsible for handling the direct share feature.
class ShareService {
  /// Updates the share shortcuts for [conversation]. If a message was received or
  /// sent in [conversation], this method should be called.
  Future<void> recordSentMessage(
    Conversation conversation,
  ) async {
    final prefs = await GetIt.I.get<PreferencesService>().getPreferences();
    await ShareHandlerPlatform.instance.recordSentMessage(
      conversationIdentifier: conversation.jid,
      conversationName: conversation.getTitleWithOptionalContact(
        prefs.enableContactIntegration,
      ),
      conversationImageFilePath: conversation.getAvatarPathWithOptionalContact(
        prefs.enableContactIntegration,
      ),
      serviceName: 'moxxy-share-recorder',
    );
  }
}
