package com.drena.simpen_woi.capture.parser

internal object CaptureAmountParser {
    private val amountPattern = Regex("""Rp\s?[\d.,]+""", RegexOption.IGNORE_CASE)

    fun extract(text: String): Long? {
        val raw = amountPattern.find(text)?.value ?: return null
        val cleaned = raw
            .replace("Rp", "", ignoreCase = true)
            .replace(" ", "")
            .replace(".", "")
            .substringBefore(",")
        return cleaned.toLongOrNull()?.takeIf { it > 0L }
    }
}
