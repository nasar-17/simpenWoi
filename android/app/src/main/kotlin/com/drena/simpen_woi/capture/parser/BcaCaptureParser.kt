package com.drena.simpen_woi.capture.parser

internal object BcaCaptureParser {
    fun parse(text: String): String? = MerchantExtractor.extract(text)
}
