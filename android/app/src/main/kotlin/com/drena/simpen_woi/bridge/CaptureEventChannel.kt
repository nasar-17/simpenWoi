package com.drena.simpen_woi.bridge

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

object CaptureEventChannel {
    private const val NAME = "simpenwoi/capture_events"
    private const val EVENT_TYPE = "type"
    private const val QUEUE_CHANGED = "queue_changed"

    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    private var sink: EventChannel.EventSink? = null

    fun attach(flutterEngine: FlutterEngine) {
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NAME,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    sink = events
                }

                override fun onCancel(arguments: Any?) {
                    sink = null
                }
            },
        )
    }

    fun emitQueueChanged() {
        mainHandler.post {
            try {
                sink?.success(mapOf(EVENT_TYPE to QUEUE_CHANGED))
            } catch (_: Exception) {
            }
        }
    }
}
