package com.drena.simpen_woi

import android.content.Context

object CaptureSimulator {
    private const val SIMULATOR_PACKAGE = "com.drena.simpen_woi.simulator"

    fun simulate(context: Context, amount: Long, merchant: String) {
        if (amount <= 0L) return
        val trimmedMerchant = merchant.trim().ifBlank { "Warung Bu Tini" }
        val queue = CaptureQueue(context)
        val postedAt = System.currentTimeMillis()
        val rule = CapturePreferences.getMerchantRule(context, trimmedMerchant)
        val captureId = queue.insertCapture(
            amount,
            trimmedMerchant,
            SIMULATOR_PACKAGE,
            postedAt,
            rule?.categoryId,
        )
        if (captureId <= 0L) return

        val capture = PendingCapture(
            captureId,
            amount,
            trimmedMerchant,
            SIMULATOR_PACKAGE,
            postedAt,
            rule?.categoryId,
            null,
        )
        val notifier = CaptureNotifier(context)
        if (rule != null) {
            notifier.showSaved(capture, rule.categoryName)
        } else {
            notifier.showQuestion(capture)
        }
        notifier.showSummary(queue.countUnanswered())
    }
}
