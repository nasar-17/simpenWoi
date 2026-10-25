package com.drena.simpen_woi.capture.notify

internal object CaptureNotificationContract {
    const val CHANNEL_ID = "capture"
    const val CHANNEL_NAME = "Tangkapan transaksi"
    const val GROUP_KEY = "simpenwoi_capture_group"
    const val SUMMARY_ID = 990001
    const val ACTION_CATEGORY = "com.drena.simpen_woi.action.CATEGORY"
    const val ACTION_REPLY = "com.drena.simpen_woi.action.REPLY"
    const val ACTION_UNDO = "com.drena.simpen_woi.action.UNDO"
    const val ACTION_UNPAIR = "com.drena.simpen_woi.action.UNPAIR"
    const val EXTRA_CAPTURE_ID = "capture_id"
    const val EXTRA_CATEGORY_ID = "category_id"
    const val EXTRA_CATEGORY_NAME = "category_name"
    const val KEY_TEXT_REPLY = "capture_text_reply"
    const val QUESTION_TIMEOUT_MS = 6 * 60 * 60 * 1000L
}
