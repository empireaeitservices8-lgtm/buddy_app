package com.gabby.talk

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.gabby.talk/call_channel"
    private var methodChannel: MethodChannel? = null
    private var pendingCallJson: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Allow app to show on lock screen and wake the device when incoming call arrives
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }

        createNotificationChannels()
        extractCallDataFromIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        extractCallDataFromIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPendingCall" -> {
                        val data = pendingCallJson
                        pendingCallJson = null
                        try {
                            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                            prefs.edit().remove("flutter.pending_incoming_call_data").apply()
                        } catch (_: Exception) {}
                        result.success(data)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        // If a call intent arrived before the engine finished configuring, notify Flutter immediately
        pendingCallJson?.let { json ->
            methodChannel?.invokeMethod("onIncomingCallFromNative", json)
        }
    }

    private fun extractCallDataFromIntent(intent: Intent?) {
        if (intent == null) return
        val extras = intent.extras ?: return
        val map = mutableMapOf<String, Any>()
        for (key in extras.keySet()) {
            extras.get(key)?.let { value ->
                map[key] = value
            }
        }
        val hasChannel = map.containsKey("channel_name") && map["channel_name"]?.toString()?.isNotBlank() == true
        val hasCallId = map.containsKey("call_id")
        val type = map["type"]?.toString()?.lowercase() ?: ""
        if (hasChannel && (type == "incoming_call" || hasCallId)) {
            val jsonStr = JSONObject(map as Map<*, *>).toString()
            pendingCallJson = jsonStr
            methodChannel?.invokeMethod("onIncomingCallFromNative", jsonStr)

            // Clear intent extras so it won't re-trigger on subsequent activity resumes
            try {
                intent.replaceExtras(null as android.os.Bundle?)
            } catch (_: Exception) {}

            // Also write to Flutter SharedPreferences
            try {
                val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                prefs.edit().putString("flutter.pending_incoming_call_data", jsonStr).apply()
            } catch (_: Exception) {}
        }
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "high_importance_channel"
            val channelName = "Incoming Calls & Alerts"
            val channelDescription = "High priority notifications for incoming audio calls and critical alerts"
            val importance = NotificationManager.IMPORTANCE_HIGH

            val ringtoneUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

            val audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                .build()

            val channel = NotificationChannel(channelId, channelName, importance).apply {
                description = channelDescription
                enableLights(true)
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 250, 500, 250, 500)
                setSound(ringtoneUri, audioAttributes)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager?.createNotificationChannel(channel)
        }
    }
}

