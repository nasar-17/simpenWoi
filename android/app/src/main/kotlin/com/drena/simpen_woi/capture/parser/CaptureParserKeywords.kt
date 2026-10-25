package com.drena.simpen_woi.capture.parser

internal object CaptureParserKeywords {
    val outgoing = listOf(
        "berhasil",
        "pembayaran",
        "dibayar",
        "membayar",
        "transfer ke",
        "bayar ke",
    )

    val ignored = listOf(
        "promo",
        "cashback",
        "diskon",
        "voucher",
        "top up",
        "topup",
        "isi saldo",
        "dana masuk",
        "uang masuk",
        "menerima transfer",
        "anda menerima",
        "refund",
        "hadiah",
        "undian",
        "bonus",
    )
}
