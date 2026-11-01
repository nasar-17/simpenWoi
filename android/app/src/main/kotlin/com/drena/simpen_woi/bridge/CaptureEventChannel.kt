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
    private var sink: EventChannel.EventSink? = null
    private var pendingChange = false

    fun attach(flutterEngine: FlutterEngine) {
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NAME,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    sink = events
                    deliverPendingChange()
                }

                override fun onCancel(arguments: Any?) {
                    sink = null
                }
            },
        )
    }

    fun emitQueueChanged() {
        mainHandler.post {
            pendingChange = true
            deliverPendingChange()
        }
    }

    private fun deliverPendingChange() {
        if (!pendingChange) return
        val events = sink ?: return
        try {
            events.success(mapOf(EVENT_TYPE to QUEUE_CHANGED))
            pendingChange = false
        } catch (_: RuntimeException) {
            // The queue stays durable and this signal can be delivered later.
            sink = null
        }
    }
}
