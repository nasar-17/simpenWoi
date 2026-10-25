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
                direction TEXT NOT NULL DEFAULT 'OUT',
                category_id INTEGER,
                note TEXT,
                status TEXT NOT NULL DEFAULT '${CaptureQueueSchema.STATUS_PENDING}',
                dirty INTEGER NOT NULL DEFAULT 0,
                is_transfer INTEGER NOT NULL DEFAULT 0,
                pair_id INTEGER,
                merged INTEGER NOT NULL DEFAULT 0,
                transfer_source_package TEXT,
                transfer_destination_package TEXT
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
        if (oldVersion < 3) {
            db.execSQL(
                "ALTER TABLE ${CaptureQueueSchema.TABLE} ADD COLUMN " +
                    "direction TEXT NOT NULL DEFAULT 'OUT'",
            )
        }
        if (oldVersion < 4) {
            db.execSQL(
                "ALTER TABLE ${CaptureQueueSchema.TABLE} ADD COLUMN " +
                    "is_transfer INTEGER NOT NULL DEFAULT 0",
            )
            db.execSQL(
                "ALTER TABLE ${CaptureQueueSchema.TABLE} ADD COLUMN pair_id INTEGER",
            )
            db.execSQL(
                "ALTER TABLE ${CaptureQueueSchema.TABLE} ADD COLUMN " +
                    "merged INTEGER NOT NULL DEFAULT 0",
            )
            db.execSQL(
                "ALTER TABLE ${CaptureQueueSchema.TABLE} ADD COLUMN " +
                    "transfer_source_package TEXT",
            )
            db.execSQL(
                "ALTER TABLE ${CaptureQueueSchema.TABLE} ADD COLUMN " +
                    "transfer_destination_package TEXT",
            )
        }
    }
}
