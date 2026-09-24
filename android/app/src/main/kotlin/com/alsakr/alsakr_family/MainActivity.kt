package com.alsakr.alsakr_family

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ensureLockScreenChannel()
    }

    private fun ensureLockScreenChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            "school_lock_alerts",
            "تنبيهات المدرسة",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "إشعارات المدرسة على شاشة القفل"
            enableVibration(true)
            enableLights(true)
            setShowBadge(true)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            setSound(
                android.provider.Settings.System.DEFAULT_NOTIFICATION_URI,
                android.media.AudioAttributes.Builder()
                    .setUsage(android.media.AudioAttributes.USAGE_NOTIFICATION)
                    .build()
            )
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }
}
