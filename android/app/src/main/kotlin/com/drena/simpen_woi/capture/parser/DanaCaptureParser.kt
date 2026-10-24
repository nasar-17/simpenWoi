package com.drena.simpen_woi.capture.parser

internal object DanaCaptureParser {
    fun parse(text: String): String? = MerchantExtractor.extract(text)
}
