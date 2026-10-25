package com.drena.simpen_woi.bridge

import android.app.Activity
import android.content.ComponentName
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import com.drena.simpen_woi.capture.CaptureSimulator
import com.drena.simpen_woi.capture.NotificationCaptureService
import com.drena.simpen_woi.capture.inspector.CaptureInspector
import com.drena.simpen_woi.capture.inspector.toInspectorMap
import com.drena.simpen_woi.capture.inspector.toListenerStatusMap
import com.drena.simpen_woi.capture.notify.CaptureNotifier
import com.drena.simpen_woi.capture.prefs.CapturePreferences
import com.drena.simpen_woi.capture.queue.CaptureExecutor
import com.drena.simpen_woi.capture.queue.CaptureQueue
import com.drena.simpen_woi.capture.queue.toMap
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class CaptureChannelHandler(private val activity: Activity) {
    companion object {
        private const val CHANNEL = "simpenwoi/capture"
    }

    private val mainHandler = Handler(Looper.getMainLooper())

    fun attach(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            handle(call, result)
        }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "getPendingCaptures" -> {
                    runAsync(result) {
                        CaptureQueue.getInstance(activity).getPending().map { it.toMap() }
                    }
                }

                "getDirtyCaptures" -> {
                    runAsync(result) {
                        CaptureQueue.getInstance(activity).getDirtyCaptures().map { it.toMap() }
                    }
                }

                "markSynced" -> {
                    val ids = call.longListArgument("ids")
                    runAsync(result) {
                        CaptureQueue.getInstance(activity).markSynced(ids)
                        null
                    }
                }

                "markImported" -> {
                    val ids = call.longListArgument("ids")
                    runAsync(result) {
                        val queue = CaptureQueue.getInstance(activity)
                        queue.markImported(ids)
                        val notifier = CaptureNotifier(activity)
                        ids.forEach { notifier.cancel(it) }
                        notifier.showSummary(queue.countUnanswered())
                        null
                    }
                }

                "pushCategories" -> {
                    val categories = call.argument<List<*>>("categories")
                    val topCategories = call.argument<List<*>>("top_categories")
                    runAsync(result) {
                        CapturePreferences.saveCategories(activity, categories, topCategories)
                        null
                    }
                }

                "pushMerchantRules" -> {
                    val rules = call.argument<List<*>>("rules")
                    runAsync(result) {
                        CapturePreferences.saveMerchantRules(activity, rules)
                        null
                    }
                }

                "openListenerSettings" -> {
                    val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    activity.startActivity(intent)
                    result.success(null)
                }

                "isListenerEnabled" -> {
                    result.success(isNotificationListenerEnabled())
                }

                "simulateCapture" -> {
                    val amount = call.argument<Number>("amount")?.toLong() ?: 25000L
                    val merchant = call.argument<String>("merchant") ?: "Warung Bu Tini"
                    runAsync(result) {
                        CaptureSimulator.simulate(activity, amount, merchant)
                        null
                    }
                }

                "getInspectorLog" -> {
                    runAsync(result) {
                        CaptureInspector.getLog(activity).map { it.toInspectorMap() }
                    }
                }

                "clearInspectorLog" -> {
                    runAsync(result) {
                        CaptureInspector.clear(activity)
                        null
                    }
                }

                "setInspectorEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    if (enabled && !isDebuggable()) {
                        result.error(
                            "inspector_debug_only",
                            "Inspektor hanya tersedia pada build debug.",
                            null,
                        )
                        return
                    }
                    runAsync(result) {
                        CaptureInspector.setEnabled(activity, enabled)
                        null
                    }
                }

                "getListenerStatus" -> {
                    runAsync(result) {
                        CaptureInspector.getListenerStatus(activity).toListenerStatusMap()
                    }
                }

                else -> result.notImplemented()
            }
        } catch (error: Exception) {
            result.error("capture_error", error.message, null)
        }
    }

    private fun runAsync(result: MethodChannel.Result, block: () -> Any?) {
        CaptureExecutor.execute {
            try {
                val value = block()
                mainHandler.post { result.success(value) }
            } catch (error: Exception) {
                mainHandler.post { result.error("capture_error", error.message, null) }
            }
        }
    }

    private fun isDebuggable(): Boolean {
        return (activity.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
    }

    private fun isNotificationListenerEnabled(): Boolean {
        val enabled = Settings.Secure.getString(
            activity.contentResolver,
            "enabled_notification_listeners",
        ) ?: return false
        val component = ComponentName(activity, NotificationCaptureService::class.java)
        return enabled.split(":").any {
            it.equals(component.flattenToString(), ignoreCase = true)
        }
    }

    private fun MethodCall.longListArgument(name: String): List<Long> {
        return (argument<List<*>>(name) ?: emptyList<Any>())
            .mapNotNull { (it as? Number)?.toLong() }
    }
}
