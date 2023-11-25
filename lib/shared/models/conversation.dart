import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:moxxyv2/service/preferences.dart';
import 'package:moxxyv2/shared/models/groupchat.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

class ConversationChatStateConverter
    implements JsonConverter<ChatState, Map<String, dynamic>> {
  const ConversationChatStateConverter();

  @override
  ChatState fromJson(Map<String, dynamic> json) =>
      ChatState.fromName(json['chatState'] as String);

  @override
  Map<String, dynamic> toJson(ChatState state) => <String, String>{
        'chatState': state.toName(),
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
  chat('chat'),
  note('note'),
  groupchat('groupchat');

  const ConversationType(this.value);
  final String value;

  static ConversationType fromString(String value) {
    switch (value) {
      case 'groupchat':
        return ConversationType.groupchat;
      case 'note':
        return ConversationType.note;
      case 'chat':
        return ConversationType.chat;
      default:
        // Should ideally never happen
        throw Exception();
    }
  }

  /// Returns the "type" attribute value for a message within the enum value's
  /// context.
  String toMessageType() {
    assert(
      this != ConversationType.note,
      'Chat states should not be sent to the self-chat',
    );

    switch (this) {
      case ConversationType.note:
      case ConversationType.chat:
        return 'chat';
      case ConversationType.groupchat:
        return 'groupchat';
    }
  }
}

class ConversationTypeConverter
    extends JsonConverter<ConversationType, String> {
  const ConversationTypeConverter();

  @override
  ConversationType fromJson(String json) {
    return ConversationType.fromString(json);
  }

  @override
  String toJson(ConversationType object) {
    return object.value;
  }
}

class GroupchatDetailsConverter
    extends JsonConverter<GroupchatDetails, Map<String, dynamic>> {
  const GroupchatDetailsConverter();

  @override
  GroupchatDetails fromJson(Map<String, dynamic> json) {
    return GroupchatDetails(
      json['jid']! as String,
      json['accountJid']! as String,
      json['nick']! as String,
    );
  }

  @override
  Map<String, dynamic> toJson(GroupchatDetails object) {
    return {
      'jid': object.jid,
      'accountJid': object.accountJid,
      'nick': object.nick,
    };
  }
}

@freezed
class Conversation with _$Conversation {
  factory Conversation(
    /// The account that has the conversation.
    String accountJid,

    /// The title of the chat.
    String title,

    // The newest message in the chat.
    @ConversationMessageConverter() Message? lastMessage,

    // The path to the avatar.
    String? avatarPath,

    // The hash of the avatar.
    String? avatarHash,

    // The JID of the entity we're having a chat with...
    String jid,

    // The nick with which the MUC is joined...
    @GroupchatDetailsConverter() GroupchatDetails? groupchatDetails,

    // The number of unread messages.
    int unreadCounter,

    // The kind of chat this conversation is representing.
    @ConversationTypeConverter() ConversationType type,

    // The timestamp the conversation was last changed.
    // NOTE: In milliseconds since Epoch or -1 if none has ever happened
    int lastChangeTimestamp,

    // Indicates if the conversation should be shown on the homescreen.
    bool open,

    /// Flag indicating whether the "add to roster" button should be shown.
    bool showAddToRoster,

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
    bool showAddToRoster,
    Message? lastMessage,
    GroupchatDetails? groupchatDetails,
  ) {
    return Conversation.fromJson({
      ...json,
      'muted': intToBool(json['muted']! as int),
      'open': intToBool(json['open']! as int),
      'showAddToRoster': showAddToRoster,
      'encrypted': intToBool(json['encrypted']! as int),
      'chatState':
          const ConversationChatStateConverter().toJson(ChatState.gone),
    }).copyWith(
      lastMessage: lastMessage,
      groupchatDetails: groupchatDetails,
    );
  }

  Map<String, dynamic> toDatabaseJson() {
    final map = toJson()
      ..remove('id')
      ..remove('chatState')
      ..remove('showAddToRoster')
      ..remove('lastMessage')
      ..remove('groupchatDetails');

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

  /// The path to the avatar. This returns, if [contactIntegration] is true, first the contact's avatar
  /// path, then the XMPP avatar's path. If [contactIntegration] is false, just returns the regular
  /// XMPP avatar's path.
  String? getAvatarPathWithOptionalContact(bool contactIntegration) {
    if (contactIntegration) {
      return contactAvatarPath ?? avatarPath;
    }

    return avatarPath;
  }

  /// This getter is a short-hand for [getAvatarPathWithOptionalContact] with the
  /// contact integration enablement status extracted from the [PreferencesBloc].
  /// NOTE: This method only works in the UI.
  String? get avatarPathWithOptionalContact => getAvatarPathWithOptionalContact(
        GetIt.I.get<PreferencesBloc>().state.enableContactIntegration,
      );

  /// This getter is a short-hand for [getAvatarPathWithOptionalContact] with the
  /// contact integration enablement status extracted from the [PreferencesService].
  /// NOTE: This method only works in the background isolate.
  Future<String?> get avatarPathWithOptionalContactService async =>
      getAvatarPathWithOptionalContact(
        (await GetIt.I.get<PreferencesService>().getPreferences())
            .enableContactIntegration,
      );

  /// The title of the chat. This returns, if [contactIntegration] is true, first the contact's display
  /// name, then the XMPP chat title. If [contactIntegration] is false, just returns the XMPP chat
  /// title.
  String getTitleWithOptionalContact(bool contactIntegration) {
    if (contactIntegration) {
      return contactDisplayName ?? title;
    }

    return title;
  }

  /// This getter is a short-hand for [getTitleWithOptionalContact] with the
  /// contact integration enablement status extracted from the [PreferencesBloc].
  /// NOTE: This method only works in the UI.
  String get titleWithOptionalContact => getTitleWithOptionalContact(
        GetIt.I.get<PreferencesBloc>().state.enableContactIntegration,
      );

  /// This getter is a short-hand for [getTitleWithOptionalContact] with the
  /// contact integration enablement status extracted from the [PreferencesService].
  /// NOTE: This method only works in the background isolate.
  Future<String> get titleWithOptionalContactService async =>
      getTitleWithOptionalContact(
        (await GetIt.I.get<PreferencesService>().getPreferences())
            .enableContactIntegration,
      );

  /// The amount of items that are shown in the context menu.
  int get numberContextMenuOptions => 1 + (unreadCounter != 0 ? 1 : 0);

  /// True, if the conversation is a self-chat. False, if not.
  bool get isSelfChat => type == ConversationType.note;

  /// True, if the conversation is a groupchat. False, if not.
  bool get isGroupchat => type == ConversationType.groupchat;

  /// True, if we have unread messages. False, if not.
  bool get hasUnreads => unreadCounter > 0;

  /// A string that is either "99+" if unreadsCounter > 99 or unreadsCounter.
  String get unreadsString {
    if (unreadCounter > 99) {
      return '99+';
    } else {
      return unreadCounter.toString();
    }
  }

  /// Flag indicating whether the conversation is "favourited".
  // TODO: Replace with an actual database attribute.
  bool get favourite => false;
}

/// Sorts conversations in descending order by their last change timestamp.
int compareConversation(Conversation a, Conversation b) {
  return -1 * Comparable.compare(a.lastChangeTimestamp, b.lastChangeTimestamp);
}
