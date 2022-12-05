import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:moxxyv2/shared/models/media.dart';
import 'package:moxxyv2/shared/models/message.dart';

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

class ConversationMessageConverter implements JsonConverter<Message?, Map<String, dynamic>> {
  const ConversationMessageConverter();

  @override
  Message? fromJson(Map<String, dynamic> json) {
    if (json['message'] == null) return null;

    return Message.fromJson(json['message']! as Map<String, dynamic>);
  }
  
  @override
  Map<String, dynamic> toJson(Message? message) => <String, dynamic>{
    'message': message?.toJson(),
  };
}

@freezed
class Conversation with _$Conversation {
  factory Conversation(
    String title,
    @ConversationMessageConverter() Message? lastMessage,
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
    // Whether the chat is muted (true = muted, false = not muted)
    bool muted,
    // Whether the conversation is encrypted or not (true = encrypted, false = unencrypted)
    bool encrypted,
    // The current chat state
    @ConversationChatStateConverter() ChatState chatState,
  ) = _Conversation;

  const Conversation._();
  
  /// JSON
  factory Conversation.fromJson(Map<String, dynamic> json) => _$ConversationFromJson(json);

  factory Conversation.fromDatabaseJson(Map<String, dynamic> json, bool inRoster, String subscription, List<Map<String, dynamic>> sharedMedia, Message? lastMessage) {
    return Conversation.fromJson({
      ...json,
      'muted': intToBool(json['muted']! as int),
      'open': intToBool(json['open']! as int),
      'sharedMedia': sharedMedia,
      'inRoster': inRoster,
      'subscription': subscription,
      'encrypted': intToBool(json['encrypted']! as int),
      'chatState': const ConversationChatStateConverter().toJson(ChatState.gone),
    }).copyWith(
      lastMessage: lastMessage,
    );
  }
  
  Map<String, dynamic> toDatabaseJson() {
    final map = toJson()
      ..remove('id')
      ..remove('chatState')
      ..remove('sharedMedia')
      ..remove('inRoster')
      ..remove('subscription')
      ..remove('lastMessage');

    return {
      ...map,
      'open': boolToInt(open),
      'muted': boolToInt(muted),
      'encrypted': boolToInt(encrypted),
      'lastMessageId': lastMessage?.id,
    };
  }

  /// True, when the chat state of the conversation indicates typing. False, if not.
  bool get isTyping => chatState == ChatState.composing;
}

/// Sorts conversations in descending order by their last change timestamp.
int compareConversation(Conversation a, Conversation b) {
  return -1 * Comparable.compare(a.lastChangeTimestamp, b.lastChangeTimestamp);
}
