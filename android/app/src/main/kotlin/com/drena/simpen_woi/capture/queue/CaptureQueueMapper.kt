package com.drena.simpen_woi.capture.queue

import android.database.Cursor

internal fun Cursor.toPendingCapture(): PendingCapture = PendingCapture(
    id = getLong(0),
    amount = getLong(1),
    merchant = if (isNull(2)) null else getString(2),
    sourcePackage = getString(3),
    postedAt = getLong(4),
    categoryId = if (isNull(5)) null else getInt(5),
    note = if (isNull(6)) null else getString(6),
)

internal fun Cursor.toDirtyCapture(): DirtyCapture = DirtyCapture(
    id = getLong(0),
    categoryId = if (isNull(1)) null else getInt(1),
    note = if (isNull(2)) null else getString(2),
)
