package com.drena.simpen_woi.capture.notify

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.RemoteInput
import com.drena.simpen_woi.capture.queue.CaptureExecutor
import com.drena.simpen_woi.capture.queue.CaptureQueue
import com.drena.simpen_woi.capture.queue.PendingCapture

class CaptureActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val pendingResult = goAsync()
        CaptureExecutor.execute {
            try {
                handle(context, intent)
            } catch (_: Exception) {
            } finally {
                pendingResult.finish()
            }
        }
    }

    private fun handle(context: Context, intent: Intent) {
        val captureId = intent.getLongExtra(
            CaptureNotificationContract.EXTRA_CAPTURE_ID,
            -1L,
        )
        if (captureId <= 0L) return
        val queue = CaptureQueue.getInstance(context)
        val capture = queue.getById(captureId) ?: return

        when (intent.action) {
            CaptureNotificationContract.ACTION_CATEGORY -> {
                handleCategory(context, queue, capture, intent)
            }

            CaptureNotificationContract.ACTION_REPLY -> {
                handleReply(context, queue, capture, intent)
            }

            CaptureNotificationContract.ACTION_UNDO -> {
                handleUndo(context, queue, capture)
            }
        }
    }

    private fun handleCategory(
        context: Context,
        queue: CaptureQueue,
        capture: PendingCapture,
        intent: Intent,
    ) {
        val categoryId = intent.getIntExtra(
            CaptureNotificationContract.EXTRA_CATEGORY_ID,
            -1,
        )
        if (categoryId <= 0) return
        val categoryName = intent.getStringExtra(
            CaptureNotificationContract.EXTRA_CATEGORY_NAME,
        ) ?: CaptureNotificationText.DEFAULT_CATEGORY
        queue.updateCategory(capture.id, categoryId)
        queue.markDirtyIfImported(capture.id)
        CaptureNotifier(context).showSaved(capture.copy(categoryId = categoryId), categoryName)
    }

    private fun handleReply(
        context: Context,
        queue: CaptureQueue,
        capture: PendingCapture,
        intent: Intent,
    ) {
        val reply = RemoteInput.getResultsFromIntent(intent)
            ?.getCharSequence(CaptureNotificationContract.KEY_TEXT_REPLY)
            ?.toString()
            ?.trim()
        if (reply.isNullOrEmpty()) return
        queue.updateNote(capture.id, reply)
        queue.markDirtyIfImported(capture.id)
        CaptureNotifier(context).showSaved(
            capture.copy(note = reply),
            CaptureNotificationText.noteLabel(reply),
        )
    }

    private fun handleUndo(
        context: Context,
        queue: CaptureQueue,
        capture: PendingCapture,
    ) {
        queue.clearAnswer(capture.id)
        CaptureNotifier(context).showQuestion(capture.copy(categoryId = null, note = null))
    }
}
