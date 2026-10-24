package com.drena.simpen_woi.capture.parser

internal object OvoCaptureParser {
    fun parse(text: String): String? = MerchantExtractor.extract(text)
}
