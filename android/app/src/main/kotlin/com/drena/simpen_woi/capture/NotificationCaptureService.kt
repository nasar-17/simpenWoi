package com.drena.simpen_woi.capture

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import com.drena.simpen_woi.bridge.CaptureEventChannel
import com.drena.simpen_woi.bridge.CaptureEngineHost
import com.drena.simpen_woi.capture.inspector.CaptureInspector
import com.drena.simpen_woi.capture.inspector.InspectorEntry
import com.drena.simpen_woi.capture.notify.CaptureNotifier
import com.drena.simpen_woi.capture.parser.SupportedApps
import com.drena.simpen_woi.capture.prefs.CapturePreferences
import com.drena.simpen_woi.capture.queue.CaptureExecutor
import com.drena.simpen_woi.capture.queue.CaptureQueue

/** Capture losslessly; interpretation belongs exclusively to FunctionGemma. */
class NotificationCaptureService : NotificationListenerService() {
    override fun onListenerConnected() {
        super.onListenerConnected()
        CaptureEngineHost.ensureRunning(applicationContext)
        CaptureExecutor.execute { CaptureInspector.updateListenerStatus(this, true) }
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        CaptureExecutor.execute { CaptureInspector.updateListenerStatus(this, false) }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        CaptureExecutor.execute {
            try {
                capture(sbn)
            } catch (_: Exception) {
                Log.e("simpenWoi", "Could not queue notification for local AI")
            }
        }
    }

    private fun capture(sbn: StatusBarNotification) {
        if (!SupportedApps.isSupported(sbn.packageName)) return
        if ((sbn.notification.flags and Notification.FLAG_GROUP_SUMMARY) != 0) return
        val extras = sbn.notification.extras
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
        val raw = listOfNotNull(title, text, bigText).distinct().joinToString("\n")
        if (raw.isBlank()) return
        val queue = CaptureQueue.getInstance(this)
        // Key+content: repeated updates are ignored; separate payments of the same
        // amount (even from different apps) must never be discarded.
        val identity = "${sbn.key}:${sbn.postTime}:${raw.hashCode()}"
        if (CapturePreferences.isNotificationKeyDuplicate(this, identity)) return
        val id = queue.insertCapture(0, null, sbn.packageName, sbn.postTime, "raw", null, raw)
        if (id <= 0) return
        CapturePreferences.shouldIgnoreNotificationKey(this, identity)
        if (CaptureInspector.isEnabled(this)) {
            CaptureInspector.record(this, InspectorEntry(
                sbn.postTime, sbn.packageName, title, text, bigText,
                "Menunggu pemahaman AI lokal", null,
            ))
        }
        CaptureEngineHost.ensureRunning(applicationContext)
        CaptureNotifier(this).showAiPending(id)
        CaptureEventChannel.emitQueueChanged()
    }
}
