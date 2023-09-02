package org.moxxy.moxxyv2

// The tag we use for logging.
const val TAG = "Moxxy"

// The data key for text entered in the notification's reply field
const val REPLY_TEXT_KEY = "key_reply_text"

// The key for the notification id to mark as read
const val MARK_AS_READ_ID_KEY = "notification_id"

// Values for actions performed through the notification
const val REPLY_ACTION = "reply"
const val MARK_AS_READ_ACTION = "mark_as_read"
const val TAP_ACTION = "tap"

// Extra data keys for the intents that reach the NotificationReceiver
const val NOTIFICATION_EXTRA_JID_KEY = "jid"
const val NOTIFICATION_EXTRA_ID_KEY = "notification_id"

// Extra data keys for messages embedded inside the notification style
const val NOTIFICATION_MESSAGE_EXTRA_MIME = "mime"
const val NOTIFICATION_MESSAGE_EXTRA_PATH = "path"

const val MOXXY_FILEPROVIDER_ID = "org.moxxy.moxxyv2.fileprovider"

// Shared preferences keys
const val SHARED_PREFERENCES_KEY = "org.moxxy.moxxyv2"
const val SHARED_PREFERENCES_YOU_KEY = "you"
const val SHARED_PREFERENCES_MARK_AS_READ_KEY = "mark_as_read"
const val SHARED_PREFERENCES_REPLY_KEY = "reply"
const val SHARED_PREFERENCES_AVATAR_KEY = "avatar_path"