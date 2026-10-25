package com.drena.simpen_woi.capture.notify

import com.drena.simpen_woi.capture.queue.PendingCapture

internal object CaptureNotificationText {
    const val CHANNEL_DESCRIPTION = "Catatan transaksi otomatis dari notifikasi e-wallet"
    const val QUESTION_TEXT = "Untuk apa?"
    const val QUESTION_BIG_TEXT = "Untuk apa? Ketuk kategori atau ketik catatan."
    const val INCOMING_QUESTION = "Dari mana?"
    const val INCOMING_BIG_TEXT = "Dari mana? Ketuk kategori pemasukan atau ketik catatan."
    const val REPLY_LABEL = "Catatan (mis. bakso 2 porsi)"
    const val SAVED_BODY = "Transaksi tercatat di simpenWoi."
    const val SUMMARY_BODY = "Buka simpenWoi untuk melengkapi kategori."
    const val REPLY_ACTION = "Ketik"
    const val EDIT_ACTION = "Ubah"
    const val DEFAULT_CATEGORY = "Kategori"

    fun noteLabel(note: String): String = "Catatan: $note"

    fun title(capture: PendingCapture): String {
        val merchant = capture.merchant?.takeIf { it.isNotBlank() }
        return if (merchant == null) {
            formatRupiah(capture.amount)
        } else {
            "${formatRupiah(capture.amount)} di $merchant"
        }
    }

    fun incomingTitle(capture: PendingCapture): String {
        val sender = capture.merchant?.takeIf { it.isNotBlank() } ?: "pengirim"
        return "${formatRupiah(capture.amount)} masuk dari $sender"
    }

    fun savedTitle(capture: PendingCapture, categoryName: String): String {
        val merchantPart = capture.merchant
            ?.takeIf { it.isNotBlank() }
            ?.let { " - $it" }
            .orEmpty()
        val label = categoryName.trim().ifBlank {
            capture.note?.trim().orEmpty()
        }
        val suffix = if (label.isNotBlank()) " - $label" else ""
        return "Tersimpan: ${formatRupiah(capture.amount)}$merchantPart$suffix"
    }

    fun incomingSavedTitle(capture: PendingCapture, categoryName: String): String {
        val label = categoryName.trim().ifBlank {
            capture.note?.trim().orEmpty()
        }
        val suffix = if (label.isNotBlank()) " - $label" else ""
        return "Tersimpan: ${incomingTitle(capture)}$suffix"
    }

    fun summaryTitle(count: Int): String = "$count transaksi belum dikategorikan"

    fun formatRupiah(amount: Long): String {
        val digits = amount.toString()
        val builder = StringBuilder()
        digits.forEachIndexed { index, character ->
            if (index > 0 && (digits.length - index) % 3 == 0) builder.append('.')
            builder.append(character)
        }
        return "Rp$builder"
    }
}
