package com.example.vajra_mobile

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.provider.CalendarContract
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

class MainActivity : FlutterActivity() {
    private val CALENDAR_CHANNEL = "com.vajra.app/device_calendar"
    private val NOTIFICATION_CHANNEL = "com.vajra.app/device_notifications"
    private val BRIDGE_CHANNEL = "com.vajra.app/device_bridge"
    private val NOTIF_CHANNEL_ID = "vajra_reminders"
    private var voiceRecognizer: VajraVoiceRecognizer? = null
    private var vajraTts: VajraTextToSpeech? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register Voice Recognizer channel & stream
        voiceRecognizer = VajraVoiceRecognizer(this).apply {
            register(flutterEngine.dartExecutor.binaryMessenger)
        }

        // Register Text-to-Speech channel & stream
        vajraTts = VajraTextToSpeech(this).apply {
            register(flutterEngine.dartExecutor.binaryMessenger)
            initializeImmediately()
        }

        // Register Siri-like Assistant Platform Services
        VajraCallService(this).register(flutterEngine.dartExecutor.binaryMessenger)
        VajraNotificationListener.registerChannel(flutterEngine.dartExecutor.binaryMessenger, this)
        VajraDeviceControlService(this).register(flutterEngine.dartExecutor.binaryMessenger)

        createNotificationChannel()

        // 1. Calendar Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CALENDAR_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "createEvent" -> {
                    val title = call.argument<String>("title") ?: "Event"
                    val description = call.argument<String>("description")
                    val startTime = (call.argument<Number>("startTime"))?.toLong() ?: System.currentTimeMillis()
                    val endTime = (call.argument<Number>("endTime"))?.toLong() ?: (startTime + 3600000)
                    val isAllDay = call.argument<Boolean>("isAllDay") ?: false
                    val location = call.argument<String>("location")
                    val userEmail = call.argument<String>("userEmail")

                    // Check runtime permissions on Android
                    val readPerm = checkSelfPermission(android.Manifest.permission.READ_CALENDAR)
                    val writePerm = checkSelfPermission(android.Manifest.permission.WRITE_CALENDAR)
                    if (readPerm != PackageManager.PERMISSION_GRANTED || writePerm != PackageManager.PERMISSION_GRANTED) {
                        result.success(
                            mapOf(
                                "success" to false,
                                "eventId" to null,
                                "calendarId" to null,
                                "error" to "PERMISSION_DENIED",
                                "message" to "Calendar access is not enabled."
                            )
                        )
                        return@setMethodCallHandler
                    }

