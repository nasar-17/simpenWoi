package com.drena.simpen_woi.capture.notify

import android.app.Notification
import android.content.Context
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.RemoteInput
import com.drena.simpen_woi.capture.parser.CaptureDirection
import com.drena.simpen_woi.capture.prefs.CapturePreferences
import com.drena.simpen_woi.capture.queue.PendingCapture

class CaptureNotifier(private val context: Context) {
    fun showAiPending(captureId: Long) {
        val builder = baseBuilder()
            .setContentTitle("simpenWoi sedang menunggu AI lokal")
            .setContentText("Notifikasi tersimpan. AI lokal memproses saat model siap.")
            .setSilent(true)
            .setContentIntent(CaptureNotificationIntents.openApp(context, captureId))
            .setAutoCancel(false)
            .setGroup(CaptureNotificationContract.GROUP_KEY)
        notifySafely(CaptureNotificationIntents.notificationId(captureId), builder.build())
    }

    fun showQuestion(capture: PendingCapture) {
        val incoming = capture.direction == CaptureDirection.IN.label
        val builder = baseBuilder()
            .setWhen(capture.postedAt)
            .setContentTitle(
                if (incoming) {
                    CaptureNotificationText.incomingTitle(capture)
                } else {
                    CaptureNotificationText.title(capture)
                },
            )
            .setContentText(
                if (incoming) {
                    CaptureNotificationText.INCOMING_QUESTION
                } else {
                    CaptureNotificationText.QUESTION_TEXT
                },
            )
            .setStyle(
                NotificationCompat.BigTextStyle().bigText(
                    if (incoming) {
                        CaptureNotificationText.INCOMING_BIG_TEXT
                    } else {
                        CaptureNotificationText.QUESTION_BIG_TEXT
                    },
                ),
            )
            .setContentIntent(CaptureNotificationIntents.openApp(context, capture.id))
            .setAutoCancel(false)
            .setTimeoutAfter(CaptureNotificationContract.QUESTION_TIMEOUT_MS)
            .setGroup(CaptureNotificationContract.GROUP_KEY)

        val categories = if (incoming) {
            CapturePreferences.getTopIncomeCategories(context)
        } else {
            CapturePreferences.getTopCategories(context)
        }
        categories.take(2).forEach { category ->
            builder.addAction(
                NotificationCompat.Action.Builder(
                    0,
                    category.name,
                    CaptureNotificationIntents.category(context, capture.id, category),
                ).build(),
            )
        }

        builder.addAction(
            NotificationCompat.Action.Builder(
                android.R.drawable.ic_menu_send,
                CaptureNotificationText.REPLY_ACTION,
                CaptureNotificationIntents.reply(context, capture.id),
            ).addRemoteInput(
                RemoteInput.Builder(CaptureNotificationContract.KEY_TEXT_REPLY)
                    .setLabel(CaptureNotificationText.REPLY_LABEL)
                    .build(),
            ).build(),
        )

        notifySafely(
            CaptureNotificationIntents.notificationId(capture.id),
            builder.build(),
        )
    }

    fun showSaved(capture: PendingCapture, categoryName: String) {
        val incoming = capture.direction == CaptureDirection.IN.label
        val builder = baseBuilder()
            .setWhen(capture.postedAt)
            .setContentTitle(
                if (incoming) {
                    CaptureNotificationText.incomingSavedTitle(capture, categoryName)
                } else {
                    CaptureNotificationText.savedTitle(capture, categoryName)
                },
            )
            .setContentText(CaptureNotificationText.SAVED_BODY)
            .setContentIntent(CaptureNotificationIntents.openApp(context, capture.id))
            .setAutoCancel(true)
            .setTimeoutAfter(CaptureNotificationContract.QUESTION_TIMEOUT_MS)
            .setGroup(CaptureNotificationContract.GROUP_KEY)
            .addAction(
                NotificationCompat.Action.Builder(
                    android.R.drawable.ic_menu_edit,
                    CaptureNotificationText.EDIT_ACTION,
                    CaptureNotificationIntents.undo(context, capture.id),
                ).build(),
            )
        notifySafely(
            CaptureNotificationIntents.notificationId(capture.id),
            builder.build(),
        )
    }

    fun showTransferSaved(capture: PendingCapture) {
        val builder = baseBuilder()
            .setWhen(capture.postedAt)
            .setContentTitle(CaptureNotificationText.transferSavedTitle(capture))
            .setContentText(CaptureNotificationText.SAVED_BODY)
            .setContentIntent(CaptureNotificationIntents.openApp(context, capture.id))
            .setAutoCancel(true)
            .setTimeoutAfter(CaptureNotificationContract.QUESTION_TIMEOUT_MS)
            .setGroup(CaptureNotificationContract.GROUP_KEY)
            .addAction(
                NotificationCompat.Action.Builder(
                    android.R.drawable.ic_menu_close_clear_cancel,
                    CaptureNotificationText.UNPAIR_ACTION,
                    CaptureNotificationIntents.unpair(context, capture.id),
                ).build(),
            )
        notifySafely(
            CaptureNotificationIntents.notificationId(capture.id),
            builder.build(),
        )
    }

    fun showSummary(count: Int) {
        val manager = NotificationManagerCompat.from(context)
        if (count <= 1) {
            manager.cancel(CaptureNotificationContract.SUMMARY_ID)
            return
        }
        val builder = baseBuilder()
            .setContentTitle(CaptureNotificationText.summaryTitle(count))
            .setContentText(CaptureNotificationText.SUMMARY_BODY)
            .setContentIntent(CaptureNotificationIntents.openApp(context, 0L))
            .setAutoCancel(true)
            .setTimeoutAfter(CaptureNotificationContract.QUESTION_TIMEOUT_MS)
            .setGroup(CaptureNotificationContract.GROUP_KEY)
            .setGroupSummary(true)
            .setSilent(true)
        notifySafely(CaptureNotificationContract.SUMMARY_ID, builder.build())
    }

    fun cancel(captureId: Long) {
        NotificationManagerCompat.from(context)
            .cancel(CaptureNotificationIntents.notificationId(captureId))
    }

    private fun baseBuilder(): NotificationCompat.Builder =
        CaptureNotificationChannel.builder(context)

    private fun notifySafely(id: Int, notification: Notification) {
        try {
            NotificationManagerCompat.from(context).notify(id, notification)
        } catch (_: SecurityException) {
        }
    }
}

