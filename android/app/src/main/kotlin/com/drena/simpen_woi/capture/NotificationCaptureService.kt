package com.drena.simpen_woi.capture

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import com.drena.simpen_woi.capture.notify.CaptureNotifier
import com.drena.simpen_woi.capture.parser.CaptureParser
import com.drena.simpen_woi.capture.parser.SupportedApps
import com.drena.simpen_woi.capture.prefs.CapturePreferences
import com.drena.simpen_woi.capture.queue.CaptureExecutor
import com.drena.simpen_woi.capture.queue.CaptureQueue
import com.drena.simpen_woi.capture.queue.PendingCapture

class NotificationCaptureService : NotificationListenerService() {
    companion object {
        private const val AMOUNT_DEDUPE_WINDOW_MS = 3 * 60 * 1000L
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        CaptureExecutor.execute {
            try {
                handle(sbn)
            } catch (_: Exception) {
            }
        }
    }

    private fun handle(sbn: StatusBarNotification) {
        val sourcePackage = sbn.packageName ?: return
        if (sourcePackage == applicationContext.packageName) return
        if (!SupportedApps.isSupported(sourcePackage)) return

        val extras = sbn.notification?.extras ?: return
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
            ?: extras.getCharSequence(Notification.EXTRA_SUMMARY_TEXT)?.toString()

        val parsed = CaptureParser.parse(sourcePackage, title, text, bigText) ?: return
        if (CapturePreferences.shouldIgnoreNotificationKey(this, sbn.key ?: return)) return

        val queue = CaptureQueue.getInstance(this)
        if (queue.hasRecentAmount(parsed.amount, sourcePackage, AMOUNT_DEDUPE_WINDOW_MS)) return

        val postedAt = if (sbn.postTime > 0L) sbn.postTime else System.currentTimeMillis()
        val rule = CapturePreferences.getMerchantRule(this, parsed.merchant)
        val captureId = queue.insertCapture(
            parsed.amount,
            parsed.merchant,
            sourcePackage,
            postedAt,
            rule?.categoryId,
        )
        if (captureId <= 0L) return

        val capture = PendingCapture(
            captureId,
            parsed.amount,
            parsed.merchant,
            sourcePackage,
            postedAt,
            rule?.categoryId,
            null,
        )
        val notifier = CaptureNotifier(this)
        if (rule != null) {
            notifier.showSaved(capture, rule.categoryName)
        } else {
            notifier.showQuestion(capture)
        }
        notifier.showSummary(queue.countUnanswered())
    }
}
