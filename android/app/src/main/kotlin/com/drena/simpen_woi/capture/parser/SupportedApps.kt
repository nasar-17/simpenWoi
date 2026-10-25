package com.drena.simpen_woi.capture.parser

object SupportedApps {
    val packages: Set<String> = setOf(
        "com.gojek.app",
        "ovo.id",
        "id.dana",
        "com.shopee.id",
        "com.telkom.mwallet",
        "com.bca",
        "id.bmri.livin",
        "id.co.bri.brimo",
        "id.co.bankbkemobile.digitalbank",
    )

    fun isSupported(packageName: String?): Boolean {
        return packageName != null && packages.contains(packageName)
    }
}
