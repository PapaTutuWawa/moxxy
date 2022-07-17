import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/media.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0085.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

class ConversationChatStateConverter implements JsonConverter<ChatState, Map<String, dynamic>> {
  const ConversationChatStateConverter();

  @override
  ChatState fromJson(Map<String, dynamic> json) => chatStateFromString(json['chatState'] as String);
  
  @override
  Map<String, dynamic> toJson(ChatState state) => <String, String>{
    'chatState': chatStateToString(state),
  };
}

@freezed
class Conversation with _$Conversation {
  factory Conversation(
    String title,
    String lastMessageBody,
    String avatarUrl,
    String jid,
    int unreadCounter,
    // NOTE: In milliseconds since Epoch or -1 if none has ever happened
    int lastChangeTimestamp,
    List<SharedMedium> sharedMedia,
    int id,
    // Indicates if the conversation should be shown on the homescreen
    bool open,
    // Indicates, if [jid] is a regular user, if the user is in the roster.
    bool inRoster,
    // The subscription state of the roster item
    String subscription,
    // The current chat state
    @ConversationChatStateConverter() ChatState chatState,
  ) = _Conversation;

  // JSON
  factory Conversation.fromJson(Map<String, dynamic> json) => _$ConversationFromJson(json);
}

/// Sorts conversations in descending order by their last change timestamp.
int compareConversation(Conversation a, Conversation b) {
  return -1 * Comparable.compare(a.lastChangeTimestamp, b.lastChangeTimestamp);
}
