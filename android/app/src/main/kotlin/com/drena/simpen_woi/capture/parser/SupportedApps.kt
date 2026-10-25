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

    private val names: Map<String, String> = mapOf(
        "com.gojek.app" to "GoPay",
        "ovo.id" to "OVO",
        "id.dana" to "DANA",
        "com.shopee.id" to "ShopeePay",
        "com.telkom.mwallet" to "LinkAja",
        "com.bca" to "BCA",
        "id.bmri.livin" to "Livin",
        "id.co.bri.brimo" to "BRImo",
        "id.co.bankbkemobile.digitalbank" to "SeaBank",
    )

    fun isSupported(packageName: String?): Boolean {
        return packageName != null && packages.contains(packageName)
    }

    fun displayName(packageName: String?): String {
        if (packageName == null) return "Dompet"
        return names[packageName] ?: packageName.substringAfterLast('.')
    }
}
