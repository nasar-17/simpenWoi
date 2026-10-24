package com.drena.simpen_woi

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.RemoteInput

class CaptureNotifier(private val context: Context) {
    companion object {
        const val CHANNEL_ID = "capture"
        const val CHANNEL_NAME = "Tangkapan transaksi"
        const val GROUP_KEY = "simpenwoi_capture_group"
        const val SUMMARY_ID = 990001
        const val ACTION_CATEGORY = "com.drena.simpen_woi.action.CATEGORY"
        const val ACTION_REPLY = "com.drena.simpen_woi.action.REPLY"
        const val ACTION_UNDO = "com.drena.simpen_woi.action.UNDO"
        const val EXTRA_CAPTURE_ID = "capture_id"
        const val EXTRA_CATEGORY_ID = "category_id"
        const val EXTRA_CATEGORY_NAME = "category_name"
        const val KEY_TEXT_REPLY = "capture_text_reply"

        private const val NOTIFICATION_BASE = 100000
        private const val REQUEST_CATEGORY = 200000
        private const val REQUEST_REPLY = 300000
        private const val REQUEST_UNDO = 400000
        private const val REQUEST_OPEN = 500000
        private const val QUESTION_TIMEOUT_MS = 6 * 60 * 60 * 1000L
    }

    fun showQuestion(capture: PendingCapture) {
        ensureChannel()
        val builder = baseBuilder()
            .setWhen(capture.postedAt)
            .setContentTitle(buildTitle(capture))
            .setContentText("Untuk apa?")
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText("Untuk apa? Ketuk kategori atau ketik catatan."),
            )
            .setContentIntent(openAppIntent(capture.id))
            .setAutoCancel(false)
            .setTimeoutAfter(QUESTION_TIMEOUT_MS)
            .setGroup(GROUP_KEY)

        CapturePreferences.getTopCategories(context)
            .take(2)
            .forEach { category ->
                builder.addAction(
                    NotificationCompat.Action.Builder(
                        0,
                        category.name,
                        categoryPendingIntent(capture.id, category),
                    ).build(),
                )
            }

        builder.addAction(
            NotificationCompat.Action.Builder(
                android.R.drawable.ic_menu_send,
                "Ketik",
                replyPendingIntent(capture.id),
            ).addRemoteInput(
                RemoteInput.Builder(KEY_TEXT_REPLY)
                    .setLabel("Catatan (mis. bakso 2 porsi)")
                    .build(),
            ).build(),
        )

        notifySafely(notificationId(capture.id), builder.build())
    }

    fun showSaved(capture: PendingCapture, categoryName: String) {
        ensureChannel()
        val merchantPart = capture.merchant
            ?.takeIf { it.isNotBlank() }
            ?.let { " - $it" }
            .orEmpty()
        val label = categoryName.trim().ifBlank {
            capture.note?.trim().orEmpty()
        }
        val suffix = if (label.isNotBlank()) " - $label" else ""
        val builder = baseBuilder()
            .setWhen(capture.postedAt)
            .setContentTitle("Tersimpan: ${formatRupiah(capture.amount)}$merchantPart$suffix")
            .setContentText("Transaksi tercatat di simpenWoi.")
            .setContentIntent(openAppIntent(capture.id))
            .setAutoCancel(true)
            .setTimeoutAfter(QUESTION_TIMEOUT_MS)
            .setGroup(GROUP_KEY)
            .addAction(
                NotificationCompat.Action.Builder(
                    android.R.drawable.ic_menu_edit,
                    "Ubah",
                    undoPendingIntent(capture.id),
                ).build(),
            )
        notifySafely(notificationId(capture.id), builder.build())
    }

    fun showSummary(count: Int) {
        ensureChannel()
        val manager = NotificationManagerCompat.from(context)
        if (count <= 1) {
            manager.cancel(SUMMARY_ID)
            return
        }
        val builder = baseBuilder()
            .setContentTitle("$count transaksi belum dikategorikan")
            .setContentText("Buka simpenWoi untuk melengkapi kategori.")
            .setContentIntent(openAppIntent(0L))
            .setAutoCancel(true)
            .setTimeoutAfter(QUESTION_TIMEOUT_MS)
            .setGroup(GROUP_KEY)
            .setGroupSummary(true)
        notifySafely(SUMMARY_ID, builder.build())
    }

    fun cancel(captureId: Long) {
        NotificationManagerCompat.from(context).cancel(notificationId(captureId))
    }

    private fun baseBuilder(): NotificationCompat.Builder {
        return NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOnlyAlertOnce(true)
            .setShowWhen(true)
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Catatan transaksi otomatis dari notifikasi e-wallet"
            setSound(null, null)
            enableVibration(false)
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }

    private fun categoryPendingIntent(
        captureId: Long,
        category: CaptureCategory,
    ): PendingIntent {
        val intent = Intent(context, CaptureActionReceiver::class.java).apply {
            action = ACTION_CATEGORY
            putExtra(EXTRA_CAPTURE_ID, captureId)
            putExtra(EXTRA_CATEGORY_ID, category.id)
            putExtra(EXTRA_CATEGORY_NAME, category.name)
        }
        return PendingIntent.getBroadcast(
            context,
            REQUEST_CATEGORY + requestOffset(captureId, category.id),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun replyPendingIntent(captureId: Long): PendingIntent {
        val intent = Intent(context, CaptureActionReceiver::class.java).apply {
            action = ACTION_REPLY
            putExtra(EXTRA_CAPTURE_ID, captureId)
        }
        return PendingIntent.getBroadcast(
            context,
            REQUEST_REPLY + captureId.toInt(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
        )
    }

    private fun undoPendingIntent(captureId: Long): PendingIntent {
        val intent = Intent(context, CaptureActionReceiver::class.java).apply {
            action = ACTION_UNDO
            putExtra(EXTRA_CAPTURE_ID, captureId)
        }
        return PendingIntent.getBroadcast(
            context,
            REQUEST_UNDO + captureId.toInt(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun openAppIntent(captureId: Long): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(EXTRA_CAPTURE_ID, captureId)
        }
        return PendingIntent.getActivity(
            context,
            REQUEST_OPEN + captureId.toInt(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun requestOffset(captureId: Long, categoryId: Int): Int {
        return (captureId.toInt() * 10) + categoryId
    }

    private fun notificationId(captureId: Long): Int {
        return NOTIFICATION_BASE + (captureId % 100000L).toInt()
    }

    private fun buildTitle(capture: PendingCapture): String {
        val merchant = capture.merchant?.takeIf { it.isNotBlank() }
        return if (merchant == null) {
            formatRupiah(capture.amount)
        } else {
            "${formatRupiah(capture.amount)} di $merchant"
        }
    }

    private fun formatRupiah(amount: Long): String {
        val digits = amount.toString()
        val builder = StringBuilder()
        digits.forEachIndexed { index, character ->
            if (index > 0 && (digits.length - index) % 3 == 0) builder.append('.')
            builder.append(character)
        }
        return "Rp$builder"
    }

    private fun notifySafely(id: Int, notification: Notification) {
        try {
            NotificationManagerCompat.from(context).notify(id, notification)
        } catch (_: SecurityException) {
        }
    }
}
