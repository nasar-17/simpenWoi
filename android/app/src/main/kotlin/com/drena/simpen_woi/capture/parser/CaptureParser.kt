package com.drena.simpen_woi.capture.parser

import com.drena.simpen_woi.capture.queue.ParsedCapture

object CaptureParser {
    fun detect(
        packageName: String,
        title: String?,
        text: String?,
        bigText: String?,
    ): CaptureDetection {
        if (!SupportedApps.isSupported(packageName)) {
            return CaptureDetection.Skipped(CaptureSkipReason.PACKAGE_NOT_WHITELISTED)
        }

        val combined = listOfNotNull(title, text, bigText)
            .joinToString(" ")
            .replace(Regex("\\s+"), " ")
            .trim()
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
}
