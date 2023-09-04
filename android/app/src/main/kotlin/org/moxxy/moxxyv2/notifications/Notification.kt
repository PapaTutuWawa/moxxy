package org.moxxy.moxxyv2.notifications

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannelGroup
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.graphics.Color
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.Person
import androidx.core.app.RemoteInput
import androidx.core.app.TaskStackBuilder
import androidx.core.content.FileProvider
import androidx.core.graphics.drawable.IconCompat
import org.moxxy.moxxyv2.MARK_AS_READ_ACTION
import org.moxxy.moxxyv2.MOXXY_FILEPROVIDER_ID
import org.moxxy.moxxyv2.MainActivity
import org.moxxy.moxxyv2.MessagingNotification
import org.moxxy.moxxyv2.NOTIFICATION_EXTRA_ID_KEY
import org.moxxy.moxxyv2.NOTIFICATION_EXTRA_JID_KEY
import org.moxxy.moxxyv2.NOTIFICATION_MESSAGE_EXTRA_MIME
import org.moxxy.moxxyv2.NOTIFICATION_MESSAGE_EXTRA_PATH
import org.moxxy.moxxyv2.NotificationChannel
import org.moxxy.moxxyv2.NotificationChannelImportance
import org.moxxy.moxxyv2.NotificationGroup
import org.moxxy.moxxyv2.NotificationIcon
import org.moxxy.moxxyv2.R
import org.moxxy.moxxyv2.REPLY_ACTION
import org.moxxy.moxxyv2.REPLY_TEXT_KEY
import org.moxxy.moxxyv2.RegularNotification
import org.moxxy.moxxyv2.SHARED_PREFERENCES_AVATAR_KEY
import org.moxxy.moxxyv2.SHARED_PREFERENCES_KEY
import org.moxxy.moxxyv2.SHARED_PREFERENCES_MARK_AS_READ_KEY
import org.moxxy.moxxyv2.SHARED_PREFERENCES_REPLY_KEY
import org.moxxy.moxxyv2.SHARED_PREFERENCES_YOU_KEY
import org.moxxy.moxxyv2.TAG
import org.moxxy.moxxyv2.TAP_ACTION
import java.io.File

/*
 * Holds "persistent" data for notifications, like i18n strings. While not useful now, this is
 * useful for when the app is dead and we receive a notification.
 * */
object NotificationDataManager {
    private var you: String? = null
    private var markAsRead: String? = null
    private var reply: String? = null

    private var fetchedAvatarPath = false
    private var avatarPath: String? = null

    private fun getString(context: Context, key: String, fallback: String): String {
        return context.getSharedPreferences(SHARED_PREFERENCES_KEY, Context.MODE_PRIVATE)!!.getString(key, fallback)!!
    }

    private fun setString(context: Context, key: String, value: String) {
        val prefs = context.getSharedPreferences(SHARED_PREFERENCES_KEY, Context.MODE_PRIVATE)
        prefs.edit()
            .putString(key, value)
            .apply()
    }

    fun getYou(context: Context): String {
        if (you == null) you = getString(context, SHARED_PREFERENCES_YOU_KEY, "You")
        return you!!
    }

    fun setYou(context: Context, value: String) {
        setString(context, SHARED_PREFERENCES_YOU_KEY, value)
        you = value
    }

    fun getMarkAsRead(context: Context): String {
        if (markAsRead == null) markAsRead = getString(context, SHARED_PREFERENCES_MARK_AS_READ_KEY, "Mark as read")
        return markAsRead!!
    }

    fun setMarkAsRead(context: Context, value: String) {
        setString(context, SHARED_PREFERENCES_MARK_AS_READ_KEY, value)
        markAsRead = value
    }

    fun getReply(context: Context): String {
        if (reply != null) reply = getString(context, SHARED_PREFERENCES_REPLY_KEY, "Reply")
        return reply!!
    }

    fun setReply(context: Context, value: String) {
        setString(context, SHARED_PREFERENCES_REPLY_KEY, value)
        reply = value
    }

    fun getAvatarPath(context: Context): String? {
        if (avatarPath == null && !fetchedAvatarPath) {
            val path = getString(context, SHARED_PREFERENCES_AVATAR_KEY, "")
            if (path.isNotEmpty()) {
                avatarPath = path
            }
        }

        return avatarPath
    }

