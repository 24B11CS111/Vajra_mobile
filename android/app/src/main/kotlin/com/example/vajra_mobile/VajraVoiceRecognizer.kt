package com.example.vajra_mobile

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class VajraVoiceRecognizer(private val activity: Activity) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        private const val TAG = "VajraVoiceRecognizer"
        private const val METHOD_CHANNEL_NAME = "com.vajra.app/voice"
        private const val EVENT_CHANNEL_NAME = "com.vajra.app/voice/events"
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null

    private var speechRecognizer: SpeechRecognizer? = null
    private var isListening: Boolean = false

    fun register(messenger: BinaryMessenger) {
        methodChannel = MethodChannel(messenger, METHOD_CHANNEL_NAME).apply {
            setMethodCallHandler(this@VajraVoiceRecognizer)
        }
        eventChannel = EventChannel(messenger, EVENT_CHANNEL_NAME).apply {
            setStreamHandler(this@VajraVoiceRecognizer)
        }
    }

    fun cleanup() {
        mainHandler.post {
            destroyRecognizer()
            methodChannel?.setMethodCallHandler(null)
            methodChannel = null
            eventChannel?.setStreamHandler(null)
            eventChannel = null
            eventSink = null
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkAvailability" -> {
                val available = SpeechRecognizer.isRecognitionAvailable(activity)
                val onDeviceAvailable = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    SpeechRecognizer.isOnDeviceRecognitionAvailable(activity)
                } else {
                    false
                }
                result.success(
                    mapOf(
                        "available" to available,
                        "onDeviceAvailable" to onDeviceAvailable
                    )
                )
            }
            "startListening" -> {
                val perm = activity.checkSelfPermission(android.Manifest.permission.RECORD_AUDIO)
                if (perm != PackageManager.PERMISSION_GRANTED) {
                    result.error(
                        "PERMISSION_DENIED",
                        "Microphone permission not granted.",
                        null
                    )
                    return
                }

                val locale = call.argument<String>("locale")
                mainHandler.post {
                    startNativeListening(locale, result)
                }
            }
            "stopListening" -> {
                mainHandler.post {
                    try {
                        if (isListening) {
                            speechRecognizer?.stopListening()
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        Log.w(TAG, "Error stopping listener: ${e.message}")
                        result.success(false)
                    }
                }
            }
            "cancelListening" -> {
                mainHandler.post {
                    try {
                        if (isListening) {
                            speechRecognizer?.cancel()
                            isListening = false
                            sendEvent("cancelled", emptyMap())
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        Log.w(TAG, "Error cancelling listener: ${e.message}")
                        result.success(false)
                    }
                }
            }
            "openAppSettings" -> {
                try {
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.fromParts("package", activity.packageName, null)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    activity.startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("SETTINGS_ERROR", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun startNativeListening(locale: String?, result: MethodChannel.Result) {
        destroyRecognizer()

        val onDevice = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            SpeechRecognizer.isOnDeviceRecognitionAvailable(activity)
        ) {
            try {
                speechRecognizer = SpeechRecognizer.createOnDeviceSpeechRecognizer(activity)
                true
            } catch (e: Exception) {
                Log.w(TAG, "Failed creating on-device recognizer, falling back to standard: ${e.message}")
                speechRecognizer = SpeechRecognizer.createSpeechRecognizer(activity)
                false
            }
        } else {
            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(activity)
            false
        }

        val recognizer = speechRecognizer
        if (recognizer == null) {
            result.error("RECOGNIZER_UNAVAILABLE", "Failed to instantiate SpeechRecognizer", null)
            return
        }

        recognizer.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {
                isListening = true
                sendEvent("ready", mapOf("onDevice" to onDevice))
            }

            override fun onBeginningOfSpeech() {
                sendEvent("speechStart", emptyMap())
            }

            override fun onRmsChanged(rmsdB: Float) {
                // Normalize rmsdB (-2 to 10 dB) roughly to 0.0 to 1.0 for UI visualizer
                val normalized = ((rmsdB + 2f) / 12f).coerceIn(0f, 1f)
                sendEvent("rms", mapOf("rms" to rmsdB.toDouble(), "normalized" to normalized.toDouble()))
            }

            override fun onBufferReceived(buffer: ByteArray?) {}

            override fun onEndOfSpeech() {
                sendEvent("speechEnd", emptyMap())
            }

            override fun onError(error: Int) {
                isListening = false
                val (code, message) = when (error) {
                    SpeechRecognizer.ERROR_AUDIO -> "audio_error" to "Audio recording error. Please check your microphone."
                    SpeechRecognizer.ERROR_CLIENT -> "client_error" to "Voice service encountered an error."
                    SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "permission_denied" to "Microphone permission is required."
                    SpeechRecognizer.ERROR_NETWORK -> "network_error" to "Network connection error during voice recognition."
                    SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "network_timeout" to "Speech recognition connection timed out."
                    SpeechRecognizer.ERROR_NO_MATCH -> "no_speech" to "No speech detected. Tap the mic when ready."
                    SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "recognizer_busy" to "Speech recognizer is currently busy."
                    SpeechRecognizer.ERROR_SERVER -> "server_error" to "Speech service server error. Please try again."
                    SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "no_speech" to "No speech detected. Tap the mic when ready."
                    10 -> "too_many_requests" to "Too many voice requests. Please wait a moment."
                    11 -> "server_disconnected" to "Speech recognition disconnected."
                    14 -> "cannot_check_support" to "Cannot check speech recognition support."
                    else -> "unknown_error" to "Speech recognition stopped (code $error)."
                }
                sendEvent(
                    "error",
                    mapOf(
                        "errorCode" to code,
                        "rawCode" to error,
                        "message" to message
                    )
                )
            }

            override fun onResults(results: Bundle?) {
                isListening = false
                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                val text = matches?.firstOrNull()?.trim() ?: ""
                sendEvent("finalResult", mapOf("text" to text))
            }

            override fun onPartialResults(partialResults: Bundle?) {
                val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                val text = matches?.firstOrNull()?.trim() ?: ""
                if (text.isNotEmpty()) {
                    sendEvent("partialResult", mapOf("text" to text))
                }
            }

            override fun onEvent(eventType: Int, params: Bundle?) {}
        })

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 3)
            if (!locale.isNullOrBlank()) {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, locale)
            }
        }

        try {
            recognizer.startListening(intent)
            result.success(mapOf("started" to true, "onDevice" to onDevice))
        } catch (e: Exception) {
            Log.e(TAG, "startListening error: ${e.message}", e)
            result.error("START_FAILED", e.message, null)
        }
    }

    private fun destroyRecognizer() {
        try {
            speechRecognizer?.stopListening()
            speechRecognizer?.cancel()
            speechRecognizer?.destroy()
        } catch (e: Exception) {
            Log.w(TAG, "destroyRecognizer warning: ${e.message}")
        } finally {
            speechRecognizer = null
            isListening = false
        }
    }

    private fun sendEvent(type: String, data: Map<String, Any>) {
        val payload = HashMap<String, Any>(data).apply {
            put("type", type)
        }
        mainHandler.post {
            try {
                eventSink?.success(payload)
            } catch (e: Exception) {
                Log.w(TAG, "sendEvent failed: ${e.message}")
            }
        }
    }
}
