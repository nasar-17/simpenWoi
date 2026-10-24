package com.drena.simpen_woi

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.RemoteInput

class CaptureActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val captureId = intent.getLongExtra(CaptureNotifier.EXTRA_CAPTURE_ID, -1L)
        if (captureId <= 0L) return
        val queue = CaptureQueue(context)
        val capture = queue.getById(captureId) ?: return

        when (intent.action) {
            CaptureNotifier.ACTION_CATEGORY -> handleCategory(context, queue, capture, intent)
            CaptureNotifier.ACTION_REPLY -> handleReply(context, queue, capture, intent)
            CaptureNotifier.ACTION_UNDO -> handleUndo(context, queue, capture)
        }
    }

    private fun handleCategory(
        context: Context,
        queue: CaptureQueue,
        capture: PendingCapture,
        intent: Intent,
    ) {
        val categoryId = intent.getIntExtra(CaptureNotifier.EXTRA_CATEGORY_ID, -1)
        if (categoryId <= 0) return
        val categoryName = intent.getStringExtra(CaptureNotifier.EXTRA_CATEGORY_NAME)
            ?: "Kategori"
        queue.updateCategory(capture.id, categoryId)
        queue.markDirtyIfImported(capture.id)
        CaptureNotifier(context).showSaved(capture.copy(categoryId = categoryId), categoryName)
        CaptureNotifier(context).showSummary(queue.countUnanswered())
    }

    private fun handleReply(
        context: Context,
        queue: CaptureQueue,
        capture: PendingCapture,
        intent: Intent,
    ) {
        val reply = RemoteInput.getResultsFromIntent(intent)
            ?.getCharSequence(CaptureNotifier.KEY_TEXT_REPLY)
            ?.toString()
            ?.trim()
        if (reply.isNullOrEmpty()) return
        queue.updateNote(capture.id, reply)
        queue.markDirtyIfImported(capture.id)
        CaptureNotifier(context).showSaved(capture.copy(note = reply), "Catatan: $reply")
        CaptureNotifier(context).showSummary(queue.countUnanswered())
    }

    private fun handleUndo(
        context: Context,
        queue: CaptureQueue,
        capture: PendingCapture,
    ) {
        queue.clearAnswer(capture.id)
        CaptureNotifier(context).showQuestion(capture.copy(categoryId = null, note = null))
        CaptureNotifier(context).showSummary(queue.countUnanswered())
    }
}
