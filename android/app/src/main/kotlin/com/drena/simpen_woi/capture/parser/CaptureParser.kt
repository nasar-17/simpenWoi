package com.drena.simpen_woi.capture.parser

import com.drena.simpen_woi.capture.queue.ParsedCapture

object CaptureParser {
    fun parse(
        packageName: String,
        title: String?,
        text: String?,
        bigText: String?,
    ): ParsedCapture? {
        val combined = listOfNotNull(title, text, bigText)
            .joinToString(" ")
            .replace(Regex("\\s+"), " ")
            .trim()
        if (combined.isEmpty()) return null

        val lower = combined.lowercase()
        if (CaptureParserKeywords.outgoing.none { lower.contains(it) }) return null
        if (CaptureParserKeywords.ignored.any { lower.contains(it) }) return null

        val amount = CaptureAmountParser.extract(combined) ?: return null
        return ParsedCapture(amount, CaptureMerchantResolver.resolve(packageName, combined))
    }
}
