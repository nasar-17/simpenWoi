package com.drena.simpen_woi.capture.queue

import java.util.concurrent.Executors

internal object CaptureExecutor {
    private val executor = Executors.newSingleThreadExecutor()

    fun execute(task: () -> Unit) {
        executor.execute(task)
    }
}
