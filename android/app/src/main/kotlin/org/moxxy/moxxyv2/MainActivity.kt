package org.moxxy.moxxyv2

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import org.moxxy.moxxyv2.quirks.MoxxyQuirkApi
import org.moxxy.moxxyv2.quirks.QuirkNotificationEvent
import org.moxxy.moxxyv2.quirks.QuirkNotificationEventType

class MainActivity : FlutterActivity(), MoxxyQuirkApi {
    private var lastEvent: QuirkNotificationEvent? = null

    private fun handleIntent(intent: Intent?): Boolean {
        if (intent == null) return false

        when (intent.action) {
            org.moxxy.moxxy_native.TAP_ACTION -> {
                Log.d("Moxxy", "Handling tap data")
                lastEvent = QuirkNotificationEvent(
                    intent.getLongExtra(org.moxxy.moxxy_native.NOTIFICATION_EXTRA_ID_KEY, -1),
                    intent.getStringExtra(org.moxxy.moxxy_native.NOTIFICATION_EXTRA_JID_KEY)!!,
                    QuirkNotificationEventType.OPEN,
                    null,
                    org.moxxy.moxxy_native.notifications.extractPayloadMapFromIntent(intent),
                )
                return true
            }
            else -> {
                Log.d("Moxxy", "Unknown intent action: ${intent.action}")
                return false
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        MoxxyQuirkApi.setUp(flutterEngine.dartExecutor.binaryMessenger, this)
        super.configureFlutterEngine(flutterEngine)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun earlyNotificationEventQuirk(): QuirkNotificationEvent? {
        val event = lastEvent
        lastEvent = null
        return event
    }
}
