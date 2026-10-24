package com.drena.simpen_woi

data class PendingCapture(
    val id: Long,
    val amount: Long,
    val merchant: String?,
    val sourcePackage: String,
    val postedAt: Long,
    val categoryId: Int?,
    val note: String?,
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
    "category_id" to categoryId,
    "note" to note,
)

fun DirtyCapture.toMap(): Map<String, Any?> = mapOf(
    "id" to id,
    "category_id" to categoryId,
    "note" to note,
)
