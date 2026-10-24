package com.drena.simpen_woi

import android.content.ComponentName
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "simpenwoi/capture"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "getPendingCaptures" -> {
                        result.success(CaptureQueue(this).getPending().map { it.toMap() })
                    }

                    "markImported" -> {
                        val ids = (call.argument<List<*>>("ids") ?: emptyList<Any>())
                            .mapNotNull { (it as? Number)?.toLong() }
                        val queue = CaptureQueue(this)
                        queue.markImported(ids)
                        val notifier = CaptureNotifier(this)
                        ids.forEach { notifier.cancel(it) }
                        notifier.showSummary(queue.countUnanswered())
                        result.success(null)
                    }

                    "pushCategories" -> {
                        CapturePreferences.saveCategories(
                            this,
                            call.argument<List<*>>("categories"),
                            call.argument<List<*>>("top_categories"),
                        )
                        result.success(null)
                    }

                    "pushMerchantRules" -> {
                        CapturePreferences.saveMerchantRules(
                            this,
                            call.argument<List<*>>("rules"),
                        )
                        result.success(null)
                    }

                    "openListenerSettings" -> {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(null)
                    }

                    "isListenerEnabled" -> {
                        result.success(isNotificationListenerEnabled())
                    }

                    "simulateCapture" -> {
                        val amount = call.argument<Number>("amount")?.toLong() ?: 25000L
                        val merchant = call.argument<String>("merchant") ?: "Warung Bu Tini"
                        CaptureSimulator.simulate(this, amount, merchant)
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            } catch (error: Exception) {
                result.error("capture_error", error.message, null)
            }
        }
    }

    private fun isNotificationListenerEnabled(): Boolean {
        val enabled = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners",
        ) ?: return false
        val component = ComponentName(this, NotificationCaptureService::class.java)
        return enabled.split(":").any {
            it.equals(component.flattenToString(), ignoreCase = true)
        }
    }
}
