package org.moxxy.moxxyv2.plugin

import android.app.Activity
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.PluginRegistry.NewIntentListener
import org.moxxy.moxxyv2.notifications.NotificationDataManager
import org.moxxy.moxxyv2.notifications.createNotificationChannelsImpl
import org.moxxy.moxxyv2.notifications.createNotificationGroupsImpl
import org.moxxy.moxxyv2.notifications.extractPayloadMapFromIntent
import org.moxxy.moxxyv2.notifications.showNotificationImpl
import org.moxxy.moxxyv2.picker.PickerResultListener

object MoxxyEventChannels {
    var notificationChannel: EventChannel? = null
    var notificationEventSink: EventChannel.EventSink? = null
}

object NotificationStreamHandler : EventChannel.StreamHandler {
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
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

class MoxxyPlugin : FlutterPlugin, ActivityAware, NewIntentListener, MoxxyApi {
    private var context: Context? = null
    private var activity: Activity? = null
    private lateinit var pickerListener: PickerResultListener

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        MoxxyEventChannels.notificationChannel = EventChannel(binding.binaryMessenger, "org.moxxy.moxxyv2/notification_stream")
        MoxxyEventChannels.notificationChannel!!.setStreamHandler(NotificationStreamHandler)
        MoxxyApi.setUp(binding.binaryMessenger, this)
        pickerListener = PickerResultListener(context!!)
        Log.d(TAG, "Attached to engine")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "Detached from engine")
    }
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(pickerListener)
        Log.d(TAG, "Attached to activity")
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
        Log.d(TAG, "Detached from activity")
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
        Log.d(TAG, "Detached from activity")
    }

    private fun handleIntent(intent: Intent?): Boolean {
        if (intent == null) return false

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
                return true
            }
            else -> {
                Log.d(TAG, "Unknown intent action: ${intent.action}")
                return false
            }
        }
    }

    override fun onNewIntent(intent: Intent): Boolean {
        return handleIntent(intent)
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
        NotificationDataManager.setAvatarPath(context!!, path)
    }

    override fun setNotificationI18n(data: NotificationI18nData) {
        NotificationDataManager.apply {
            setYou(context!!, data.you)
            setReply(context!!, data.reply)
            setMarkAsRead(context!!, data.markAsRead)
        }
    }

    override fun pickFiles(
        type: FilePickerType,
        multiple: Boolean,
        callback: (Result<List<String>>) -> Unit,
    ) {
        val requestCode = if (multiple) PICK_FILES_REQUEST else PICK_FILE_REQUEST
        AsyncRequestTracker.requestTracker[requestCode] = callback as (Result<Any>) -> Unit
        Log.d(TAG, "Tracker size ${AsyncRequestTracker.requestTracker.size}")
        if (type == FilePickerType.GENERIC) {
            val pickIntent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                this.type = "*/*"

                // Allow/disallow picking multiple files
                putExtra(Intent.EXTRA_ALLOW_MULTIPLE, multiple)
            }
            activity?.startActivityForResult(pickIntent, requestCode)
            return
        }

        val contract = when (multiple) {
            false -> ActivityResultContracts.PickVisualMedia()
            true -> ActivityResultContracts.PickMultipleVisualMedia()
        }
        val pickType = when (type) {
            // We keep FilePickerType.GENERIC here, even though we know that @type will never be
            // GENERIC to make Kotlin happy.
            FilePickerType.GENERIC, FilePickerType.IMAGE -> ActivityResultContracts.PickVisualMedia.ImageOnly
            FilePickerType.VIDEO -> ActivityResultContracts.PickVisualMedia.VideoOnly
            FilePickerType.IMAGEANDVIDEO -> ActivityResultContracts.PickVisualMedia.ImageAndVideo
        }
        val pickIntent = contract.createIntent(context!!, PickVisualMediaRequest(pickType))
        activity?.startActivityForResult(pickIntent, requestCode)
    }

    override fun pickFileWithData(type: FilePickerType, callback: (Result<ByteArray?>) -> Unit) {
        AsyncRequestTracker.requestTracker[PICK_FILE_WITH_DATA_REQUEST] = callback as (Result<Any>) -> Unit
        if (type == FilePickerType.GENERIC) {
            val pickIntent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                this.type = "*/*"
            }
            activity?.startActivityForResult(pickIntent, PICK_FILE_WITH_DATA_REQUEST)
            return
        }

        val pickType = when (type) {
            // We keep FilePickerType.GENERIC here, even though we know that @type will never be
            // GENERIC to make Kotlin happy.
            FilePickerType.GENERIC, FilePickerType.IMAGE -> ActivityResultContracts.PickVisualMedia.ImageOnly
            FilePickerType.VIDEO -> ActivityResultContracts.PickVisualMedia.VideoOnly
            FilePickerType.IMAGEANDVIDEO -> ActivityResultContracts.PickVisualMedia.ImageAndVideo
        }
        val contract = ActivityResultContracts.PickVisualMedia()
        val pickIntent = contract.createIntent(context!!, PickVisualMediaRequest(pickType))
        activity?.startActivityForResult(pickIntent, PICK_FILE_WITH_DATA_REQUEST)
    }

    override fun notificationStub(event: NotificationEvent) {
        TODO("Not yet implemented")
    }
}
