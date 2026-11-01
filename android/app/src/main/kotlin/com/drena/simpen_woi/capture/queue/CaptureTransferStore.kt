package com.drena.simpen_woi.capture.queue

import android.content.Context
import com.drena.simpen_woi.capture.notify.CaptureNotifier

class CaptureTransferStore(private val queue: CaptureQueue) {
    /** Persist only an explicitly validated model transfer, without a matching heuristic. */
    fun pairConfirmed(
        context: Context,
        primaryId: Long,
        secondaryId: Long,
        amount: Long,
        fromWalletId: Long,
        toWalletId: Long,
        primaryDirection: String,
        secondaryDirection: String,
    ): Boolean {
        require(primaryId > 0 && secondaryId > 0 && primaryId != secondaryId)
        require(amount > 0 && fromWalletId > 0 && toWalletId > 0 && fromWalletId != toWalletId)
        require(setOf(primaryDirection, secondaryDirection) == setOf("IN", "OUT"))
        val database = queue.database.writableDatabase
        database.beginTransaction()
        try {
            val primary = queue.getById(primaryId) ?: return false
            val secondary = queue.getById(secondaryId) ?: return false
            if (primary.direction != "raw" || isImported(primaryId) ||
                (secondary.direction == "raw" && isImported(secondaryId)) ||
                primary.isTransfer || primary.merged ||
                secondary.isTransfer || secondary.merged ||
                primary.sourcePackage == secondary.sourcePackage ||
                kotlin.math.abs(primary.postedAt - secondary.postedAt) > 10 * 60 * 1000L
            ) return false
            if (secondary.direction != "raw" &&
                (secondary.amount != amount || secondary.direction != secondaryDirection)
            ) return false
            val secondaryValues = android.content.ContentValues().apply {
                put("amount", amount)
                put("direction", secondaryDirection)
                put("merged", 1)
                put("is_transfer", 1)
                put("pair_id", secondaryId)
            }
            database.update(CaptureQueueSchema.TABLE, secondaryValues,
                "id = ?", arrayOf(secondaryId.toString()))
            val primaryValues = android.content.ContentValues().apply {
                put("amount", amount)
                put("direction", primaryDirection)
                put("is_transfer", 1)
                put("pair_id", secondaryId)
                put("transfer_source_package", "wallet:$fromWalletId")
                put("transfer_destination_package", "wallet:$toWalletId")
                putNull("category_id")
            }
            database.update(CaptureQueueSchema.TABLE, primaryValues,
                "id = ?", arrayOf(primaryId.toString()))
            database.setTransactionSuccessful()
        } finally {
            database.endTransaction()
        }
        val notifier = CaptureNotifier(context)
        notifier.cancel(secondaryId)
        // The saved notification is shown only after the Drift import commits.
        return true
    }

    /** Restore both original captures, including already-imported pairs. */
    fun unpair(context: Context, capture: PendingCapture) {
        val pairId = capture.pairId ?: return
        val database = queue.database.writableDatabase
        val ids = mutableListOf<Long>()
        database.beginTransaction()
        try {
            database.query(
                CaptureQueueSchema.TABLE,
                arrayOf("id"),
                "id = ? OR pair_id = ?",
                arrayOf(pairId.toString(), pairId.toString()),
                null,
                null,
                null,
            ).use { cursor ->
                while (cursor.moveToNext()) ids.add(cursor.getLong(0))
            }
            database.update(
                CaptureQueueSchema.TABLE,
                android.content.ContentValues().apply {
                    put("merged", 0)
                    put("is_transfer", 0)
                    put("status", CaptureQueueSchema.STATUS_PENDING)
                    put("dirty", 0)
                    putNull("pair_id")
                    putNull("transfer_source_package")
                    putNull("transfer_destination_package")
                },
                "id = ? OR pair_id = ?",
                arrayOf(pairId.toString(), pairId.toString()),
            )
            database.setTransactionSuccessful()
        } finally {
            database.endTransaction()
        }
        val notifier = CaptureNotifier(context)
        ids.forEach { id ->
            notifier.cancel(id)
            queue.getById(id)?.let(notifier::showQuestion)
        }
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

