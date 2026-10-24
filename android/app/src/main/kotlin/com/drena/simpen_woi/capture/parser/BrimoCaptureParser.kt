package com.drena.simpen_woi.capture.parser

internal object BrimoCaptureParser {
    fun parse(text: String): String? = MerchantExtractor.extract(text)
}
