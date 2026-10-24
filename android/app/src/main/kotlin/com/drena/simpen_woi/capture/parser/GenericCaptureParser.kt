package com.drena.simpen_woi.capture.parser

internal object GenericCaptureParser {
    fun parse(text: String): String? = MerchantExtractor.extract(text)
}
