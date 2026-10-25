package com.drena.simpen_woi.capture.parser

internal object DanaCaptureParser {
    private const val TRANSFER_KEYWORD = "telah dikirim ke"
    private val targetPattern = Regex(
        """telah\s+dikirim\s+ke\s+(.+?)\s+-\s+""",
        RegexOption.IGNORE_CASE,
    )
    private val maskedAccountPattern = Regex("""\*+\d+""")

    fun detect(content: String): CaptureDetection? {
        if (!content.contains(TRANSFER_KEYWORD, ignoreCase = true)) return null
        val amount = CaptureAmountParser.extract(content)
            ?: return CaptureDetection.Skipped(
                CaptureSkipReason.AMOUNT_NOT_FOUND,
                CaptureDirection.OUT,
            )
        val merchant = targetPattern.find(content)
            ?.groupValues
            ?.get(1)
            ?.replace(maskedAccountPattern, "")
            ?.trim()
            ?.trim('.', ',', '-', ' ')
            ?.takeIf { it.isNotEmpty() }
        return CaptureDetection.Captured(amount, merchant, CaptureDirection.OUT)
    }

    fun parse(text: String): String? = MerchantExtractor.extract(text)
}
