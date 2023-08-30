const int timestampNever = -1;

/// The amount of messages that are fetched by a paginated message request
const int messagePaginationSize = 30;

/// The aount of pages of messages we can cache in memory
const int maxMessagePages = 5;

/// The amount of shared media that are fetched per paginated request
const int sharedMediaPaginationSize = 60;

/// The amount of pages of shared media we can cache in memory
const int maxSharedMediaPages = 3;

/// The amount of conversations for which we cache the first page.
const int conversationMessagePageCacheSize = 4;

/// The amount of sticker packs we fetch per paginated request
const stickerPackPaginationSize = 10;

/// The amount of sticker packs we can cache in memory.
const maxStickerPackPages = 2;

/// An "invalid" fake JID to make share_handler happy when adding the self-chat
/// to the direct share list.
const selfChatShareFakeJid = '{{ self-chat }}';

/// Keys for grouping notifications
const messageNotificationGroupId = 'message';
const warningNotificationGroupId = 'warning';
const foregroundServiceNotificationGroupId = 'service';

/// Notification channel ids
const foregroundServiceNotificationChannelId = 'FOREGROUND_DEFAULT';
const messageNotificationChannelId = 'message_channel';
const warningNotificationChannelId = 'warning_channel';
