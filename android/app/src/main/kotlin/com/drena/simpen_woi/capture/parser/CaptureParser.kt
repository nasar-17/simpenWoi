package com.drena.simpen_woi.capture.parser

import com.drena.simpen_woi.capture.queue.ParsedCapture

object CaptureParser {
    private const val DANA_PACKAGE = "id.dana"
    private const val SEA_BANK_PACKAGE = "id.co.bankbkemobile.digitalbank"

    fun detect(
        packageName: String,
        title: String?,
        text: String?,
        bigText: String?,
    ): CaptureDetection {
        if (!SupportedApps.isSupported(packageName)) {
            return CaptureDetection.Skipped(CaptureSkipReason.PACKAGE_NOT_WHITELISTED)
        }

        val content = normalize(listOfNotNull(text, bigText))
        when (packageName) {
            DANA_PACKAGE -> DanaCaptureParser.detect(content)?.let { return it }
            SEA_BANK_PACKAGE -> SeaBankCaptureParser.detect(title, content)?.let { return it }
        }

        val combined = normalize(listOfNotNull(title, text, bigText))
        if (combined.isEmpty()) {
            return CaptureDetection.Skipped(CaptureSkipReason.PAYMENT_KEYWORD_NOT_MATCHED)
        }

        val lower = combined.lowercase()
        if (CaptureParserKeywords.outgoing.none { lower.contains(it) }) {
            return CaptureDetection.Skipped(CaptureSkipReason.PAYMENT_KEYWORD_NOT_MATCHED)
        }
        if (CaptureParserKeywords.ignored.any { lower.contains(it) }) {
            return CaptureDetection.Skipped(CaptureSkipReason.PAYMENT_KEYWORD_NOT_MATCHED)
        }

        val amount = CaptureAmountParser.extract(combined)
            ?: return CaptureDetection.Skipped(CaptureSkipReason.AMOUNT_NOT_FOUND)
        return CaptureDetection.Captured(
            amount,
            CaptureMerchantResolver.resolve(packageName, combined),
            CaptureDirection.OUT,
        )
    }

    fun parse(
        packageName: String,
        title: String?,
        text: String?,
        bigText: String?,
    ): ParsedCapture? {
        val detection = detect(packageName, title, text, bigText)
        if (detection !is CaptureDetection.Captured) return null
        return ParsedCapture(detection.amount, detection.merchant)
    }

    private fun normalize(values: List<String>): String {
        return values.joinToString(" ")
            .replace(Regex("\\s+"), " ")
            .trim()
    }
}
