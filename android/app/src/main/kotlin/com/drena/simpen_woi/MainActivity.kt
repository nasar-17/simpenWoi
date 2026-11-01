package com.drena.simpen_woi

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.os.Bundle
import com.drena.simpen_woi.bridge.CaptureEngineHost
import com.drena.simpen_woi.capture.CaptureSimulator
import com.drena.simpen_woi.capture.queue.CaptureExecutor
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: Context): FlutterEngine {
        return CaptureEngineHost.getOrCreate(context)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleDebugCapture(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleDebugCapture(intent)
    }

    private fun handleDebugCapture(intent: Intent?) {
        if ((applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) == 0) return
        if (intent?.getBooleanExtra("simpenwoi_simulate_capture", false) != true) return
        // Consume once: Activity recreation must not enqueue a second payment.
        intent.removeExtra("simpenwoi_simulate_capture")
        val context = applicationContext
        CaptureExecutor.execute {
            CaptureSimulator.simulate(context, 25000L, "Warung Bu Tini")
        }
    }

    // The notification listener shares this engine after the UI is closed.
    // The model itself retains the normal idle-unload policy in Dart.
    override fun shouldDestroyEngineWithHost(): Boolean = false
}
