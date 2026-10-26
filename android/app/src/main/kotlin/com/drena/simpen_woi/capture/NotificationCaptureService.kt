package com.drena.simpen_woi.capture

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import com.drena.simpen_woi.bridge.CaptureEventChannel
import com.drena.simpen_woi.capture.inspector.CaptureInspector
import com.drena.simpen_woi.capture.inspector.InspectorEntry
import com.drena.simpen_woi.capture.notify.CaptureNotifier
import com.drena.simpen_woi.capture.parser.CaptureDetection
import com.drena.simpen_woi.capture.parser.CaptureDirection
import com.drena.simpen_woi.capture.parser.CaptureParser
import com.drena.simpen_woi.capture.prefs.CapturePreferences
import com.drena.simpen_woi.capture.queue.CaptureExecutor
import com.drena.simpen_woi.capture.queue.CaptureQueue
import com.drena.simpen_woi.capture.queue.CaptureTransferStore
import com.drena.simpen_woi.capture.queue.PendingCapture

class NotificationCaptureService : NotificationListenerService() {
    companion object {
        private const val AMOUNT_DEDUPE_WINDOW_MS = 3 * 60 * 1000L
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        CaptureExecutor.execute {
            CaptureInspector.updateListenerStatus(this, true)
        }
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        CaptureExecutor.execute {
            CaptureInspector.updateListenerStatus(this, false)
        }
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
        if (sourcePackage == CaptureSimulator.SIMULATOR_PACKAGE) return

        val extras = sbn.notification?.extras
        val title = extras?.getCharSequence(Notification.EXTRA_TITLE)?.toString()
        val text = extras?.getCharSequence(Notification.EXTRA_TEXT)?.toString()
        val bigText = extras?.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
            ?: extras?.getCharSequence(Notification.EXTRA_SUMMARY_TEXT)?.toString()

        val detection = CaptureParser.detect(sourcePackage, title, text, bigText)
        val postedAt = if (sbn.postTime > 0L) sbn.postTime else System.currentTimeMillis()
        if (CaptureInspector.isEnabled(this)) {
            recordInspector(
                sbn,
                sourcePackage,
                title,
                text,
                bigText,
                inspectResult(detection, sourcePackage, sbn.key, postedAt),
                detection.direction?.label,
            )
        }
        if (detection !is CaptureDetection.Captured) return

        val key = sbn.key ?: return
        if (CapturePreferences.shouldIgnoreNotificationKey(this, key)) return

        val queue = CaptureQueue.getInstance(this)
        if (
            queue.hasRecentAmount(
                detection.amount,
                detection.direction.label,
                sourcePackage,
                postedAt,
                AMOUNT_DEDUPE_WINDOW_MS,
            )
        ) {
            return
        }

        val rule = if (detection.direction == CaptureDirection.OUT) {
            CapturePreferences.getMerchantRule(this, detection.merchant)
        } else {
            null
        }
        val captureId = queue.insertCapture(
            detection.amount,
            detection.merchant,
            sourcePackage,
            postedAt,
            detection.direction.label,
            rule?.categoryId,
        )
        if (captureId <= 0L) return

        val capture = PendingCapture(
            captureId,
            detection.amount,
            detection.merchant,
            sourcePackage,
            postedAt,
            detection.direction.label,
            rule?.categoryId,
            null,
        )
        val notifier = CaptureNotifier(this)
        val paired = CaptureTransferStore(queue).tryPair(this, capture)
        if (paired) {
            CaptureEventChannel.emitQueueChanged()
            return
        }
        if (rule != null) {
            notifier.showSaved(capture, rule.categoryName)
        } else {
            notifier.showQuestion(capture)
        }
        notifier.showSummary(queue.countUnanswered())
        CaptureEventChannel.emitQueueChanged()
    }

    private fun inspectResult(
        detection: CaptureDetection,
        sourcePackage: String,
        key: String?,
        postedAt: Long,
    ): String {
        if (detection !is CaptureDetection.Captured) {
            return CaptureInspector.resultFor(detection)
        }
        if (key == null || CapturePreferences.isNotificationKeyDuplicate(this, key)) {
            return CaptureInspector.resultFor(detection, duplicate = true)
        }
        val queue = CaptureQueue.getInstance(this)
        if (
            queue.hasRecentAmount(
                detection.amount,
                detection.direction.label,
                sourcePackage,
                postedAt,
                AMOUNT_DEDUPE_WINDOW_MS,
            )
        ) {
            return CaptureInspector.resultFor(detection, duplicate = true)
        }
        return CaptureInspector.resultFor(detection)
    }

    private fun recordInspector(
        sbn: StatusBarNotification,
        sourcePackage: String,
        title: String?,
        text: String?,
        bigText: String?,
        result: String,
        direction: String?,
    ) {
        val postedAt = if (sbn.postTime > 0L) sbn.postTime else System.currentTimeMillis()
        CaptureInspector.record(
            this,
            InspectorEntry(
                postedAt,
                sourcePackage,
                title,
                text,
                bigText,
                result,
                direction,
            ),
        )
    }
}
