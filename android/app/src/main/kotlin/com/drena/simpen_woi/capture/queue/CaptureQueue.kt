package com.drena.simpen_woi.capture.queue

import android.content.ContentValues
import android.content.Context

class CaptureQueue private constructor(context: Context) {
    internal val database = CaptureQueueDatabase(context)

    fun insertCapture(
        amount: Long,
        merchant: String?,
        sourcePackage: String,
        postedAt: Long,
        direction: String,
        categoryId: Int?,
        note: String? = null,
    ): Long {
        val values = ContentValues().apply {
            put("amount", amount)
            put("merchant", merchant)
            put("note", note)
            put("source_package", sourcePackage)
            put("posted_at", postedAt)
            put("direction", direction)
            if (categoryId != null) put("category_id", categoryId) else putNull("category_id")
            put("status", CaptureQueueSchema.STATUS_PENDING)
        }
        return database.writableDatabase.insert(CaptureQueueSchema.TABLE, null, values)
    }

    fun resolveAi(id: Long, amount: Long, direction: String, merchant: String?, categoryId: Int?, note: String?) {
        val values = ContentValues().apply {
            put("amount", amount)
            put("direction", direction)
            put("merchant", merchant)
            if (categoryId == null) putNull("category_id") else put("category_id", categoryId)
            if (note == null) putNull("note") else put("note", note)
        }
        database.writableDatabase.update(CaptureQueueSchema.TABLE, values,
            "id = ? AND direction = ?", arrayOf(id.toString(), "raw"))
    }

    fun getPending(): List<PendingCapture> {
        val captures = mutableListOf<PendingCapture>()
        database.readableDatabase.query(
            CaptureQueueSchema.TABLE,
            CaptureQueueSchema.COLUMNS,
            "status = ? AND merged = 0",
            arrayOf(CaptureQueueSchema.STATUS_PENDING),
            null,
            null,
            "posted_at ASC",
        ).use { cursor ->
            while (cursor.moveToNext()) {
                captures.add(cursor.toPendingCapture())
            }
        }
        return captures
    }

    fun getById(id: Long): PendingCapture? {
        return database.readableDatabase.query(
            CaptureQueueSchema.TABLE,
            CaptureQueueSchema.COLUMNS,
            "id = ?",
            arrayOf(id.toString()),
            null,
            null,
            null,
            "1",
        ).use { cursor ->
            if (cursor.moveToFirst()) cursor.toPendingCapture() else null
        }
    }

    fun markImported(ids: List<Long>) {
        if (ids.isEmpty()) return
        val groupIds = ids.map { getById(it)?.pairId ?: it }.distinct()
        val allIds = (ids + groupIds).distinct()
        val placeholders = allIds.joinToString(",") { "?" }
        val values = ContentValues().apply { put("status", CaptureQueueSchema.STATUS_IMPORTED) }
        val args = allIds.map { it.toString() }.toTypedArray()
        database.writableDatabase.update(
            CaptureQueueSchema.TABLE,
            values,
            "id IN ($placeholders) OR pair_id IN ($placeholders)",
            args + args,
        )
    }

    fun updateCategory(id: Long, categoryId: Int) {
        val values = ContentValues().apply { put("category_id", categoryId) }
        database.writableDatabase.update(
            CaptureQueueSchema.TABLE,
            values,
            "id = ?",
            arrayOf(id.toString()),
        )
    }

    fun updateNote(id: Long, note: String) {
        val values = ContentValues().apply { put("note", note) }
        database.writableDatabase.update(
            CaptureQueueSchema.TABLE,
            values,
            "id = ?",
            arrayOf(id.toString()),
        )
    }

    fun markDirtyIfImported(id: Long) {
        val values = ContentValues().apply { put("dirty", 1) }
        database.writableDatabase.update(
            CaptureQueueSchema.TABLE,
            values,
            "id = ? AND status = ?",
            arrayOf(id.toString(), CaptureQueueSchema.STATUS_IMPORTED),
        )
    }

    fun getDirtyCaptures(): List<DirtyCapture> {
        val captures = mutableListOf<DirtyCapture>()
        database.readableDatabase.query(
            CaptureQueueSchema.TABLE,
            CaptureQueueSchema.DIRTY_COLUMNS,
            "dirty = 1",
            null,
            null,
            null,
            "posted_at ASC",
        ).use { cursor ->
            while (cursor.moveToNext()) {
                captures.add(cursor.toDirtyCapture())
            }
        }
        return captures
    }

    fun markSynced(ids: List<Long>) {
        if (ids.isEmpty()) return
        val placeholders = ids.joinToString(",") { "?" }
        val values = ContentValues().apply { put("dirty", 0) }
        database.writableDatabase.update(
            CaptureQueueSchema.TABLE,
            values,
            "id IN ($placeholders)",
            ids.map { it.toString() }.toTypedArray(),
        )
    }

    fun clearAnswer(id: Long) {
        val values = ContentValues().apply {
            putNull("category_id")
            putNull("note")
        }
        database.writableDatabase.update(
            CaptureQueueSchema.TABLE,
            values,
            "id = ?",
            arrayOf(id.toString()),
        )
    }

    fun countUnanswered(): Int {
        return database.readableDatabase.rawQuery(
            "SELECT COUNT(*) FROM ${CaptureQueueSchema.TABLE} " +
                "WHERE status = ? AND category_id IS NULL " +
                "AND is_transfer = 0 AND merged = 0",
            arrayOf(CaptureQueueSchema.STATUS_PENDING),
        ).use { cursor ->
            if (cursor.moveToFirst()) cursor.getInt(0) else 0
        }
    }

    companion object {
        @Volatile
        private var instance: CaptureQueue? = null

        fun getInstance(context: Context): CaptureQueue {
            return instance ?: synchronized(this) {
                instance ?: CaptureQueue(context.applicationContext).also { instance = it }
            }
        }
    }
}

