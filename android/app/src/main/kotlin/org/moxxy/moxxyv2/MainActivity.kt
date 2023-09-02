package org.moxxy.moxxyv2

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import org.moxxy.moxxyv2.notifications.NotificationDataManager
import org.moxxy.moxxyv2.notifications.createNotificationChannelsImpl
import org.moxxy.moxxyv2.notifications.createNotificationGroupsImpl
import org.moxxy.moxxyv2.notifications.extractPayloadMapFromIntent
import org.moxxy.moxxyv2.notifications.showNotificationImpl

object MoxxyEventChannels {
    var notificationChannel: EventChannel? = null
    var notificationEventSink: EventSink? = null
}

object NotificationStreamHandler : EventChannel.StreamHandler {
    override fun onListen(arguments: Any?, events: EventSink?) {
        Log.d(TAG, "NotificationStreamHandler: Attached stream")
        MoxxyEventChannels.notificationEventSink = events
    }

    override fun onCancel(arguments: Any?) {
        Log.d(TAG, "NotificationStreamHandler: Detached stream")
        MoxxyEventChannels.notificationEventSink = null
    }
}

/*
 * Hold the last notification event in case we did a cold start.
 * TODO: Currently unused, but useful in the future.
 * */
object NotificationCache {
    var lastEvent: NotificationEvent? = null
}

class MainActivity: FlutterActivity(), FlutterPlugin, MoxxyApi {
    private var context: Context? = null

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return

        when (intent.action) {
            TAP_ACTION -> {
                Log.d(TAG, "Handling tap data")
                val event = NotificationEvent(
                    intent.getLongExtra(NOTIFICATION_EXTRA_ID_KEY, -1),
                    intent.getStringExtra(NOTIFICATION_EXTRA_JID_KEY)!!,
                    NotificationEventType.OPEN,
                    null,
                    extractPayloadMapFromIntent(intent),
                )
                NotificationCache.lastEvent = event
                MoxxyEventChannels.notificationEventSink?.success(
                    event.toList(),
                )
            }
            else -> Log.d(TAG, "Unknown intent action: ${intent.action}")
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    override fun createNotificationGroups(groups: List<NotificationGroup>) {
        createNotificationGroupsImpl(context!!, groups)
    }

    override fun deleteNotificationGroups(ids: List<String>) {
        val notificationManager = context!!.getSystemService(NotificationManager::class.java)
        for (id in ids) {
            notificationManager.deleteNotificationChannelGroup(id)
        }
    }

    override fun createNotificationChannels(channels: List<NotificationChannel>) {
        createNotificationChannelsImpl(context!!, channels)
    }

    override fun deleteNotificationChannels(ids: List<String>) {
        val notificationManager = context!!.getSystemService(NotificationManager::class.java)
        for (id in ids) {
            notificationManager.deleteNotificationChannel(id)
        }
    }

    override fun showMessagingNotification(notification: MessagingNotification) {
        org.moxxy.moxxyv2.notifications.showMessagingNotification(context!!, notification)
    }

    override fun showNotification(notification: RegularNotification) {
        showNotificationImpl(context!!, notification)
    }

    override fun dismissNotification(id: Long) {
        NotificationManagerCompat.from(context!!).cancel(id.toInt())
    }

    override fun setNotificationSelfAvatar(path: String) {
        NotificationDataManager.setAvatarPath(context!!, path);
    }

    override fun setNotificationI18n(data: NotificationI18nData) {
        NotificationDataManager.apply {
            setYou(context!!, data.you)
            setReply(context!!, data.reply)
            setMarkAsRead(context!!, data.markAsRead)
        }
    }

    override fun notificationStub(event: NotificationEvent) {}

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        MoxxyEventChannels.notificationChannel = EventChannel(binding.binaryMessenger, "org.moxxy.moxxyv2/notification_stream")
        MoxxyEventChannels.notificationChannel!!.setStreamHandler(NotificationStreamHandler)

        MoxxyApi.setUp(binding.binaryMessenger, this)

        Log.d(TAG, "Attached to engine")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "Detached from engine")
    }
}
