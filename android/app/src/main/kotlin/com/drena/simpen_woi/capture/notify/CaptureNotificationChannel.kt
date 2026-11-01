package com.drena.simpen_woi.capture.notify

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ContentResolver
import android.content.Context
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import com.drena.simpen_woi.R

internal object CaptureNotificationChannel {
    private val vibration = longArrayOf(0, 90, 60, 90)

    fun builder(context: Context): NotificationCompat.Builder {
        ensure(context)
        return NotificationCompat.Builder(context, CaptureNotificationContract.CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification_simpenwoi)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setSound(soundUri(context))
            .setVibrate(vibration)
            .setGroupAlertBehavior(NotificationCompat.GROUP_ALERT_CHILDREN)
            .setOnlyAlertOnce(true)
            .setShowWhen(true)
    }

    private fun soundUri(context: Context): Uri = Uri.Builder()
        .scheme(ContentResolver.SCHEME_ANDROID_RESOURCE)
        .authority(context.packageName)
        .appendPath("raw")
        .appendPath("simpenwoi_chime")
        .build()

    private fun ensure(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CaptureNotificationContract.CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CaptureNotificationContract.CHANNEL_ID,
            CaptureNotificationContract.CHANNEL_NAME,
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = CaptureNotificationText.CHANNEL_DESCRIPTION
            setSound(
                soundUri(context),
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
            enableVibration(true)
            vibrationPattern = vibration
            setShowBadge(true)
        }
        // No bypass-DND or channel deletion: user sound settings remain authoritative.
        manager.createNotificationChannel(channel)
    }
}
