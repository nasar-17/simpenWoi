package com.drena.simpen_woi.capture.parser

internal object MerchantExtractor {
    private val merchantPattern = Regex(
        """\b(?:ke|di)\s+([A-Za-z0-9][A-Za-z0-9 .&'\-]{1,48})""",
        RegexOption.IGNORE_CASE,
    )

    private val cutters = listOf(
        " sebesar",
        " senilai",
        " dengan",
        " pada",
        " tanggal",
        " berhasil",
        " melalui",
        " dari",
        ",",
        " - ",
    )

    fun extract(text: String): String? {
        val match = merchantPattern.find(text) ?: return null
        var name = match.groupValues[1]
        cutters.forEach { cutter ->
            val index = name.indexOf(cutter, ignoreCase = true)
            if (index > 0) name = name.substring(0, index)
        }
        name = name.trim().trim('.', ',', '-', ' ', '\n')
        return name.takeIf { it.length in 2..48 }
    }
}
