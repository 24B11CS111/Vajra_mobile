package com.example.vajra_mobile

import android.app.Activity
import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale
import java.util.UUID

class VajraTextToSpeech(private val activity: Activity) :
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    companion object {
        private const val TAG = "VAJRA_TTS"
        private const val METHOD_CHANNEL_NAME = "com.vajra.app/tts"
        private const val EVENT_CHANNEL_NAME = "com.vajra.app/tts/events"
        private const val MAX_CHUNK_LENGTH = 350
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null

    private var tts: TextToSpeech? = null
    private var isInitialized: Boolean = false
    private var isInitializing: Boolean = false
    private val initCallbacks = mutableListOf<(Boolean) -> Unit>()

    private var activeUtteranceId: String? = null
    private var expectedFinalChunkId: String? = null
    private var audioFocusRequest: AudioFocusRequest? = null

    fun register(messenger: BinaryMessenger) {
        Log.i(TAG, "Registering TTS channels: $METHOD_CHANNEL_NAME and $EVENT_CHANNEL_NAME")
        methodChannel = MethodChannel(messenger, METHOD_CHANNEL_NAME).apply {
            setMethodCallHandler(this@VajraTextToSpeech)
        }
        eventChannel = EventChannel(messenger, EVENT_CHANNEL_NAME).apply {
            setStreamHandler(this@VajraTextToSpeech)
        }
    }

    fun initializeImmediately() {
        Log.i(TAG, "initializeImmediately: Warming up TTS engine eagerly on startup")
        initializeTts { success ->
            Log.i(TAG, "Startup TTS engine warmup completed: success=$success, engine=${tts?.defaultEngine}")
        }
    }

    fun cleanup() {
        Log.i(TAG, "cleanup: Releasing TTS resources")
        mainHandler.post {
            try {
                abandonAudioFocus()
                tts?.stop()
                tts?.shutdown()
            } catch (e: Exception) {
                Log.w(TAG, "Error shutting down TTS: ${e.message}")
            } finally {
                tts = null
                isInitialized = false
                isInitializing = false
                initCallbacks.clear()
                activeUtteranceId = null
                expectedFinalChunkId = null
                methodChannel?.setMethodCallHandler(null)
                methodChannel = null
                eventChannel?.setStreamHandler(null)
                eventChannel = null
                eventSink = null
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                Log.d(TAG, "MethodCall: initialize")
                initializeTts { success ->
                    val engineName = tts?.defaultEngine ?: "unknown"
                    val lang = tts?.language?.toString() ?: "unknown"
                    val voiceName = tts?.voice?.name ?: "default"
                    Log.i(TAG, "initialize response: success=$success, engine=$engineName, lang=$lang, voice=$voiceName")
                    result.success(
                        mapOf(
                            "available" to success,
                            "initialized" to success,
                            "language" to lang,
                            "engine" to engineName,
                            "voice" to voiceName
                        )
                    )
                }
            }
            "isAvailable" -> {
                val available = isInitialized && tts != null
                val isSpeaking = try {
                    tts?.isSpeaking == true
                } catch (e: Exception) {
                    false
                }
                result.success(
                    mapOf(
                        "available" to available,
                        "isSpeaking" to isSpeaking
                    )
                )
            }
            "speak" -> {
                val text = call.argument<String>("text") ?: ""
                val utteranceId = call.argument<String>("utteranceId") ?: UUID.randomUUID().toString()

                if (text.isBlank()) {
                    Log.d(TAG, "MethodCall speak: Empty or blank text, skipping")
                    result.success(false)
                    return
                }

                Log.i(TAG, "MethodCall speak: textLength=${text.length}, utteranceId=$utteranceId")

                ensureInitialized { success ->
                    if (!success || tts == null) {
                        Log.e(TAG, "speak failed: TextToSpeech engine unavailable")
                        result.error(
                            "TTS_UNAVAILABLE",
                            "Voice output isn't available right now.",
                            null
                        )
                        return@ensureInitialized
                    }

                    mainHandler.post {
                        val speakSuccess = executeSpeak(text, utteranceId)
                        result.success(speakSuccess)
                    }
                }
            }
            "stop" -> {
                Log.i(TAG, "MethodCall stop: Halting active TTS speech")
                mainHandler.post {
                    executeStop(notifyEvent = true)
                    result.success(true)
                }
            }
            "setLanguage" -> {
                val langTag = call.argument<String>("language")
                Log.i(TAG, "MethodCall setLanguage: $langTag")
                if (langTag.isNullOrBlank()) {
                    result.success(false)
                    return
                }

                ensureInitialized { success ->
                    if (!success || tts == null) {
                        result.success(false)
                        return@ensureInitialized
                    }

                    val loc = Locale.forLanguageTag(langTag)
                    val langRes = tts?.setLanguage(loc)
                    val supported = langRes != null &&
                            langRes != TextToSpeech.LANG_MISSING_DATA &&
                            langRes != TextToSpeech.LANG_NOT_SUPPORTED
                    Log.i(TAG, "setLanguage($langTag) result=$langRes, supported=$supported")
                    result.success(supported)
                }
            }
            "testDiagnosticSpeak" -> {
                val utteranceId = "diagnostic_${UUID.randomUUID()}"
                Log.i(TAG, "MethodCall testDiagnosticSpeak requested: utteranceId=$utteranceId")
                ensureInitialized { success ->
                    if (!success || tts == null) {
                        Log.e(TAG, "testDiagnosticSpeak failed: TTS not initialized")
                        result.success(
                            mapOf(
                                "success" to false,
                                "error" to "TTS_INITIALIZATION_FAILED",
                                "engine" to (tts?.defaultEngine ?: "unknown"),
                                "initialized" to false
                            )
                        )
                        return@ensureInitialized
                    }

                    val audioManager = activity.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
                    val streamVol = audioManager?.getStreamVolume(AudioManager.STREAM_MUSIC) ?: -1
                    val maxVol = audioManager?.getStreamMaxVolume(AudioManager.STREAM_MUSIC) ?: -1

                    val speakSuccess = executeSpeak("VAJRA voice test successful.", utteranceId)
                    Log.i(TAG, "testDiagnosticSpeak executeSpeak: result=$speakSuccess, volume=$streamVol/$maxVol")
                    result.success(
                        mapOf(
                            "success" to speakSuccess,
                            "utteranceId" to utteranceId,
                            "engine" to (tts?.defaultEngine ?: "unknown"),
                            "language" to (tts?.language?.toString() ?: "unknown"),
                            "voice" to (tts?.voice?.name ?: "default"),
                            "streamVolume" to streamVol,
                            "maxVolume" to maxVol,
                            "isSpeaking" to (tts?.isSpeaking == true)
                        )
                    )
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        Log.d(TAG, "EventChannel onListen")
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        Log.d(TAG, "EventChannel onCancel")
        eventSink = null
    }

    private fun initializeTts(callback: (Boolean) -> Unit) {
        if (isInitialized && tts != null) {
            callback(true)
            return
        }

        initCallbacks.add(callback)
        if (isInitializing) {
            Log.d(TAG, "initializeTts: already in progress, callback enqueued (queueSize=${initCallbacks.size})")
            return
        }

        isInitializing = true
        Log.i(TAG, "initializeTts: Instantiating android.speech.tts.TextToSpeech...")
        mainHandler.post {
            try {
                tts = TextToSpeech(activity.applicationContext) { status ->
                    mainHandler.post {
                        isInitializing = false
                        if (status == TextToSpeech.SUCCESS && tts != null) {
                            Log.i(TAG, "TextToSpeech init SUCCESS. Default engine: ${tts?.defaultEngine}")
                            configureTtsInstance()
                            isInitialized = true
                            notifyInitCallbacks(true)
                        } else {
                            Log.e(TAG, "TextToSpeech init FAILED with status: $status")
                            isInitialized = false
                            tts = null
                            notifyInitCallbacks(false)
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Exception initializing TextToSpeech: ${e.message}", e)
                isInitializing = false
                isInitialized = false
                tts = null
                notifyInitCallbacks(false)
            }
        }
    }

    private fun ensureInitialized(callback: (Boolean) -> Unit) {
        if (isInitialized && tts != null) {
            callback(true)
        } else {
            initializeTts(callback)
        }
    }

    private fun notifyInitCallbacks(success: Boolean) {
        val callbacks = ArrayList(initCallbacks)
        initCallbacks.clear()
        for (cb in callbacks) {
            cb(success)
        }
    }

    private fun configureTtsInstance() {
        val ttsInstance = tts ?: return

        // 1. Configure AudioAttributes for MEDIA playback
        try {
            val audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                .build()
            ttsInstance.setAudioAttributes(audioAttributes)
            Log.i(TAG, "Configured AudioAttributes: USAGE_MEDIA, CONTENT_TYPE_SPEECH")
        } catch (e: Exception) {
            Log.w(TAG, "Failed to set AudioAttributes on TextToSpeech: ${e.message}")
        }

        // 2. Check and log current media volume
        logStreamVolume()

        // 3. Robust Language and Voice resolution
        resolveLanguageAndVoice(ttsInstance)

        // 4. Register comprehensive UtteranceProgressListener
        ttsInstance.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
            override fun onStart(utteranceId: String?) {
                Log.i(TAG, "onStart: utteranceId=$utteranceId")
                val currentActiveId = activeUtteranceId
                if (utteranceId != null && currentActiveId != null && utteranceId.startsWith(currentActiveId)) {
                    sendEvent("start", mapOf("utteranceId" to currentActiveId))
                }
            }

            override fun onDone(utteranceId: String?) {
                Log.i(TAG, "onDone: utteranceId=$utteranceId")
                if (utteranceId != null && utteranceId == expectedFinalChunkId) {
                    val id = activeUtteranceId ?: utteranceId
                    activeUtteranceId = null
                    expectedFinalChunkId = null
                    abandonAudioFocus()
                    sendEvent("done", mapOf("utteranceId" to id))
                }
            }

            @Suppress("DEPRECATION")
            override fun onError(utteranceId: String?) {
                Log.e(TAG, "onError (legacy): utteranceId=$utteranceId")
                val id = activeUtteranceId ?: (utteranceId ?: "")
                activeUtteranceId = null
                expectedFinalChunkId = null
                abandonAudioFocus()
                sendEvent(
                    "error",
                    mapOf(
                        "utteranceId" to id,
                        "errorCode" to "playback_error",
                        "message" to "Voice output encountered an issue."
                    )
                )
            }

            override fun onError(utteranceId: String?, errorCode: Int) {
                val errorName = getErrorName(errorCode)
                Log.e(TAG, "onError: utteranceId=$utteranceId, code=$errorCode ($errorName)")
                val id = activeUtteranceId ?: (utteranceId ?: "")
                activeUtteranceId = null
                expectedFinalChunkId = null
                abandonAudioFocus()
                sendEvent(
                    "error",
                    mapOf(
                        "utteranceId" to id,
                        "errorCode" to "playback_error_$errorCode",
                        "message" to "Voice output error: $errorName"
                    )
                )
            }

            override fun onStop(utteranceId: String?, interrupted: Boolean) {
                Log.i(TAG, "onStop: utteranceId=$utteranceId, interrupted=$interrupted")
                val id = activeUtteranceId ?: (utteranceId ?: "")
                activeUtteranceId = null
                expectedFinalChunkId = null
                abandonAudioFocus()
                sendEvent(
                    "stop",
                    mapOf(
                        "utteranceId" to id,
                        "interrupted" to interrupted
                    )
                )
            }
        })
    }

    private fun resolveLanguageAndVoice(ttsInstance: TextToSpeech) {
        var resolvedLocale: Locale? = null
        val candidates = listOf(
            Locale.getDefault(),
            Locale.US,
            Locale.UK,
            Locale("en", "IN"),
            Locale("en", "GB"),
            Locale.CANADA
        )

        for (loc in candidates) {
            try {
                val avail = ttsInstance.isLanguageAvailable(loc)
                Log.d(TAG, "isLanguageAvailable for $loc: $avail")
                if (avail >= TextToSpeech.LANG_AVAILABLE) {
                    val res = ttsInstance.setLanguage(loc)
                    Log.d(TAG, "setLanguage($loc) returned: $res")
                    if (res >= TextToSpeech.LANG_AVAILABLE) {
                        resolvedLocale = loc
                        Log.i(TAG, "Successfully resolved and set language: $loc")
                        break
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "Error testing locale $loc: ${e.message}")
            }
        }

        // If candidates failed, try defaultVoice or existing installed voice
        if (resolvedLocale == null) {
            try {
                val defaultVoice = ttsInstance.defaultVoice
                if (defaultVoice != null) {
                    ttsInstance.voice = defaultVoice
                    resolvedLocale = defaultVoice.locale
                    Log.i(TAG, "Fell back to defaultVoice: ${defaultVoice.name}, locale=${defaultVoice.locale}")
                } else {
                    val installedVoice = ttsInstance.voices?.firstOrNull { voice ->
                        !voice.isNetworkConnectionRequired && voice.locale.language == "en"
                    } ?: ttsInstance.voices?.firstOrNull()

                    if (installedVoice != null) {
                        ttsInstance.voice = installedVoice
                        resolvedLocale = installedVoice.locale
                        Log.i(TAG, "Fell back to installed voice: ${installedVoice.name}, locale=${installedVoice.locale}")
                    } else {
                        Log.w(TAG, "No optimal voice found. Active language remains: ${ttsInstance.language}")
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "Error resolving fallback voice: ${e.message}")
            }
        }

        Log.i(TAG, "Active voice: ${ttsInstance.voice?.name ?: "default"}, language: ${ttsInstance.language}")
    }

    private fun executeSpeak(text: String, utteranceId: String): Boolean {
        val ttsInstance = tts ?: return false

        // Stop any previous active speech first to prevent overlapping audio
        executeStop(notifyEvent = false)

        activeUtteranceId = utteranceId
        val chunks = splitIntoNaturalChunks(text)
        if (chunks.isEmpty()) {
            Log.w(TAG, "executeSpeak: Text chunks empty after splitting")
            return false
        }

        expectedFinalChunkId = "${utteranceId}_chunk_${chunks.size - 1}"
        Log.i(TAG, "executeSpeak: utteranceId=$utteranceId, chunksCount=${chunks.size}, textLength=${text.length}")

        // Request transient audio focus with ducking so media players yield cleanly
        requestAudioFocus()

        // Build explicit Bundle routing to STREAM_MUSIC with volume 1.0f
        val params = Bundle().apply {
            putInt(TextToSpeech.Engine.KEY_PARAM_STREAM, AudioManager.STREAM_MUSIC)
            putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, 1.0f)
        }

        var allQueued = true
        for (i in chunks.indices) {
            val chunk = chunks[i]
            val chunkUtteranceId = "${utteranceId}_chunk_$i"
            val queueMode = if (i == 0) TextToSpeech.QUEUE_FLUSH else TextToSpeech.QUEUE_ADD

            val res = ttsInstance.speak(chunk, queueMode, params, chunkUtteranceId)
            if (res != TextToSpeech.SUCCESS) {
                Log.w(TAG, "tts.speak returned error code $res for chunk $i ($chunkUtteranceId)")
                allQueued = false
            } else {
                Log.d(TAG, "tts.speak queued chunk $i successfully ($chunkUtteranceId)")
            }
        }

        return allQueued
    }

    private fun executeStop(notifyEvent: Boolean = true) {
        try {
            tts?.stop()
        } catch (e: Exception) {
            Log.w(TAG, "Error stopping TTS: ${e.message}")
        }
        abandonAudioFocus()
        val priorId = activeUtteranceId
        activeUtteranceId = null
        expectedFinalChunkId = null
        if (notifyEvent) {
            sendEvent("stop", mapOf("utteranceId" to (priorId ?: ""), "interrupted" to true))
        }
    }

    private fun requestAudioFocus(): Boolean {
        val audioManager = activity.getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return false
        logStreamVolume()

        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val req = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_MEDIA)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                            .build()
                    )
                    .setOnAudioFocusChangeListener { focusChange ->
                        Log.d(TAG, "Audio focus changed: $focusChange")
                    }
                    .build()
                audioFocusRequest = req
                val res = audioManager.requestAudioFocus(req)
                Log.d(TAG, "requestAudioFocus result: $res")
                res == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
            } else {
                @Suppress("DEPRECATION")
                val res = audioManager.requestAudioFocus(
                    null,
                    AudioManager.STREAM_MUSIC,
                    AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK
                )
                res == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error requesting audio focus: ${e.message}")
            false
        }
    }

    private fun abandonAudioFocus() {
        try {
            val audioManager = activity.getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                audioFocusRequest?.let {
                    audioManager.abandonAudioFocusRequest(it)
                    audioFocusRequest = null
                    Log.d(TAG, "abandonAudioFocusRequest completed")
                }
            } else {
                @Suppress("DEPRECATION")
                audioManager.abandonAudioFocus(null)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error abandoning audio focus: ${e.message}")
        }
    }

    private fun logStreamVolume() {
        try {
            val audioManager = activity.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            val currentVol = audioManager?.getStreamVolume(AudioManager.STREAM_MUSIC) ?: -1
            val maxVol = audioManager?.getStreamMaxVolume(AudioManager.STREAM_MUSIC) ?: -1
            Log.i(TAG, "Audio Stream Music volume: $currentVol / $maxVol")
            if (currentVol == 0) {
                Log.w(TAG, "WARNING: STREAM_MUSIC volume is 0 (MUTED)! Device speaker will produce no sound until media volume is unmuted.")
            }
        } catch (e: Exception) {
            Log.w(TAG, "Unable to inspect stream volume: ${e.message}")
        }
    }

    private fun getErrorName(errorCode: Int): String {
        return when (errorCode) {
            TextToSpeech.ERROR_SYNTHESIS -> "ERROR_SYNTHESIS (-3)"
            TextToSpeech.ERROR_SERVICE -> "ERROR_SERVICE (-4)"
            TextToSpeech.ERROR_OUTPUT -> "ERROR_OUTPUT (-5)"
            TextToSpeech.ERROR_NETWORK -> "ERROR_NETWORK (-6)"
            TextToSpeech.ERROR_NETWORK_TIMEOUT -> "ERROR_NETWORK_TIMEOUT (-7)"
            TextToSpeech.ERROR_INVALID_REQUEST -> "ERROR_INVALID_REQUEST (-8)"
            TextToSpeech.ERROR_NOT_INSTALLED_YET -> "ERROR_NOT_INSTALLED_YET (-9)"
            else -> "ERROR_UNKNOWN ($errorCode)"
        }
    }

    private fun splitIntoNaturalChunks(text: String): List<String> {
        val trimmed = text.trim()
        if (trimmed.isEmpty()) return emptyList()

        if (trimmed.length <= MAX_CHUNK_LENGTH) {
            return listOf(trimmed)
        }

        // Split text by sentence boundaries (.!? followed by space or newline)
        val sentenceRegex = Regex("(?<=[.!?])\\s+")
        val sentences = trimmed.split(sentenceRegex)
        val chunks = mutableListOf<String>()
        var currentChunk = StringBuilder()

        for (sentence in sentences) {
            val s = sentence.trim()
            if (s.isEmpty()) continue

            if (s.length > MAX_CHUNK_LENGTH) {
                // If an individual sentence exceeds max length, split on commas or spaces
                if (currentChunk.isNotEmpty()) {
                    chunks.add(currentChunk.toString().trim())
                    currentChunk = StringBuilder()
                }
                val subParts = s.split(Regex("(?<=,)\\s+|\\s+"))
                var subChunk = StringBuilder()
                for (part in subParts) {
                    if (subChunk.length + part.length + 1 > MAX_CHUNK_LENGTH) {
                        if (subChunk.isNotEmpty()) {
                            chunks.add(subChunk.toString().trim())
                            subChunk = StringBuilder()
                        }
                    }
                    if (subChunk.isNotEmpty()) subChunk.append(" ")
                    subChunk.append(part)
                }
                if (subChunk.isNotEmpty()) {
                    chunks.add(subChunk.toString().trim())
                }
            } else {
                if (currentChunk.length + s.length + 1 > MAX_CHUNK_LENGTH) {
                    chunks.add(currentChunk.toString().trim())
                    currentChunk = StringBuilder()
                }
                if (currentChunk.isNotEmpty()) currentChunk.append(" ")
                currentChunk.append(s)
            }
        }

        if (currentChunk.isNotEmpty()) {
            chunks.add(currentChunk.toString().trim())
        }

        return if (chunks.isEmpty()) listOf(trimmed) else chunks
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
