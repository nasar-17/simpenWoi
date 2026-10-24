package com.drena.simpen_woi.capture.queue

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

internal class CaptureQueueDatabase(context: Context) : SQLiteOpenHelper(
    context.applicationContext,
    CaptureQueueSchema.DATABASE_NAME,
    null,
    CaptureQueueSchema.DATABASE_VERSION,
) {
    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            """
            CREATE TABLE ${CaptureQueueSchema.TABLE} (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                amount INTEGER NOT NULL,
                merchant TEXT,
                source_package TEXT NOT NULL,
                posted_at INTEGER NOT NULL,
                category_id INTEGER,
                note TEXT,
                status TEXT NOT NULL DEFAULT '${CaptureQueueSchema.STATUS_PENDING}',
                dirty INTEGER NOT NULL DEFAULT 0
            )
            """.trimIndent(),
        )
        db.execSQL("CREATE INDEX idx_pending_status ON ${CaptureQueueSchema.TABLE} (status)")
        db.execSQL("CREATE INDEX idx_pending_posted_at ON ${CaptureQueueSchema.TABLE} (posted_at)")
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        if (oldVersion < 2) {
            db.execSQL(
                "ALTER TABLE ${CaptureQueueSchema.TABLE} ADD COLUMN dirty INTEGER NOT NULL DEFAULT 0",
            )
        }
    }
}
