package com.drena.simpen_woi.capture.parser

internal object SeaBankCaptureParser {
    private const val TITLE_KEYWORD = "dana masuk"
    private const val TEXT_KEYWORD = "menerima dana"
    private val senderPattern = Regex(
        """\bdari\s+(.+?)(?:\s+pada\b.*)?$""",
        RegexOption.IGNORE_CASE,
    )

    fun detect(title: String?, content: String): CaptureDetection? {
        val incoming = title.orEmpty().contains(TITLE_KEYWORD, ignoreCase = true) ||
            content.contains(TEXT_KEYWORD, ignoreCase = true)
        if (!incoming) return null
        val amount = CaptureAmountParser.extract(content)
            ?: return CaptureDetection.Skipped(
                CaptureSkipReason.AMOUNT_NOT_FOUND,
                CaptureDirection.IN,
            )
        val sender = senderPattern.find(content)
            ?.groupValues
            ?.get(1)
            ?.trim()
            ?.trimEnd('.', ',', ';')
            ?.takeIf { it.isNotEmpty() }
        return CaptureDetection.Captured(amount, sender, CaptureDirection.IN)
    }
}
