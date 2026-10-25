package com.drena.simpen_woi.capture.queue

import android.content.Context
import com.drena.simpen_woi.capture.notify.CaptureNotifier
import com.drena.simpen_woi.capture.parser.CaptureDirection

class CaptureTransferStore(private val queue: CaptureQueue) {
    fun tryPair(context: Context, capture: PendingCapture): Boolean {
        if (capture.isTransfer || capture.merged) return false
        val candidate = findCandidate(capture) ?: return false
        val pairId = candidate.id
        val sourcePackage = if (capture.direction == CaptureDirection.OUT.label) {
            capture.sourcePackage
        } else {
            candidate.sourcePackage
        }
        val destinationPackage = if (capture.direction == CaptureDirection.OUT.label) {
            candidate.sourcePackage
        } else {
            capture.sourcePackage
        }
        val candidateImported = isImported(candidate.id)
        val primary = if (candidateImported) capture else candidate
        val secondary = if (primary.id == capture.id) candidate else capture
        markMerged(secondary.id, pairId)
        markPrimary(primary.id, pairId, sourcePackage, destinationPackage)
        val notifier = CaptureNotifier(context)
        notifier.cancel(capture.id)
        notifier.cancel(candidate.id)
        queue.getById(primary.id)?.let(notifier::showTransferSaved)
        return true
    }

    fun unpair(context: Context, capture: PendingCapture) {
        val pairId = capture.pairId ?: capture.id
        queue.database.writableDatabase.update(
            CaptureQueueSchema.TABLE,
            android.content.ContentValues().apply {
                put("merged", 0)
                put("is_transfer", 0)
                putNull("pair_id")
                putNull("transfer_source_package")
                putNull("transfer_destination_package")
            },
            "id = ? OR pair_id = ?",
            arrayOf(pairId.toString(), pairId.toString()),
        )
        val notifier = CaptureNotifier(context)
        notifier.cancel(capture.id)
        notifier.cancel(pairId)
        listOf(capture.id, pairId).distinct().forEach { id ->
            if (!isImported(id)) {
                queue.getById(id)?.let(notifier::showQuestion)
            }
        }
    }

    private fun findCandidate(capture: PendingCapture): PendingCapture? {
        val direction = if (capture.direction == CaptureDirection.OUT.label) {
            CaptureDirection.IN.label
        } else {
            CaptureDirection.OUT.label
        }
        val window = 10 * 60 * 1000L
        return queue.database.readableDatabase.query(
            CaptureQueueSchema.TABLE,
            CaptureQueueSchema.COLUMNS,
            "amount = ? AND direction = ? AND source_package != ? " +
                "AND posted_at BETWEEN ? AND ? AND merged = 0 " +
                "AND pair_id IS NULL AND is_transfer = 0 " +
                "AND (status = ? OR category_id IS NULL)",
            arrayOf(
                capture.amount.toString(),
                direction,
                capture.sourcePackage,
                (capture.postedAt - window).toString(),
                (capture.postedAt + window).toString(),
                CaptureQueueSchema.STATUS_IMPORTED,
            ),
            null,
            null,
            "posted_at ASC, id ASC",
            "1",
        ).use { cursor ->
            if (cursor.moveToFirst()) cursor.toPendingCapture() else null
        }
    }

    private fun markMerged(id: Long, pairId: Long) {
        val values = android.content.ContentValues().apply {
            put("merged", 1)
            put("is_transfer", 1)
            put("pair_id", pairId)
        }
        queue.database.writableDatabase.update(
            CaptureQueueSchema.TABLE,
            values,
            "id = ?",
            arrayOf(id.toString()),
        )
    }

    private fun markPrimary(
        id: Long,
        pairId: Long,
        sourcePackage: String,
        destinationPackage: String,
    ) {
        val values = android.content.ContentValues().apply {
            put("is_transfer", 1)
            put("pair_id", pairId)
            put("transfer_source_package", sourcePackage)
            put("transfer_destination_package", destinationPackage)
        }
        queue.database.writableDatabase.update(
            CaptureQueueSchema.TABLE,
            values,
            "id = ?",
            arrayOf(id.toString()),
        )
    }

    fun syncAnswer(id: Long, categoryId: Int?, note: String?) {
        val values = android.content.ContentValues().apply {
            if (categoryId != null) put("category_id", categoryId) else putNull("category_id")
            if (note != null) put("note", note) else putNull("note")
            put("dirty", 0)
        }
        queue.database.writableDatabase.update(
            CaptureQueueSchema.TABLE,
            values,
            "id = ?",
            arrayOf(id.toString()),
        )
    }

    fun isImported(id: Long): Boolean {
        return queue.database.readableDatabase.query(
            CaptureQueueSchema.TABLE,
            arrayOf("status"),
            "id = ?",
            arrayOf(id.toString()),
            null,
            null,
            null,
            "1",
        ).use { cursor ->
            cursor.moveToFirst() && cursor.getString(0) == CaptureQueueSchema.STATUS_IMPORTED
        }
    }
}
