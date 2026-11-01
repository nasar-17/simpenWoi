package com.drena.simpen_woi.bridge

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor

/**
 * One engine owns the database, capture sync and local model for the process.
 *
 * The notification listener can start it without an Activity. Opening the app
 * attaches the Activity to this same engine instead of creating another model
 * owner. Android may still stop the process; the durable native queue is the
 * recovery source when a new engine starts.
 */
object CaptureEngineHost {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var engine: FlutterEngine? = null

    fun ensureRunning(context: Context) {
        val applicationContext = context.applicationContext
        mainHandler.post {
            try {
                getOrCreate(applicationContext)
            } catch (_: RuntimeException) {
                // Do not log notification content or model prompts.
                Log.e("simpenWoi", "Background capture runtime could not start")
            }
        }
    }

    fun getOrCreate(context: Context): FlutterEngine {
        check(Looper.myLooper() == Looper.getMainLooper())
        engine?.let { return it }
        val applicationContext = context.applicationContext
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(applicationContext)
        loader.ensureInitializationComplete(applicationContext, null)
        val created = FlutterEngine(applicationContext)
        try {
            CaptureChannelHandler(applicationContext).attach(created)
            CaptureEventChannel.attach(created)
            created.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault(),
            )
            engine = created
            return created
        } catch (error: RuntimeException) {
            created.destroy()
            throw error
        }
    }
}
