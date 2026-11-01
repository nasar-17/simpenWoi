package com.drena.simpen_woi.capture

import android.content.Context
import com.drena.simpen_woi.bridge.CaptureEngineHost
import com.drena.simpen_woi.bridge.CaptureEventChannel
import com.drena.simpen_woi.capture.notify.CaptureNotifier
import com.drena.simpen_woi.capture.queue.CaptureQueue

object CaptureSimulator {
    const val SIMULATOR_PACKAGE = "com.drena.simpen_woi.simulator"

    /** Exercise the same raw-text -> local AI pipeline as actual notifications. */
    fun simulate(context: Context, amount: Long, merchant: String) {
        if (amount <= 0L) return
        val trimmedMerchant = merchant.trim().ifBlank { "Warung Bu Tini" }
        val queue = CaptureQueue.getInstance(context)
        val captureId = queue.insertCapture(
            0,
            null,
            SIMULATOR_PACKAGE,
            System.currentTimeMillis(),
            "raw",
            null,
        )
        if (captureId <= 0L) return
        queue.updateNote(
            captureId,
            "Pembayaran berhasil. Anda membayar Rp$amount di $trimmedMerchant.",
        )
        CaptureNotifier(context).showAiPending(captureId)
        CaptureEngineHost.ensureRunning(context)
        CaptureEventChannel.emitQueueChanged()
    }
}
