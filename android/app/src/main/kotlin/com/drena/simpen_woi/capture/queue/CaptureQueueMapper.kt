package com.drena.simpen_woi.capture.queue

import android.database.Cursor

internal fun Cursor.toPendingCapture(): PendingCapture = PendingCapture(
    id = getLong(0),
    amount = getLong(1),
    merchant = if (isNull(2)) null else getString(2),
    sourcePackage = getString(3),
    postedAt = getLong(4),
    direction = getString(5),
    categoryId = if (isNull(6)) null else getInt(6),
    note = if (isNull(7)) null else getString(7),
    isTransfer = getInt(8) != 0,
    pairId = if (isNull(9)) null else getLong(9),
    merged = getInt(10) != 0,
    transferSourcePackage = if (isNull(11)) null else getString(11),
    transferDestinationPackage = if (isNull(12)) null else getString(12),
)

internal fun Cursor.toDirtyCapture(): DirtyCapture = DirtyCapture(
    id = getLong(0),
    categoryId = if (isNull(1)) null else getInt(1),
    note = if (isNull(2)) null else getString(2),
)
