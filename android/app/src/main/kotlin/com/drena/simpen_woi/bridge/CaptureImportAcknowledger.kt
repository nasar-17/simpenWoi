package com.drena.simpen_woi.bridge

import android.content.Context
import com.drena.simpen_woi.capture.notify.CaptureNotifier
import com.drena.simpen_woi.capture.prefs.CapturePreferences
import com.drena.simpen_woi.capture.queue.CaptureQueue

/** Announce a saved transaction only after the Flutter database commit. */
object CaptureImportAcknowledger {
    fun acknowledge(context: Context, ids: List<Long>) {
        val queue = CaptureQueue.getInstance(context)
        queue.markImported(ids)
        val notifier = CaptureNotifier(context)
        val categories = CapturePreferences.getCategories(context) +
            CapturePreferences.getIncomeCategories(context)
        ids.forEach { id ->
            val capture = queue.getById(id)
            notifier.cancel(id)
            if (capture != null && capture.amount > 0) {
                val category = categories.firstOrNull { it.id == capture.categoryId }
                if (capture.isTransfer) notifier.showTransferSaved(capture)
                else if (category != null) notifier.showSaved(capture, category.name)
                else notifier.showQuestion(capture)
            }
        }
        notifier.showSummary(queue.countUnanswered())
    }
}
