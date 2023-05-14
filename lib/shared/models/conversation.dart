import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

class ConversationChatStateConverter
    implements JsonConverter<ChatState, Map<String, dynamic>> {
  const ConversationChatStateConverter();

  @override
  ChatState fromJson(Map<String, dynamic> json) =>
      chatStateFromString(json['chatState'] as String);

  @override
  Map<String, dynamic> toJson(ChatState state) => <String, String>{
        'chatState': chatStateToString(state),
      };
}

class ConversationMessageConverter
    implements JsonConverter<Message?, Map<String, dynamic>> {
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

enum ConversationType {
  @JsonValue('chat')
  chat,
  @JsonValue('note')
  note
}

@freezed
class Conversation with _$Conversation {
  factory Conversation(
    String title,
    @ConversationMessageConverter() Message? lastMessage,
    String avatarUrl,
    String jid,
    int unreadCounter,
    ConversationType type,
    // NOTE: In milliseconds since Epoch or -1 if none has ever happened
    int lastChangeTimestamp,
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
    @ConversationChatStateConverter() ChatState chatState, {
    // The id of the contact in the device's phonebook if it exists
    String? contactId,
    // The path to the contact avatar, if available
    String? contactAvatarPath,
    // The contact's display name, if it exists
    String? contactDisplayName,
  }) = _Conversation;

  const Conversation._();

  /// JSON
  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);

  factory Conversation.fromDatabaseJson(
    Map<String, dynamic> json,
    bool inRoster,
    String subscription,
    Message? lastMessage,
  ) {
    return Conversation.fromJson({
      ...json,
      'muted': intToBool(json['muted']! as int),
      'open': intToBool(json['open']! as int),
      'inRoster': inRoster,
      'subscription': subscription,
      'encrypted': intToBool(json['encrypted']! as int),
      'chatState':
          const ConversationChatStateConverter().toJson(ChatState.gone),
    }).copyWith(
      lastMessage: lastMessage,
    );
  }

  Map<String, dynamic> toDatabaseJson() {
    final map = toJson()
      ..remove('id')
      ..remove('chatState')
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

  /// The path to the avatar. This returns, if enabled, first the contact's avatar
  /// path, then the XMPP avatar's path. If not enabled, just returns the regular
  /// XMPP avatar's path.
  String? get avatarPathWithOptionalContact {
    if (GetIt.I.get<PreferencesBloc>().state.enableContactIntegration) {
      return contactAvatarPath ?? avatarUrl;
    }

    return avatarUrl;
  }

  /// The title of the chat. This returns, if enabled, first the contact's display
  /// name, then the XMPP chat title. If not enabled, just returns the XMPP chat
  /// title.
  String get titleWithOptionalContact {
    if (GetIt.I.get<PreferencesBloc>().state.enableContactIntegration) {
      return contactDisplayName ?? title;
    }

    return title;
  }
}

/// Sorts conversations in descending order by their last change timestamp.
int compareConversation(Conversation a, Conversation b) {
  return -1 * Comparable.compare(a.lastChangeTimestamp, b.lastChangeTimestamp);
}