    fun setAvatarPath(context: Context, value: String) {
        setString(context, SHARED_PREFERENCES_AVATAR_KEY, value)
        fetchedAvatarPath = true
        avatarPath = value
    }
}

fun createNotificationGroupsImpl(context: Context, groups: List<NotificationGroup>) {
    val notificationManager = context.getSystemService(NotificationManager::class.java)
    for (group in groups) {
        notificationManager.createNotificationChannelGroup(
            NotificationChannelGroup(group.id, group.description),
        )
    }
}

fun createNotificationChannelsImpl(context: Context, channels: List<NotificationChannel>) {
    val notificationManager = context.getSystemService(NotificationManager::class.java)
    for (channel in channels) {
        val importance = when (channel.importance) {
            NotificationChannelImportance.DEFAULT -> NotificationManager.IMPORTANCE_DEFAULT
            NotificationChannelImportance.MIN -> NotificationManager.IMPORTANCE_MIN
            NotificationChannelImportance.HIGH -> NotificationManager.IMPORTANCE_HIGH
        }
        val notificationChannel = android.app.NotificationChannel(channel.id, channel.title, importance).apply {
            description = channel.description

            enableVibration(channel.vibration)
            enableLights(channel.enableLights)
            setShowBadge(channel.showBadge)

            if (channel.groupId != null) {
                group = channel.groupId
            }
        }
        notificationManager.createNotificationChannel(notificationChannel)
    }
}

