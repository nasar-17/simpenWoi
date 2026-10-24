package com.drena.simpen_woi.capture.notify

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import com.drena.simpen_woi.MainActivity
import com.drena.simpen_woi.capture.queue.CaptureCategory

internal object CaptureNotificationIntents {
    private const val NOTIFICATION_BASE = 100000
    private const val REQUEST_CATEGORY = 200000
    private const val REQUEST_REPLY = 300000
    private const val REQUEST_UNDO = 400000
    private const val REQUEST_OPEN = 500000

    fun category(
        context: Context,
        captureId: Long,
        category: CaptureCategory,
    ): PendingIntent {
        val intent = Intent(context, CaptureActionReceiver::class.java).apply {
            action = CaptureNotificationContract.ACTION_CATEGORY
            putExtra(CaptureNotificationContract.EXTRA_CAPTURE_ID, captureId)
            putExtra(CaptureNotificationContract.EXTRA_CATEGORY_ID, category.id)
            putExtra(CaptureNotificationContract.EXTRA_CATEGORY_NAME, category.name)
        }
        return PendingIntent.getBroadcast(
            context,
            REQUEST_CATEGORY + requestOffset(captureId, category.id),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    fun reply(context: Context, captureId: Long): PendingIntent {
        val intent = Intent(context, CaptureActionReceiver::class.java).apply {
            action = CaptureNotificationContract.ACTION_REPLY
            putExtra(CaptureNotificationContract.EXTRA_CAPTURE_ID, captureId)
        }
        return PendingIntent.getBroadcast(
            context,
            REQUEST_REPLY + captureId.toInt(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
        )
    }

    fun undo(context: Context, captureId: Long): PendingIntent {
        val intent = Intent(context, CaptureActionReceiver::class.java).apply {
            action = CaptureNotificationContract.ACTION_UNDO
            putExtra(CaptureNotificationContract.EXTRA_CAPTURE_ID, captureId)
        }
        return PendingIntent.getBroadcast(
            context,
            REQUEST_UNDO + captureId.toInt(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    fun openApp(context: Context, captureId: Long): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(CaptureNotificationContract.EXTRA_CAPTURE_ID, captureId)
        }
        return PendingIntent.getActivity(
            context,
            REQUEST_OPEN + captureId.toInt(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    fun notificationId(captureId: Long): Int {
        return NOTIFICATION_BASE + (captureId % 100000L).toInt()
    }

    private fun requestOffset(captureId: Long, categoryId: Int): Int {
        return (captureId.toInt() * 10) + categoryId
    }
}
