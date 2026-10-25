package com.drena.simpen_woi.capture

import android.content.Context
import com.drena.simpen_woi.capture.notify.CaptureNotifier
import com.drena.simpen_woi.capture.parser.CaptureDirection
import com.drena.simpen_woi.capture.prefs.CapturePreferences
import com.drena.simpen_woi.capture.queue.CaptureQueue
import com.drena.simpen_woi.capture.queue.PendingCapture

object CaptureSimulator {
    const val SIMULATOR_PACKAGE = "com.drena.simpen_woi.simulator"

    fun simulate(context: Context, amount: Long, merchant: String) {
        if (amount <= 0L) return
        val trimmedMerchant = merchant.trim().ifBlank { "Warung Bu Tini" }
        val queue = CaptureQueue.getInstance(context)
        val postedAt = System.currentTimeMillis()
        val rule = CapturePreferences.getMerchantRule(context, trimmedMerchant)
        val captureId = queue.insertCapture(
            amount,
            trimmedMerchant,
            SIMULATOR_PACKAGE,
            postedAt,
            CaptureDirection.OUT.label,
            rule?.categoryId,
        )
        if (captureId <= 0L) return

        val capture = PendingCapture(
            captureId,
            amount,
            trimmedMerchant,
            SIMULATOR_PACKAGE,
            postedAt,
            CaptureDirection.OUT.label,
            rule?.categoryId,
            null,
        )
        val notifier = CaptureNotifier(context)
        if (rule != null) {
            notifier.showSaved(capture, rule.categoryName)
        } else {
            notifier.showQuestion(capture)
        }
    }
}
