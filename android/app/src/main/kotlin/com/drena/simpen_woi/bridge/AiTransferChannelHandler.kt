package com.drena.simpen_woi.bridge

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.drena.simpen_woi.capture.queue.CaptureExecutor
import com.drena.simpen_woi.capture.queue.CaptureQueue
import com.drena.simpen_woi.capture.queue.CaptureQueueSchema
import com.drena.simpen_woi.capture.queue.CaptureTransferStore
import com.drena.simpen_woi.capture.queue.toPendingCapture
import com.drena.simpen_woi.capture.queue.toMap
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Transfer inference happens in Dart; this handler only persists validated calls. */
class AiTransferChannelHandler(private val context: Context) {
    private val main = Handler(Looper.getMainLooper())

    fun handle(call: MethodCall, result: MethodChannel.Result): Boolean {
        if (call.method !in setOf("getRecentAiCaptures", "confirmAiTransfer", "resolveAiCapture")) return false
        CaptureExecutor.execute {
            try {
                val queue = CaptureQueue.getInstance(context)
                val value: Any? = when (call.method) {
                    "getRecentAiCaptures" -> recentCaptures(queue)
                    "resolveAiCapture" -> {
                        val id = call.argument<Number>("id")?.toLong() ?: 0L
                        val amount = call.argument<Number>("amount")?.toLong() ?: 0L
                        val direction = call.argument<String>("direction")
                        require(id > 0 && amount > 0 && direction in listOf("IN", "OUT"))
                        queue.resolveAi(id, amount, direction!!,
                            call.argument<String>("merchant"),
                            call.argument<Number>("category_id")?.toInt(),
                            call.argument<String>("note"))
                        null
                    }
                    else -> CaptureTransferStore(queue).pairConfirmed(
                        context,
                        call.argument<Number>("primary_id")?.toLong() ?: 0L,
                        call.argument<Number>("secondary_id")?.toLong() ?: 0L,
                        call.argument<Number>("amount")?.toLong() ?: 0L,
                        call.argument<Number>("from_wallet_id")?.toLong() ?: 0L,
                        call.argument<Number>("to_wallet_id")?.toLong() ?: 0L,
                        call.argument<String>("primary_direction") ?: "",
                        call.argument<String>("secondary_direction") ?: "",
                    )
                }
                main.post { result.success(value) }
            } catch (_: Exception) {
                main.post { result.error("capture_transfer_error", "Could not persist local AI transfer", null) }
            }
        }
        return true
    }

    private fun recentCaptures(queue: CaptureQueue): List<Map<String, Any?>> {
        val captures = mutableListOf<Map<String, Any?>>()
        val since = System.currentTimeMillis() - 10 * 60 * 1000L
        queue.database.readableDatabase.query(
            CaptureQueueSchema.TABLE,
            CaptureQueueSchema.COLUMNS,
            "posted_at >= ? AND merged = 0 AND is_transfer = 0 " +
                "AND (amount > 0 OR status = ?)",
            arrayOf(since.toString(), CaptureQueueSchema.STATUS_PENDING),
            null,
            null,
            "posted_at DESC, id DESC",
            "20",
        ).use { cursor ->
            while (cursor.moveToNext()) captures.add(cursor.toPendingCapture().toMap())
        }
        return captures
    }
}
