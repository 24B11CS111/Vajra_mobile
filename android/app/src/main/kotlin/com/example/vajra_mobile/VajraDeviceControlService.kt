package com.example.vajra_mobile

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.camera2.CameraAccessException
import android.hardware.camera2.CameraManager
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.provider.AlarmClock
import android.provider.Settings
import android.view.KeyEvent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

class VajraDeviceControlService(private val activity: Activity) {
    private val DEVICE_CHANNEL = "com.vajra.app/device_control"
    private val MESSAGE_CHANNEL = "com.vajra.app/message_assistant"

    fun register(messenger: BinaryMessenger) {
        // 1. Device control channel
        MethodChannel(messenger, DEVICE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setFlashlight" -> {
                    val enable = call.argument<Boolean>("enable") ?: false
                    val ok = toggleFlashlight(enable)
                    result.success(ok)
                }
                "setTimer" -> {
                    val seconds = (call.argument<Number>("seconds"))?.toInt() ?: 60
                    val label = call.argument<String>("label") ?: "VAJRA Timer"
                    val ok = setCountdownTimer(seconds, label)
                    result.success(ok)
                }
                "openSetting" -> {
                    val type = call.argument<String>("type") ?: "app"
                    val ok = openSystemSetting(type)
                    result.success(ok)
                }
                "sendMediaControl" -> {
                    val command = call.argument<String>("command") ?: "play"
                    val ok = dispatchMediaControl(command)
                    result.success(ok)
                }
                "adjustVolume" -> {
                    val direction = call.argument<String>("direction") ?: "up"
                    val ok = adjustVolume(direction)
                    result.success(ok)
                }
                "cancelTimer" -> {
                    val ok = cancelTimer()
                    result.success(ok)
                }
                "openApp" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    val ok = openApp(packageName)
                    result.success(ok)
                }
                "isAppInstalled" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    result.success(isAppInstalled(packageName))
                }
                "getInstalledApps" -> {
                    val packageNames = call.argument<List<String>>("packages") ?: emptyList()
                    val resultMap = mutableMapOf<String, Boolean>()
                    for (pkg in packageNames) {
                        resultMap[pkg] = isAppInstalled(pkg)
                    }
                    result.success(resultMap)
                }
                "executeAppAction" -> {
                    val actionType = call.argument<String>("actionType") ?: ""
                    val packageName = call.argument<String>("packageName")
                    val uriString = call.argument<String>("uriString")
                    val extraParams = call.argument<Map<String, Any?>>("extraParams") ?: emptyMap()
                    val res = executeAppAction(actionType, packageName, uriString, extraParams)
                    result.success(res)
                }
                else -> result.notImplemented()
            }
        }

        // 2. Message assistant channel
        MethodChannel(messenger, MESSAGE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openSmsComposer" -> {
                    val recipient = call.argument<String>("recipient") ?: ""
                    val body = call.argument<String>("body") ?: ""
                    try {
                        val uri = if (recipient.isNotEmpty()) {
                            Uri.parse("smsto:${Uri.encode(recipient)}")
                        } else {
                            Uri.parse("smsto:")
                        }
                        val intent = Intent(Intent.ACTION_SENDTO, uri).apply {
                            putExtra("sms_body", body)
                            putExtra(Intent.EXTRA_TEXT, body)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        activity.startActivity(intent)
                        result.success(mapOf("success" to true))
                    } catch (e: Exception) {
                        result.success(
                            mapOf(
                                "success" to false,
                                "message" to "Failed to open SMS composer: ${e.message}",
                                "error" to "INTENT_FAILED"
                            )
                        )
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun toggleFlashlight(enable: Boolean): Boolean {
        return try {
            val cameraManager = activity.getSystemService(Context.CAMERA_SERVICE) as? CameraManager
                ?: return false
            val cameraId = cameraManager.cameraIdList.firstOrNull() ?: return false
            cameraManager.setTorchMode(cameraId, enable)
            true
        } catch (e: CameraAccessException) {
            false
        } catch (e: Exception) {
            false
        }
    }

    private fun setCountdownTimer(seconds: Int, label: String): Boolean {
        return try {
            val intent = Intent(AlarmClock.ACTION_SET_TIMER).apply {
                putExtra(AlarmClock.EXTRA_LENGTH, seconds)
                putExtra(AlarmClock.EXTRA_MESSAGE, label)
                putExtra(AlarmClock.EXTRA_SKIP_UI, false)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            activity.startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun cancelTimer(): Boolean {
        return try {
            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Intent(AlarmClock.ACTION_DISMISS_TIMER).apply {
                    putExtra(AlarmClock.EXTRA_SKIP_UI, false)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
            } else {
                Intent(AlarmClock.ACTION_SHOW_TIMERS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
            }
            activity.startActivity(intent)
            true
        } catch (e: Exception) {
            try {
                val fallback = Intent(AlarmClock.ACTION_SHOW_TIMERS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                activity.startActivity(fallback)
                true
            } catch (ex: Exception) {
                false
            }
        }
    }

    private fun openSystemSetting(type: String): Boolean {
        return try {
            val cleanType = type.lowercase().trim()
            val action = when (cleanType) {
                "wifi", "wi-fi" -> Settings.ACTION_WIFI_SETTINGS
                "bluetooth" -> Settings.ACTION_BLUETOOTH_SETTINGS
                "sound", "volume" -> Settings.ACTION_SOUND_SETTINGS
                "display" -> Settings.ACTION_DISPLAY_SETTINGS
                "battery" -> Intent.ACTION_POWER_USAGE_SUMMARY
                "notifications", "notification" -> Settings.ACTION_APP_NOTIFICATION_SETTINGS
                "settings" -> Settings.ACTION_SETTINGS
                "app", "vajra", "vajra_app", "vajra app settings" -> Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                else -> Settings.ACTION_SETTINGS
            }

            val intent = Intent(action).apply {
                if (action == Settings.ACTION_APPLICATION_DETAILS_SETTINGS) {
                    data = Uri.fromParts("package", activity.packageName, null)
                } else if (action == Settings.ACTION_APP_NOTIFICATION_SETTINGS) {
                    putExtra(Settings.EXTRA_APP_PACKAGE, activity.packageName)
                }
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            activity.startActivity(intent)
            true
        } catch (e: Exception) {
            try {
                val fallbackIntent = Intent(Settings.ACTION_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                activity.startActivity(fallbackIntent)
                true
            } catch (ex: Exception) {
                false
            }
        }
    }

    private fun adjustVolume(direction: String): Boolean {
        return try {
            val audioManager = activity.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
                ?: return false
            val dir = if (direction.lowercase().trim() == "down") {
                AudioManager.ADJUST_LOWER
            } else {
                AudioManager.ADJUST_RAISE
            }
            audioManager.adjustVolume(dir, AudioManager.FLAG_SHOW_UI)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun dispatchMediaControl(command: String): Boolean {
        return try {
            val audioManager = activity.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
                ?: return false

            val keyCode = when (command.lowercase()) {
                "pause" -> KeyEvent.KEYCODE_MEDIA_PAUSE
                "play" -> KeyEvent.KEYCODE_MEDIA_PLAY
                "resume" -> KeyEvent.KEYCODE_MEDIA_PLAY
                "stop" -> KeyEvent.KEYCODE_MEDIA_STOP
                "next" -> KeyEvent.KEYCODE_MEDIA_NEXT
                "previous", "prev" -> KeyEvent.KEYCODE_MEDIA_PREVIOUS
                else -> KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE
            }

            audioManager.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, keyCode))
            audioManager.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_UP, keyCode))
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun openApp(packageName: String): Boolean {
        if (packageName.isBlank()) return false
        return try {
            val pm = activity.packageManager
            val intent = pm.getLaunchIntentForPackage(packageName) ?: return false
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            activity.startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun isAppInstalled(packageName: String): Boolean {
        if (packageName.isBlank()) return false
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                activity.packageManager.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(0))
            } else {
                @Suppress("DEPRECATION")
                activity.packageManager.getPackageInfo(packageName, 0)
            }
            true
        } catch (e: PackageManager.NameNotFoundException) {
            activity.packageManager.getLaunchIntentForPackage(packageName) != null
        } catch (e: Exception) {
            false
        }
    }

    private fun executeAppAction(
        actionType: String,
        packageName: String?,
        uriString: String?,
        extraParams: Map<String, Any?>
    ): Map<String, Any?> {
        return try {
            when (actionType) {
                "app.launch" -> {
                    val pkg = packageName ?: return mapOf("success" to false, "error" to "MISSING_PACKAGE")
                    val ok = openApp(pkg)
                    mapOf("success" to ok, "error" to if (ok) null else "LAUNCH_FAILED")
                }
                "browser.search" -> {
                    val query = extraParams["query"]?.toString() ?: ""
                    val targetUri = Uri.parse("https://www.google.com/search?q=${Uri.encode(query)}")
                    val intent = Intent(Intent.ACTION_VIEW, targetUri).apply {
                        if (!packageName.isNullOrBlank()) setPackage(packageName)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    activity.startActivity(intent)
                    mapOf("success" to true)
                }
                "browser.open_url" -> {
                    var url = uriString ?: extraParams["url"]?.toString() ?: ""
                    if (!url.startsWith("http://") && !url.startsWith("https://")) {
                        url = "https://$url"
                    }
                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                        if (!packageName.isNullOrBlank()) setPackage(packageName)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    activity.startActivity(intent)
                    mapOf("success" to true)
                }
                "youtube.search" -> {
                    val query = extraParams["query"]?.toString() ?: ""
                    val ytUri = Uri.parse("https://www.youtube.com/results?search_query=${Uri.encode(query)}")
                    val intent = Intent(Intent.ACTION_VIEW, ytUri).apply {
                        if (!packageName.isNullOrBlank()) setPackage(packageName)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    activity.startActivity(intent)
                    mapOf("success" to true)
                }
                "youtube.open_video" -> {
                    val url = uriString ?: extraParams["url"]?.toString() ?: ""
                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                        if (!packageName.isNullOrBlank()) setPackage(packageName)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    activity.startActivity(intent)
                    mapOf("success" to true)
                }
                "youtube.open_channel" -> {
                    var channel = extraParams["channel"]?.toString() ?: uriString ?: ""
                    if (!channel.startsWith("@") && !channel.startsWith("http")) {
                        channel = "@$channel"
                    }
                    val ytUri = if (channel.startsWith("http")) {
                        Uri.parse(channel)
                    } else {
                        Uri.parse("https://www.youtube.com/$channel")
                    }
                    val intent = Intent(Intent.ACTION_VIEW, ytUri).apply {
                        if (!packageName.isNullOrBlank()) setPackage(packageName)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    activity.startActivity(intent)
                    mapOf("success" to true)
                }
                "maps.search" -> {
                    val query = extraParams["query"]?.toString() ?: ""
                    val mapsUri = Uri.parse("geo:0,0?q=${Uri.encode(query)}")
                    val intent = Intent(Intent.ACTION_VIEW, mapsUri).apply {
                        if (!packageName.isNullOrBlank()) setPackage(packageName)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    activity.startActivity(intent)
                    mapOf("success" to true)
                }
                "maps.directions" -> {
                    val destination = extraParams["destination"]?.toString() ?: ""
                    val dirUri = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=${Uri.encode(destination)}")
                    val intent = Intent(Intent.ACTION_VIEW, dirUri).apply {
                        if (!packageName.isNullOrBlank()) setPackage(packageName)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    activity.startActivity(intent)
                    mapOf("success" to true)
                }
                "maps.navigate" -> {
                    val destination = extraParams["destination"]?.toString() ?: ""
                    val navUri = Uri.parse("google.navigation:q=${Uri.encode(destination)}")
                    val intent = Intent(Intent.ACTION_VIEW, navUri).apply {
                        if (!packageName.isNullOrBlank()) setPackage(packageName)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    activity.startActivity(intent)
                    mapOf("success" to true)
                }
                "instagram.profile" -> {
                    val username = extraParams["username"]?.toString()?.removePrefix("@")?.trim() ?: ""
                    val igUri = Uri.parse("https://www.instagram.com/_u/$username")
                    val intent = Intent(Intent.ACTION_VIEW, igUri).apply {
                        if (!packageName.isNullOrBlank()) setPackage(packageName)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    activity.startActivity(intent)
                    mapOf("success" to true)
                }
                "instagram.post" -> {
                    val postUrl = uriString ?: extraParams["url"]?.toString() ?: ""
                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(postUrl)).apply {
                        if (!packageName.isNullOrBlank()) setPackage(packageName)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    activity.startActivity(intent)
                    mapOf("success" to true)
                }
                "instagram.reel" -> {
                    val reelUrl = uriString ?: extraParams["url"]?.toString() ?: ""
                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(reelUrl)).apply {
                        if (!packageName.isNullOrBlank()) setPackage(packageName)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    activity.startActivity(intent)
                    mapOf("success" to true)
                }
                "instagram.open_url" -> {
                    val url = uriString ?: extraParams["url"]?.toString() ?: ""
                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                        if (!packageName.isNullOrBlank()) setPackage(packageName)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    activity.startActivity(intent)
                    mapOf("success" to true)
                }
                "whatsapp.chat" -> {
                    val phone = extraParams["phone"]?.toString()?.replace(Regex("[^0-9+]"), "") ?: ""
                    val waUri = if (phone.isNotEmpty()) {
                        Uri.parse("https://api.whatsapp.com/send?phone=$phone")
                    } else {
                        Uri.parse("https://api.whatsapp.com/send")
                    }
                    val intent = Intent(Intent.ACTION_VIEW, waUri).apply {
                        if (!packageName.isNullOrBlank()) setPackage(packageName)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    activity.startActivity(intent)
                    mapOf("success" to true)
                }
                "whatsapp.prepare_message" -> {
                    val phone = extraParams["phone"]?.toString()?.replace(Regex("[^0-9+]"), "") ?: ""
                    val text = extraParams["message"]?.toString() ?: extraParams["text"]?.toString() ?: ""
                    val waUri = if (phone.isNotEmpty()) {
                        Uri.parse("https://api.whatsapp.com/send?phone=$phone&text=${Uri.encode(text)}")
                    } else {
                        Uri.parse("https://api.whatsapp.com/send?text=${Uri.encode(text)}")
                    }
                    val intent = Intent(Intent.ACTION_VIEW, waUri).apply {
                        if (!packageName.isNullOrBlank()) setPackage(packageName)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    activity.startActivity(intent)
                    mapOf("success" to true)
                }
                else -> mapOf("success" to false, "error" to "UNSUPPORTED_ACTION")
            }
        } catch (e: Exception) {
            mapOf("success" to false, "error" to (e.message ?: "ACTION_EXCEPTION"))
        }
    }
}
