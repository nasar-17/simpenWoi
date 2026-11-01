package com.drena.simpen_woi

import android.content.Context
import com.drena.simpen_woi.bridge.CaptureEngineHost
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: Context): FlutterEngine {
        return CaptureEngineHost.getOrCreate(context)
    }

    // The notification listener shares this engine after the UI is closed.
    // The model itself retains the normal idle-unload policy in Dart.
    override fun shouldDestroyEngineWithHost(): Boolean = false
}
