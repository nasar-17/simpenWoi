package com.drena.simpen_woi.capture.parser

sealed class CaptureDetection {
    abstract val direction: CaptureDirection?

    data class Captured(
        val amount: Long,
        val merchant: String?,
        override val direction: CaptureDirection,
    ) : CaptureDetection()

    data class Skipped(
        val reason: CaptureSkipReason,
        override val direction: CaptureDirection? = null,
    ) : CaptureDetection()
}

enum class CaptureDirection(val label: String) {
    OUT("OUT"),
    IN("IN"),
}

enum class CaptureSkipReason(val label: String) {
    PACKAGE_NOT_WHITELISTED("package tidak ada di whitelist"),
    PAYMENT_KEYWORD_NOT_MATCHED("kata kunci pembayaran tidak cocok"),
    AMOUNT_NOT_FOUND("nominal tidak ditemukan"),
    DUPLICATE("terdeteksi duplikat"),
}
