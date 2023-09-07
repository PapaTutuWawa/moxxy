package org.moxxy.moxxyv2

import android.content.Intent
import android.os.Bundle
import android.os.PersistableBundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import org.moxxy.moxxyv2.notifications.extractPayloadMapFromIntent
import org.moxxy.moxxyv2.plugin.MoxxyEventChannels
import org.moxxy.moxxyv2.plugin.NOTIFICATION_EXTRA_ID_KEY
import org.moxxy.moxxyv2.plugin.NOTIFICATION_EXTRA_JID_KEY
import org.moxxy.moxxyv2.plugin.NotificationCache
import org.moxxy.moxxyv2.plugin.NotificationEvent
import org.moxxy.moxxyv2.plugin.NotificationEventType
import org.moxxy.moxxyv2.plugin.TAP_ACTION

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent);
    }

    private fun handleIntent(intent: Intent?): Boolean {
        if (intent == null) return false

        when (intent.action) {
            TAP_ACTION -> {
                Log.d(org.moxxy.moxxyv2.plugin.TAG, "Handling tap data")
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
                Log.d(org.moxxy.moxxyv2.plugin.TAG, "Unknown intent action: ${intent.action}")
                return false
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        handleIntent(intent)
    }
}