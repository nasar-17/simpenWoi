package com.drena.simpen_woi.capture.parser

internal object ShopeePayCaptureParser {
    fun parse(text: String): String? = MerchantExtractor.extract(text)
}
