package com.example.vajra_mobile

import android.app.Activity
import android.app.Notification
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import androidx.core.app.NotificationManagerCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ConcurrentLinkedQueue

class VajraNotificationListener : NotificationListenerService() {

    companion object {
        private const val MAX_HISTORY = 50
        private val notificationHistory = ConcurrentLinkedQueue<Map<String, Any?>>()

        fun getRecentNotifications(): List<Map<String, Any?>> {
            return notificationHistory.toList()
        }

        fun isAccessGranted(context: Context): Boolean {
            val enabledPackages = NotificationManagerCompat.getEnabledListenerPackages(context)
            return enabledPackages.contains(context.packageName)
        }

        fun registerChannel(messenger: BinaryMessenger, context: Activity) {
            MethodChannel(messenger, "com.vajra.app/notification_assistant").setMethodCallHandler { call, result ->
                when (call.method) {
                    "isPermissionGranted" -> {
                        result.success(isAccessGranted(context))
                    }
                    "openPermissionSettings" -> {
                        try {
                            val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            context.startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SETTINGS_ERROR", e.message, null)
                        }
                    }
                    "getActiveNotifications" -> {
                        val items = getRecentNotifications()
                        result.success(items)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        val pkg = sbn.packageName ?: return
        // Ignore self notifications
        if (pkg == packageName) return

        val extras = sbn.notification?.extras ?: return
        val title = extras.getString(Notification.EXTRA_TITLE) ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""

        if (title.isEmpty() && text.isEmpty()) return

        val pm = applicationContext.packageManager
        val appName = try {
            val appInfo = pm.getApplicationInfo(pkg, 0)
            pm.getApplicationLabel(appInfo).toString()
        } catch (e: Exception) {
            pkg
        }

        val item = mapOf(
            "id" to "${sbn.id}_${sbn.postTime}",
            "packageName" to pkg,
            "appName" to appName,
            "title" to title,
            "text" to text,
            "timestamp" to sbn.postTime
        )

        notificationHistory.add(item)
        while (notificationHistory.size > MAX_HISTORY) {
            notificationHistory.poll()
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
    }
}
