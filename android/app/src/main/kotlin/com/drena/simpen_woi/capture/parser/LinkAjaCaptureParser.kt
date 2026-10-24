package com.drena.simpen_woi.capture.parser

internal object LinkAjaCaptureParser {
    fun parse(text: String): String? = MerchantExtractor.extract(text)
}