                    try {
                        val res = createCalendarEvent(title, description, startTime, endTime, isAllDay, location, userEmail)
                        result.success(res)
                    } catch (e: Exception) {
                        result.success(
                            mapOf(
                                "success" to false,
                                "eventId" to null,
                                "calendarId" to null,
                                "error" to "CALENDAR_ERROR",
                                "message" to (e.message ?: "Unknown calendar error")
                            )
                        )
                    }
                }
                "getEvents" -> {
                    val startDate = (call.argument<Number>("startDate"))?.toLong() ?: System.currentTimeMillis()
                    val endDate = (call.argument<Number>("endDate"))?.toLong() ?: (startDate + 7 * 86400000)

                    try {
                        val events = getCalendarEvents(startDate, endDate)
                        result.success(events)
                    } catch (e: SecurityException) {
                        result.error("PERMISSION_DENIED", "Calendar permission denied: ${e.message}", null)
                    } catch (e: Exception) {
                        result.error("CALENDAR_ERROR", e.message ?: "Unknown calendar error", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // 2. Notifications Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "showNotification" -> {
                    val id = (call.argument<Number>("id"))?.toInt() ?: (System.currentTimeMillis() % 100000).toInt()
                    val title = call.argument<String>("title") ?: "VAJRA Reminder"
                    val body = call.argument<String>("body") ?: ""
                    try {
                        showLocalNotification(id, title, body)
                        result.success(id)
                    } catch (e: Exception) {
                        result.error("NOTIFICATION_ERROR", e.message, null)
                    }
                }
                "scheduleNotification" -> {
                    val id = (call.argument<Number>("id"))?.toInt() ?: (System.currentTimeMillis() % 100000).toInt()
                    val title = call.argument<String>("title") ?: "VAJRA Reminder"
                    val body = call.argument<String>("body") ?: ""
                    val scheduledEpoch = (call.argument<Number>("scheduledEpoch"))?.toLong() ?: System.currentTimeMillis()
                    try {
                        val scheduledId = scheduleLocalNotification(id, title, body, scheduledEpoch)
                        result.success(scheduledId)
                    } catch (e: SecurityException) {
                        result.error("PERMISSION_DENIED", "Exact alarm or notification permission denied: ${e.message}", null)
                    } catch (e: Exception) {
                        result.error("SCHEDULE_ERROR", e.message, null)
                    }
                }
                "cancelNotification" -> {
                    val id = (call.argument<Number>("id"))?.toInt() ?: 0
                    cancelScheduledNotification(id)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // 3. Device Bridge Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BRIDGE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openUrl" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "URL cannot be null", null)
                    }
                }
                "openSettings" -> {
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.fromParts("package", packageName, null)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "VAJRA Reminders"
            val descriptionText = "Notifications for tasks, study sessions and reminders"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(NOTIF_CHANNEL_ID, name, importance).apply {
                description = descriptionText
                enableVibration(true)
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            notificationManager?.createNotificationChannel(channel)
        }
    }

    private fun showLocalNotification(id: Int, title: String, body: String) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            id,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, NOTIF_CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        val notification = builder
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()

        notificationManager.notify(id, notification)
    }

    private fun scheduleLocalNotification(id: Int, title: String, body: String, scheduledEpoch: Long): Int {
        // If scheduled within the next 5 seconds, fire immediately
        if (scheduledEpoch <= System.currentTimeMillis() + 5000) {
            showLocalNotification(id, title, body)
            return id
        }

        val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager
            ?: throw IllegalStateException("AlarmManager not available")

        val intent = Intent(this, VajraAlarmReceiver::class.java).apply {
            putExtra(VajraAlarmReceiver.EXTRA_ID, id)
            putExtra(VajraAlarmReceiver.EXTRA_TITLE, title)
            putExtra(VajraAlarmReceiver.EXTRA_BODY, body)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (alarmManager.canScheduleExactAlarms()) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, scheduledEpoch, pendingIntent)
            } else {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, scheduledEpoch, pendingIntent)
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, scheduledEpoch, pendingIntent)
        } else {
            alarmManager.set(AlarmManager.RTC_WAKEUP, scheduledEpoch, pendingIntent)
        }

        return id
    }

    private fun cancelScheduledNotification(id: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager
        val intent = Intent(this, VajraAlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_NO_CREATE or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )
        if (pendingIntent != null && alarmManager != null) {
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
        }

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        notificationManager?.cancel(id)
    }

    private fun getWritableCalendarId(preferredAccount: String? = null): Long? {
        val projection = arrayOf(
            CalendarContract.Calendars._ID,
            CalendarContract.Calendars.ACCOUNT_NAME,
            CalendarContract.Calendars.ACCOUNT_TYPE,
            CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
            CalendarContract.Calendars.VISIBLE,
            CalendarContract.Calendars.SYNC_EVENTS,
            CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL,
            CalendarContract.Calendars.IS_PRIMARY
        )

        var preferredId: Long? = null
        var primaryGoogleId: Long? = null
        var visibleGoogleId: Long? = null
        var anyVisibleWritableId: Long? = null
        var fallbackWritableId: Long? = null

        val cursor: Cursor? = contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            null,
            null,
            null
        )

        cursor?.use { c ->
            val idCol = c.getColumnIndex(CalendarContract.Calendars._ID)
            val accNameCol = c.getColumnIndex(CalendarContract.Calendars.ACCOUNT_NAME)
            val accTypeCol = c.getColumnIndex(CalendarContract.Calendars.ACCOUNT_TYPE)
            val nameCol = c.getColumnIndex(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME)
            val visCol = c.getColumnIndex(CalendarContract.Calendars.VISIBLE)
            val syncCol = c.getColumnIndex(CalendarContract.Calendars.SYNC_EVENTS)
            val accessCol = c.getColumnIndex(CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL)
            val primCol = c.getColumnIndex(CalendarContract.Calendars.IS_PRIMARY)

            while (c.moveToNext()) {
                val id = if (idCol != -1) c.getLong(idCol) else continue
                val accName = if (accNameCol != -1) c.getString(accNameCol) ?: "" else ""
                val accType = if (accTypeCol != -1) c.getString(accTypeCol) ?: "" else ""
                val displayName = if (nameCol != -1) c.getString(nameCol) ?: "" else ""
                val visible = if (visCol != -1) c.getInt(visCol) else 0
                val syncEvents = if (syncCol != -1) c.getInt(syncCol) else 0
                val access = if (accessCol != -1) c.getInt(accessCol) else 0
                val isPrimary = if (primCol != -1) c.getInt(primCol) == 1 else false

                // Safe diagnostic logging (NO email addresses logged!)
                android.util.Log.d("VajraCalendar", "Calendar candidate: id=$id, displayName=$displayName, accountType=$accType, accessLevel=$access, visible=$visible, syncEvents=$syncEvents, isPrimary=$isPrimary")

                // Only consider writable calendars (contributor, editor, or owner: >= 500)
                if (access < CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR) {
                    continue
                }

                if (fallbackWritableId == null) {
                    fallbackWritableId = id
                }

                // Section 4 requirement: Only use calendars where VISIBLE != 0
                if (visible == 0) {
                    continue
                }

                if (anyVisibleWritableId == null) {
                    anyVisibleWritableId = id
                }

                // Priority 1: Matches preferred account (e.g. logged-in VAJRA email)
                if (!preferredAccount.isNullOrBlank() && accName.equals(preferredAccount.trim(), ignoreCase = true)) {
                    if (isPrimary || preferredId == null) {
                        preferredId = id
                    }
                }

                // Priority 2: Primary Google calendar that is visible and syncs
                if (accType == "com.google" && syncEvents != 0) {
                    if (isPrimary && primaryGoogleId == null) {
                        primaryGoogleId = id
                    }
                    if (visibleGoogleId == null) {
                        visibleGoogleId = id
                    }
                }
            }
        }

        val chosenId = preferredId ?: primaryGoogleId ?: visibleGoogleId ?: anyVisibleWritableId ?: fallbackWritableId
        android.util.Log.d("VajraCalendar", "Selected writable calendarId: $chosenId (preferredMatch=${preferredId != null})")
        return chosenId
    }

    private fun createCalendarEvent(
        title: String,
        description: String?,
        startTime: Long,
        endTime: Long,
        isAllDay: Boolean,
        location: String?,
        preferredAccount: String?
    ): Map<String, Any?> {
        val calId = getWritableCalendarId(preferredAccount)
            ?: return mapOf(
                "success" to false,
                "eventId" to null,
                "calendarId" to null,
                "error" to "CALENDAR_UNAVAILABLE",
                "message" to "No writable calendar account found on this device."
            )

        val defaultTz = TimeZone.getDefault().id
        val values = ContentValues().apply {
            put(CalendarContract.Events.CALENDAR_ID, calId)
            put(CalendarContract.Events.TITLE, title)
            put(CalendarContract.Events.DESCRIPTION, description ?: "")
            put(CalendarContract.Events.DTSTART, startTime)
            put(CalendarContract.Events.DTEND, endTime)
            put(CalendarContract.Events.EVENT_TIMEZONE, defaultTz)
            put(CalendarContract.Events.ALL_DAY, if (isAllDay) 1 else 0)
            put(CalendarContract.Events.STATUS, CalendarContract.Events.STATUS_CONFIRMED)
            put(CalendarContract.Events.AVAILABILITY, CalendarContract.Events.AVAILABILITY_BUSY)
            put(CalendarContract.Events.HAS_ALARM, 1)
            if (location != null) put(CalendarContract.Events.EVENT_LOCATION, location)
        }

        val uri = contentResolver.insert(CalendarContract.Events.CONTENT_URI, values)
            ?: return mapOf(
                "success" to false,
                "eventId" to null,
                "calendarId" to calId.toString(),
                "error" to "INSERT_FAILED",
                "message" to "ContentResolver returned null URI during insertion."
            )

        val eventId = try {
            ContentUris.parseId(uri)
        } catch (e: Exception) {
            -1L
        }

        if (eventId <= 0) {
            return mapOf(
                "success" to false,
                "eventId" to null,
                "calendarId" to calId.toString(),
                "error" to "INSERT_FAILED",
                "message" to "Invalid event ID returned from insert: $eventId"
            )
        }

        // Section 7: Verify the event after insertion (INSERT -> VERIFY -> SUCCESS)
        val verifyProjection = arrayOf(
            CalendarContract.Events._ID,
            CalendarContract.Events.TITLE,
            CalendarContract.Events.DTSTART,
            CalendarContract.Events.DTEND,
            CalendarContract.Events.CALENDAR_ID
        )
        val verifyUri = ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, eventId)
        val verifyCursor = contentResolver.query(verifyUri, verifyProjection, null, null, null)
        var verified = false
        verifyCursor?.use { c ->
            if (c.moveToFirst()) {
                val vId = c.getLong(c.getColumnIndexOrThrow(CalendarContract.Events._ID))
                val vCalId = c.getLong(c.getColumnIndexOrThrow(CalendarContract.Events.CALENDAR_ID))
                if (vId == eventId && vCalId == calId) {
                    verified = true
                }
            }
        }

        if (!verified) {
            return mapOf(
                "success" to false,
                "eventId" to null,
                "calendarId" to calId.toString(),
                "error" to "VERIFICATION_FAILED",
                "message" to "Event could not be verified in CalendarProvider after insertion."
            )
        }

        // Add default reminder
        try {
            val reminderValues = ContentValues().apply {
                put(CalendarContract.Reminders.EVENT_ID, eventId)
                put(CalendarContract.Reminders.MINUTES, 15)
                put(CalendarContract.Reminders.METHOD, CalendarContract.Reminders.METHOD_ALERT)
            }
            contentResolver.insert(CalendarContract.Reminders.CONTENT_URI, reminderValues)
        } catch (e: Exception) {
            android.util.Log.w("VajraCalendar", "Failed to add reminder: ${e.message}")
        }

        return mapOf(
            "success" to true,
            "eventId" to eventId.toString(),
            "calendarId" to calId.toString(),
            "error" to null
        )
    }

    private fun getCalendarEvents(startDate: Long, endDate: Long): List<Map<String, Any>> {
        val events = mutableListOf<Map<String, Any>>()
        val projection = arrayOf(
            CalendarContract.Events._ID,
            CalendarContract.Events.TITLE,
            CalendarContract.Events.DESCRIPTION,
            CalendarContract.Events.DTSTART,
            CalendarContract.Events.DTEND,
            CalendarContract.Events.ALL_DAY,
            CalendarContract.Events.EVENT_LOCATION
        )

        val selection = CalendarContract.Events.DTSTART + " >= ? AND " + CalendarContract.Events.DTEND + " <= ? AND " + CalendarContract.Events.DELETED + " = 0"
        val selectionArgs = arrayOf(startDate.toString(), endDate.toString())
        val isoFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
            timeZone = TimeZone.getTimeZone("UTC")
        }

        val cursor: Cursor? = contentResolver.query(
            CalendarContract.Events.CONTENT_URI,
            projection,
            selection,
            selectionArgs,
            CalendarContract.Events.DTSTART + " ASC"
        )

        cursor?.use {
            val idCol = it.getColumnIndex(CalendarContract.Events._ID)
            val titleCol = it.getColumnIndex(CalendarContract.Events.TITLE)
            val descCol = it.getColumnIndex(CalendarContract.Events.DESCRIPTION)
            val startCol = it.getColumnIndex(CalendarContract.Events.DTSTART)
            val endCol = it.getColumnIndex(CalendarContract.Events.DTEND)
            val allDayCol = it.getColumnIndex(CalendarContract.Events.ALL_DAY)
            val locCol = it.getColumnIndex(CalendarContract.Events.EVENT_LOCATION)

            while (it.moveToNext()) {
                val id = if (idCol != -1) it.getString(idCol) ?: "" else ""
                val title = if (titleCol != -1) it.getString(titleCol) ?: "Event" else "Event"
                val desc = if (descCol != -1) it.getString(descCol) else null
                val startMs = if (startCol != -1) it.getLong(startCol) else startDate
                val endMs = if (endCol != -1) it.getLong(endCol) else (startMs + 3600000)
                val allDay = if (allDayCol != -1) it.getInt(allDayCol) == 1 else false
                val loc = if (locCol != -1) it.getString(locCol) else null

                events.add(
                    mapOf(
                        "id" to id,
                        "title" to title,
                        "description" to (desc ?: ""),
                        "startTime" to isoFormat.format(Date(startMs)),
                        "endTime" to isoFormat.format(Date(endMs)),
                        "isAllDay" to allDay,
                        "location" to (loc ?: "")
                    )
                )
            }
        }

        return events
    }

    override fun onDestroy() {
        voiceRecognizer?.cleanup()
        voiceRecognizer = null
        vajraTts?.cleanup()
        vajraTts = null
        super.onDestroy()
    }
}
