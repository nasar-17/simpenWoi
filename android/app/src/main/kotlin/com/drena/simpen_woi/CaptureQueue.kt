package com.drena.simpen_woi

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

class CaptureQueue(context: Context) : SQLiteOpenHelper(
    context.applicationContext,
    DATABASE_NAME,
    null,
    DATABASE_VERSION,
) {
    companion object {
        private const val DATABASE_NAME = "capture_queue.db"
        private const val DATABASE_VERSION = 2
        private const val TABLE = "pending_captures"
        const val STATUS_PENDING = "pending"
        const val STATUS_IMPORTED = "imported"
        private val COLUMNS = arrayOf(
            "id",
            "amount",
            "merchant",
            "source_package",
            "posted_at",
            "category_id",
            "note",
        )
    }

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            """
            CREATE TABLE $TABLE (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                amount INTEGER NOT NULL,
                merchant TEXT,
                source_package TEXT NOT NULL,
                posted_at INTEGER NOT NULL,
                category_id INTEGER,
                note TEXT,
                status TEXT NOT NULL DEFAULT '$STATUS_PENDING',
                dirty INTEGER NOT NULL DEFAULT 0
            )
            """.trimIndent(),
        )
        db.execSQL("CREATE INDEX idx_pending_status ON $TABLE (status)")
        db.execSQL("CREATE INDEX idx_pending_posted_at ON $TABLE (posted_at)")
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        if (oldVersion < 2) {
            db.execSQL("ALTER TABLE $TABLE ADD COLUMN dirty INTEGER NOT NULL DEFAULT 0")
        }
    }

    fun insertCapture(
        amount: Long,
        merchant: String?,
        sourcePackage: String,
        postedAt: Long,
        categoryId: Int?,
    ): Long {
        val values = ContentValues().apply {
            put("amount", amount)
            put("merchant", merchant)
            put("source_package", sourcePackage)
            put("posted_at", postedAt)
            if (categoryId != null) put("category_id", categoryId) else putNull("category_id")
            put("status", STATUS_PENDING)
        }
        return writableDatabase.insert(TABLE, null, values)
    }

    fun getPending(): List<PendingCapture> {
        val captures = mutableListOf<PendingCapture>()
        readableDatabase.query(
            TABLE,
            COLUMNS,
            "status = ?",
            arrayOf(STATUS_PENDING),
            null,
            null,
            "posted_at ASC",
        ).use { cursor ->
            while (cursor.moveToNext()) {
                captures.add(
                    PendingCapture(
                        id = cursor.getLong(0),
                        amount = cursor.getLong(1),
                        merchant = if (cursor.isNull(2)) null else cursor.getString(2),
                        sourcePackage = cursor.getString(3),
                        postedAt = cursor.getLong(4),
                        categoryId = if (cursor.isNull(5)) null else cursor.getInt(5),
                        note = if (cursor.isNull(6)) null else cursor.getString(6),
                    ),
                )
            }
        }
        return captures
    }

    fun getById(id: Long): PendingCapture? {
        readableDatabase.query(
            TABLE,
            COLUMNS,
            "id = ?",
            arrayOf(id.toString()),
            null,
            null,
            null,
            "1",
        ).use { cursor ->
            if (!cursor.moveToFirst()) return null
            return PendingCapture(
                id = cursor.getLong(0),
                amount = cursor.getLong(1),
                merchant = if (cursor.isNull(2)) null else cursor.getString(2),
                sourcePackage = cursor.getString(3),
                postedAt = cursor.getLong(4),
                categoryId = if (cursor.isNull(5)) null else cursor.getInt(5),
                note = if (cursor.isNull(6)) null else cursor.getString(6),
            )
        }
    }

    fun markImported(ids: List<Long>) {
        if (ids.isEmpty()) return
        val placeholders = ids.joinToString(",") { "?" }
        val values = ContentValues().apply { put("status", STATUS_IMPORTED) }
        writableDatabase.update(
            TABLE,
            values,
            "id IN ($placeholders)",
            ids.map { it.toString() }.toTypedArray(),
        )
    }

    fun updateCategory(id: Long, categoryId: Int) {
        val values = ContentValues().apply { put("category_id", categoryId) }
        writableDatabase.update(TABLE, values, "id = ?", arrayOf(id.toString()))
    }

    fun updateNote(id: Long, note: String) {
        val values = ContentValues().apply { put("note", note) }
        writableDatabase.update(TABLE, values, "id = ?", arrayOf(id.toString()))
    }

    fun markDirtyIfImported(id: Long) {
        val values = ContentValues().apply { put("dirty", 1) }
        writableDatabase.update(
            TABLE,
            values,
            "id = ? AND status = ?",
            arrayOf(id.toString(), STATUS_IMPORTED),
        )
    }

    fun getDirtyCaptures(): List<DirtyCapture> {
        val captures = mutableListOf<DirtyCapture>()
        readableDatabase.query(
            TABLE,
            arrayOf("id", "category_id", "note"),
            "dirty = 1",
            null,
            null,
            null,
            "posted_at ASC",
        ).use { cursor ->
            while (cursor.moveToNext()) {
                captures.add(
                    DirtyCapture(
                        id = cursor.getLong(0),
                        categoryId = if (cursor.isNull(1)) null else cursor.getInt(1),
                        note = if (cursor.isNull(2)) null else cursor.getString(2),
                    ),
                )
            }
        }
        return captures
    }

    fun markSynced(ids: List<Long>) {
        if (ids.isEmpty()) return
        val placeholders = ids.joinToString(",") { "?" }
        val values = ContentValues().apply { put("dirty", 0) }
        writableDatabase.update(
            TABLE,
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
        writableDatabase.update(TABLE, values, "id = ?", arrayOf(id.toString()))
    }

    fun hasRecentAmount(amount: Long, sourcePackage: String, windowMillis: Long): Boolean {
        val since = System.currentTimeMillis() - windowMillis
        readableDatabase.query(
            TABLE,
            arrayOf("id"),
            "amount = ? AND source_package != ? AND posted_at >= ?",
            arrayOf(amount.toString(), sourcePackage, since.toString()),
            null,
            null,
            null,
            "1",
        ).use { cursor ->
            return cursor.moveToFirst()
        }
    }

    fun countUnanswered(): Int {
        readableDatabase.rawQuery(
            "SELECT COUNT(*) FROM $TABLE WHERE status = ? AND category_id IS NULL",
            arrayOf(STATUS_PENDING),
        ).use { cursor ->
            return if (cursor.moveToFirst()) cursor.getInt(0) else 0
        }
    }
}
