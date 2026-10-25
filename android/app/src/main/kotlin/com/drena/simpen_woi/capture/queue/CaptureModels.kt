package com.drena.simpen_woi.capture.queue

data class PendingCapture(
    val id: Long,
    val amount: Long,
    val merchant: String?,
    val sourcePackage: String,
    val postedAt: Long,
    val direction: String,
    val categoryId: Int?,
    val note: String?,
    val isTransfer: Boolean = false,
    val pairId: Long? = null,
    val merged: Boolean = false,
    val transferSourcePackage: String? = null,
    val transferDestinationPackage: String? = null,
)

data class CaptureCategory(
    val id: Int,
    val name: String,
)

data class MerchantRule(
    val merchant: String,
    val categoryId: Int,
    val categoryName: String,
)

data class ParsedCapture(
    val amount: Long,
    val merchant: String?,
)

data class DirtyCapture(
    val id: Long,
    val categoryId: Int?,
    val note: String?,
)

fun PendingCapture.toMap(): Map<String, Any?> = mapOf(
    "id" to id,
    "amount" to amount,
    "merchant" to merchant,
    "source_package" to sourcePackage,
    "posted_at" to postedAt,
    "direction" to direction,
    "category_id" to categoryId,
    "note" to note,
    "is_transfer" to isTransfer,
    "pair_id" to pairId,
    "transfer_source_package" to transferSourcePackage,
    "transfer_destination_package" to transferDestinationPackage,
)

fun DirtyCapture.toMap(): Map<String, Any?> = mapOf(
    "id" to id,
    "category_id" to categoryId,
    "note" to note,
)
