package com.drena.simpen_woi.capture.parser

sealed class CaptureDetection {
    data class Captured(
        val amount: Long,
        val merchant: String?,
    ) : CaptureDetection()

    data class Skipped(
        val reason: CaptureSkipReason,
    ) : CaptureDetection()
}

enum class CaptureSkipReason(val label: String) {
    PACKAGE_NOT_WHITELISTED("package tidak ada di whitelist"),
    PAYMENT_KEYWORD_NOT_MATCHED("kata kunci pembayaran tidak cocok"),
    AMOUNT_NOT_FOUND("nominal tidak ditemukan"),
    DUPLICATE("terdeteksi duplikat"),
}
