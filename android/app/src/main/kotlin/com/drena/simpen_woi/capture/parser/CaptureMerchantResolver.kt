package com.drena.simpen_woi.capture.parser

internal object CaptureMerchantResolver {
    fun resolve(packageName: String, text: String): String? {
        return when (packageName) {
            "com.gojek.app" -> GopayCaptureParser.parse(text)
            "ovo.id" -> OvoCaptureParser.parse(text)
            "id.dana" -> DanaCaptureParser.parse(text)
            "com.shopee.id" -> ShopeePayCaptureParser.parse(text)
            "com.telkom.mwallet" -> LinkAjaCaptureParser.parse(text)
            "com.bca" -> BcaCaptureParser.parse(text)
            "id.bmri.livin" -> LivinCaptureParser.parse(text)
            "id.co.bri.brimo" -> BrimoCaptureParser.parse(text)
            else -> GenericCaptureParser.parse(text)
        }
    }
}