// / Show a messaging style notification described by @notification.
@SuppressLint("WrongConstant")
fun showMessagingNotification(context: Context, notification: MessagingNotification) {
    // Build the actions
    // -> Reply action
    val remoteInput = RemoteInput.Builder(REPLY_TEXT_KEY).apply {
        setLabel(NotificationDataManager.getReply(context))
    }.build()
    val replyIntent = Intent(context, NotificationReceiver::class.java).apply {
        action = REPLY_ACTION
        putExtra(NOTIFICATION_EXTRA_JID_KEY, notification.jid)
        putExtra(NOTIFICATION_EXTRA_ID_KEY, notification.id)

        notification.extra?.forEach {
            putExtra("payload_${it.key}", it.value)
        }
    }
    val replyPendingIntent = PendingIntent.getBroadcast(
        context.applicationContext,
        0,
        replyIntent,
        PendingIntent.FLAG_MUTABLE,
    )
    val replyAction = NotificationCompat.Action.Builder(
        R.drawable.reply,
        NotificationDataManager.getReply(context),
        replyPendingIntent,
    ).apply {
        addRemoteInput(remoteInput)
        setAllowGeneratedReplies(true)
    }.build()

    // -> Mark as read action
    val markAsReadIntent = Intent(context, NotificationReceiver::class.java).apply {
        action = MARK_AS_READ_ACTION
        putExtra(NOTIFICATION_EXTRA_JID_KEY, notification.jid)
        putExtra(NOTIFICATION_EXTRA_ID_KEY, notification.id)

        notification.extra?.forEach {
            putExtra("payload_${it.key}", it.value)
        }
    }
    val markAsReadPendingIntent = PendingIntent.getBroadcast(
        context.applicationContext,
        0,
        markAsReadIntent,
        PendingIntent.FLAG_IMMUTABLE,
    )
    val markAsReadAction = NotificationCompat.Action.Builder(
        R.drawable.mark_as_read,
        NotificationDataManager.getMarkAsRead(context),
        markAsReadPendingIntent,
    ).build()

    // -> Tap action
    // NOTE: Because Android disallows "notification trampolines" (https://developer.android.com/about/versions/12/behavior-changes-12#notification-trampolines),
    //       we must do it this way instead of just using startActivity
    val tapIntent = Intent(context, MainActivity::class.java).apply {
        action = TAP_ACTION
        putExtra(NOTIFICATION_EXTRA_JID_KEY, notification.jid)
        putExtra(NOTIFICATION_EXTRA_ID_KEY, notification.id)

        notification.extra?.forEach {
            putExtra("payload_${it.key}", it.value)
        }

        // Do not launch a new task
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
    }
    val tapPendingIntent = TaskStackBuilder.create(context).run {
        addNextIntentWithParentStack(tapIntent)
        getPendingIntent(0, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }

    // Build the notification
    val selfPerson = Person.Builder().apply {
        setName(NotificationDataManager.getYou(context))

        // Set an avatar, if we have one
        val avatarPath = NotificationDataManager.getAvatarPath(context)
        if (avatarPath != null) {
            setIcon(
                IconCompat.createWithAdaptiveBitmap(
                    BitmapFactory.decodeFile(avatarPath),
                ),
            )
        }
    }.build()
    val style = NotificationCompat.MessagingStyle(selfPerson)
    style.isGroupConversation = notification.isGroupchat
    if (notification.isGroupchat) {
        style.conversationTitle = notification.title
    }

    for (i in notification.messages.indices) {
        val message = notification.messages[i]!!

        // Build the sender
        // NOTE: Note that we set it to null if message.sender == null because otherwise this results in
        //       a bogus Person object which messes with the "self-message" display as Android expects
        //       null in that case.
        val sender = if (message.sender == null) {
            null
        } else {
            Person.Builder().apply {
                setName(message.sender)
                setKey(message.jid)

                // Set the avatar, if available
                if (message.avatarPath != null) {
                    try {
                        setIcon(
                            IconCompat.createWithAdaptiveBitmap(
                                BitmapFactory.decodeFile(message.avatarPath),
                            ),
                        )
                    } catch (ex: Throwable) {
                        Log.w(TAG, "Failed to open avatar at ${message.avatarPath}")
                    }
                }
            }.build()
        }

        // Build the message
        val body = message.content.body ?: ""
        val msg = NotificationCompat.MessagingStyle.Message(
            body,
            message.timestamp,
            sender,
        )
        // If we got an image, turn it into a content URI and set it
        if (message.content.mime != null && message.content.path != null) {
            val fileUri = FileProvider.getUriForFile(
                context,
                MOXXY_FILEPROVIDER_ID,
                File(message.content.path),
            )
            msg.apply {
                setData(message.content.mime, fileUri)

                extras.apply {
                    putString(NOTIFICATION_MESSAGE_EXTRA_MIME, message.content.mime)
                    putString(NOTIFICATION_MESSAGE_EXTRA_PATH, message.content.path)
                }
            }
        }

        // Append the message
        style.addMessage(msg)
    }

    // Assemble the notification
    val finalNotification = NotificationCompat.Builder(context, notification.channelId).apply {
        setStyle(style)
        // NOTE: It's okay to use the service icon here as I cannot get Android to display the
        //       actual logo. So we'll have to make do with the silhouette and the color purple.
        setSmallIcon(R.drawable.ic_service_icon)
        color = Color.argb(255, 207, 74, 255)
        setColorized(true)

        // Tap action
        setContentIntent(tapPendingIntent)

        // Notification actions
        addAction(replyAction)
        addAction(markAsReadAction)

        // Groupchat title
        if (notification.isGroupchat) {
            setContentTitle(notification.title)
        }

        // Prevent grouping with the foreground service
        if (notification.groupId != null) {
            setGroup(notification.groupId)
        }

        setAllowSystemGeneratedContextualActions(true)
        setCategory(Notification.CATEGORY_MESSAGE)

        // Prevent no notification when we replied before
        setOnlyAlertOnce(false)

        // Automatically dismiss the notification on tap
        setAutoCancel(true)
    }.build()

    // Post the notification
    try {
        NotificationManagerCompat.from(context).notify(
            notification.id.toInt(),
            finalNotification,
        )
    } catch (ex: SecurityException) {
        // Should never happen as Moxxy checks for the permission before posting the notification
        Log.e(TAG, "Failed to post notification: ${ex.message}")
    }
}

fun showNotificationImpl(context: Context, notification: RegularNotification) {
    val builtNotification = NotificationCompat.Builder(context, notification.channelId).apply {
        setContentTitle(notification.title)
        setContentText(notification.body)

        when (notification.icon) {
            NotificationIcon.ERROR -> setSmallIcon(R.drawable.error)
            NotificationIcon.WARNING -> setSmallIcon(R.drawable.warning)
            NotificationIcon.NONE -> {}
        }

        if (notification.groupId != null) {
            setGroup(notification.groupId)
        }
    }.build()

    // Post the notification
    try {
        NotificationManagerCompat.from(context).notify(notification.id.toInt(), builtNotification)
    } catch (ex: SecurityException) {
        // Should never happen as Moxxy checks for the permission before posting the notification
        Log.e(TAG, "Failed to post notification: ${ex.message}")
    }
}
