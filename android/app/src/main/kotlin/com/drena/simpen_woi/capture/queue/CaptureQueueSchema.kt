package com.drena.simpen_woi.capture.queue

internal object CaptureQueueSchema {
    const val DATABASE_NAME = "capture_queue.db"
    const val DATABASE_VERSION = 3
    const val TABLE = "pending_captures"
    const val STATUS_PENDING = "pending"
    const val STATUS_IMPORTED = "imported"

    val COLUMNS = arrayOf(
        "id",
        "amount",
        "merchant",
        "source_package",
        "posted_at",
        "direction",
        "category_id",
        "note",
    )

    val DIRTY_COLUMNS = arrayOf("id", "category_id", "note")
}
