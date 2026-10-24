package com.drena.simpen_woi

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

object CapturePreferences {
    private const val PREFS_NAME = "simpenwoi_capture_prefs"
    private const val KEY_CATEGORIES = "expense_categories"
    private const val KEY_TOP_CATEGORIES = "top_categories"
    private const val KEY_MERCHANT_RULES = "merchant_rules"
    private const val KEY_RECENT_KEYS = "recent_notification_keys"
    private const val RECENT_KEY_TTL_MS = 10 * 60 * 1000L
    private const val MAX_RECENT_KEYS = 120

    private fun prefs(context: Context): SharedPreferences {
        return context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    fun saveCategories(context: Context, raw: List<*>?, topRaw: List<*>?) {
        prefs(context).edit()
            .putString(KEY_CATEGORIES, categoriesToJson(parseCategoryList(raw)).toString())
            .putString(KEY_TOP_CATEGORIES, categoriesToJson(parseCategoryList(topRaw)).toString())
            .apply()
    }

    fun getCategories(context: Context): List<CaptureCategory> {
        return readCategoryList(prefs(context).getString(KEY_CATEGORIES, null))
    }

    fun getTopCategories(context: Context): List<CaptureCategory> {
        return readCategoryList(prefs(context).getString(KEY_TOP_CATEGORIES, null))
    }

    fun saveMerchantRules(context: Context, raw: List<*>?) {
        val root = JSONObject()
        raw?.forEach { item ->
            val map = item as? Map<*, *> ?: return@forEach
            val merchant = (map["merchant"] as? String)?.trim()?.lowercase() ?: return@forEach
            val categoryId = (map["category_id"] as? Number)?.toInt() ?: return@forEach
            val categoryName = map["category_name"] as? String ?: return@forEach
            if (merchant.isBlank() || categoryId <= 0 || categoryName.isBlank()) return@forEach
            root.put(
                merchant,
                JSONObject()
                    .put("id", categoryId)
                    .put("name", categoryName),
            )
        }
        prefs(context).edit().putString(KEY_MERCHANT_RULES, root.toString()).apply()
    }

    fun getMerchantRule(context: Context, merchant: String?): MerchantRule? {
        val normalized = merchant?.trim()?.lowercase() ?: return null
        if (normalized.isBlank()) return null
        val raw = prefs(context).getString(KEY_MERCHANT_RULES, null) ?: return null
        return try {
            val rule = JSONObject(raw).optJSONObject(normalized) ?: return null
            val categoryId = rule.optInt("id", 0)
            val categoryName = rule.optString("name", "")
            if (categoryId <= 0 || categoryName.isBlank()) {
                null
            } else {
                MerchantRule(normalized, categoryId, categoryName)
            }
        } catch (_: JSONException) {
            null
        }
    }

    fun shouldIgnoreNotificationKey(context: Context, key: String): Boolean {
        val preferences = prefs(context)
        val now = System.currentTimeMillis()
        val stored = preferences.getStringSet(KEY_RECENT_KEYS, emptySet()) ?: emptySet()
        val valid = mutableSetOf<String>()
        var duplicate = false

        stored.forEach { entry ->
            val separator = entry.lastIndexOf('|')
            if (separator <= 0) return@forEach
            val timestamp = entry.substring(separator + 1).toLongOrNull() ?: return@forEach
            if (timestamp < now - RECENT_KEY_TTL_MS) return@forEach
            if (entry.substring(0, separator) == key) duplicate = true
            valid.add(entry)
        }

        if (!duplicate) {
            valid.add("$key|$now")
            if (valid.size > MAX_RECENT_KEYS) {
                val trimmed = valid
                    .sortedByDescending { it.substringAfterLast('|').toLongOrNull() ?: 0L }
                    .take(MAX_RECENT_KEYS)
                valid.clear()
                valid.addAll(trimmed)
            }
        }

        preferences.edit().putStringSet(KEY_RECENT_KEYS, valid).apply()
        return duplicate
    }

    private fun parseCategoryList(raw: List<*>?): List<CaptureCategory> {
        if (raw == null) return emptyList()
        return raw.mapNotNull { item ->
            val map = item as? Map<*, *> ?: return@mapNotNull null
            val id = (map["id"] as? Number)?.toInt() ?: return@mapNotNull null
            val name = map["name"] as? String ?: return@mapNotNull null
            if (id <= 0 || name.isBlank()) null else CaptureCategory(id, name)
        }
    }

    private fun categoriesToJson(categories: List<CaptureCategory>): JSONArray {
        val array = JSONArray()
        categories.forEach { category ->
            array.put(JSONObject().put("id", category.id).put("name", category.name))
        }
        return array
    }

    private fun readCategoryList(raw: String?): List<CaptureCategory> {
        if (raw.isNullOrBlank()) return emptyList()
        return try {
            val array = JSONArray(raw)
            (0 until array.length()).mapNotNull { index ->
                val item = array.optJSONObject(index) ?: return@mapNotNull null
                val id = item.optInt("id", 0)
                val name = item.optString("name", "")
                if (id <= 0 || name.isBlank()) null else CaptureCategory(id, name)
            }
        } catch (_: JSONException) {
            emptyList()
        }
    }
}
