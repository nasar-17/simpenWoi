package com.drena.simpen_woi

object CaptureParser {
    private val amountPattern = Regex("""Rp\s?[\d.,]+""", RegexOption.IGNORE_CASE)
    private val merchantPattern = Regex(
        """\b(?:ke|di)\s+([A-Za-z0-9][A-Za-z0-9 .&'\-]{1,48})""",
        RegexOption.IGNORE_CASE,
    )
    private val outgoingKeywords = listOf(
        "berhasil",
        "pembayaran",
        "dibayar",
        "membayar",
        "transfer ke",
        "bayar ke",
    )
    private val ignoredKeywords = listOf(
        "promo",
        "cashback",
        "diskon",
        "voucher",
        "top up",
        "topup",
        "isi saldo",
        "dana masuk",
        "uang masuk",
        "menerima transfer",
        "anda menerima",
        "refund",
        "hadiah",
        "undian",
        "bonus",
    )
    private val merchantCutters = listOf(
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
        if (outgoingKeywords.none { lower.contains(it) }) return null
        if (ignoredKeywords.any { lower.contains(it) }) return null

        val amount = extractAmount(combined) ?: return null
        return ParsedCapture(amount, extractMerchantFor(packageName, combined))
    }

    private fun extractAmount(text: String): Long? {
        val raw = amountPattern.find(text)?.value ?: return null
        val cleaned = raw
            .replace("Rp", "", ignoreCase = true)
            .replace(" ", "")
            .replace(".", "")
            .substringBefore(",")
        return cleaned.toLongOrNull()?.takeIf { it > 0L }
    }

    private fun extractMerchantFor(packageName: String, text: String): String? {
        return when (packageName) {
            "com.gojek.app" -> parseGopay(text)
            "ovo.id" -> parseOvo(text)
            "id.dana" -> parseDana(text)
            "com.shopee.id" -> parseShopeePay(text)
            "com.telkom.mwallet" -> parseLinkAja(text)
            "com.bca" -> parseBca(text)
            "id.bmri.livin" -> parseLivin(text)
            "id.co.bri.brimo" -> parseBrimo(text)
            else -> parseGeneric(text)
        }
    }

    fun parseGopay(text: String): String? = extractMerchant(text)

    fun parseOvo(text: String): String? = extractMerchant(text)

    fun parseDana(text: String): String? = extractMerchant(text)

    fun parseShopeePay(text: String): String? = extractMerchant(text)

    fun parseLinkAja(text: String): String? = extractMerchant(text)

    fun parseBca(text: String): String? = extractMerchant(text)

    fun parseLivin(text: String): String? = extractMerchant(text)

    fun parseBrimo(text: String): String? = extractMerchant(text)

    fun parseGeneric(text: String): String? = extractMerchant(text)

    private fun extractMerchant(text: String): String? {
        val match = merchantPattern.find(text) ?: return null
        var name = match.groupValues[1]
        merchantCutters.forEach { cutter ->
            val index = name.indexOf(cutter, ignoreCase = true)
            if (index > 0) name = name.substring(0, index)
        }
        name = name.trim().trim('.', ',', '-', ' ', '\n')
        return name.takeIf { it.length in 2..48 }
    }
}
