package com.drena.simpen_woi.capture.parser

internal object LivinCaptureParser {
    fun parse(text: String): String? = MerchantExtractor.extract(text)
}
