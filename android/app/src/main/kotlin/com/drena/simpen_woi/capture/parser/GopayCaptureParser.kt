package com.drena.simpen_woi.capture.parser

internal object GopayCaptureParser {
    fun parse(text: String): String? = MerchantExtractor.extract(text)
}
