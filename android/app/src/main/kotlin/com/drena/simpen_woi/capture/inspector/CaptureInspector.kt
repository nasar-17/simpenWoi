package com.drena.simpen_woi.capture.inspector

import android.content.Context
import android.content.SharedPreferences
import com.drena.simpen_woi.capture.parser.CaptureDetection
import com.drena.simpen_woi.capture.parser.CaptureSkipReason
import com.drena.simpen_woi.capture.prefs.CapturePreferences
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

data class InspectorEntry(
    val time: Long,
    val packageName: String,
    val title: String?,
    val text: String?,
    val bigText: String?,
    val result: String,
)

data class ListenerStatus(
    val connected: Boolean,
    val updatedAt: Long,
    val inspectorEnabled: Boolean,
)

object CaptureInspector {
    private const val KEY_ENABLED = "inspector_enabled"
    private const val KEY_LOG = "inspector_log"
    private const val KEY_LISTENER_CONNECTED = "listener_connected"
    private const val KEY_LISTENER_UPDATED_AT = "listener_updated_at"
    private const val MAX_ENTRIES = 50

    fun isEnabled(context: Context): Boolean {
        return prefs(context).getBoolean(KEY_ENABLED, false)
    }

    fun setEnabled(context: Context, enabled: Boolean) {
        prefs(context).edit().putBoolean(KEY_ENABLED, enabled).apply()
    }

    fun record(context: Context, entry: InspectorEntry) {
        if (!isEnabled(context)) return
        val entries = readEntries(context)
        entries.add(0, toJson(entry))
        while (entries.size > MAX_ENTRIES) {
            entries.removeAt(entries.lastIndex)
        }
        val array = JSONArray()
        entries.forEach { array.put(it) }
        prefs(context).edit().putString(KEY_LOG, array.toString()).apply()
    }

    fun getLog(context: Context): List<InspectorEntry> {
        return readEntries(context).mapNotNull { item ->
            val packageName = item.optString("package", "")
            if (packageName.isBlank()) return@mapNotNull null
            InspectorEntry(
                time = item.optLong("time", 0L),
                packageName = packageName,
                title = nullableString(item, "title"),
                text = nullableString(item, "text"),
                bigText = nullableString(item, "big_text"),
                result = item.optString("result", ""),
            )
        }
    }

    fun clear(context: Context) {
        prefs(context).edit().remove(KEY_LOG).apply()
    }

    fun updateListenerStatus(context: Context, connected: Boolean) {
        prefs(context).edit()
            .putBoolean(KEY_LISTENER_CONNECTED, connected)
            .putLong(KEY_LISTENER_UPDATED_AT, System.currentTimeMillis())
            .apply()
    }

    fun getListenerStatus(context: Context): ListenerStatus {
        val preferences = prefs(context)
        return ListenerStatus(
            connected = preferences.getBoolean(KEY_LISTENER_CONNECTED, false),
            updatedAt = preferences.getLong(KEY_LISTENER_UPDATED_AT, 0L),
            inspectorEnabled = isEnabled(context),
        )
    }

    fun resultFor(detection: CaptureDetection, duplicate: Boolean = false): String {
        if (duplicate) {
            return "Dilewati: ${CaptureSkipReason.DUPLICATE.label}"
        }
        return when (detection) {
            is CaptureDetection.Captured -> {
                "Ditangkap (${detection.amount}, ${detection.merchant ?: "-"})"
            }

            is CaptureDetection.Skipped -> "Dilewati: ${detection.reason.label}"
        }
    }

    private fun prefs(context: Context): SharedPreferences {
        return context.applicationContext.getSharedPreferences(
            CapturePreferences.PREFS_NAME,
            Context.MODE_PRIVATE,
        )
    }

    private fun readEntries(context: Context): MutableList<JSONObject> {
        val raw = prefs(context).getString(KEY_LOG, null) ?: return mutableListOf()
        return try {
            val array = JSONArray(raw)
            MutableList(array.length()) { index -> array.getJSONObject(index) }
        } catch (_: JSONException) {
            mutableListOf()
        }
    }

    private fun toJson(entry: InspectorEntry): JSONObject {
        return JSONObject()
            .put("time", entry.time)
            .put("package", entry.packageName)
            .put("title", entry.title ?: JSONObject.NULL)
            .put("text", entry.text ?: JSONObject.NULL)
            .put("big_text", entry.bigText ?: JSONObject.NULL)
            .put("result", entry.result)
    }

    private fun nullableString(item: JSONObject, key: String): String? {
        if (!item.has(key) || item.isNull(key)) return null
        return item.optString(key)
    }
}

fun InspectorEntry.toInspectorMap(): Map<String, Any?> {
    return mapOf(
        "time" to time,
        "package" to packageName,
        "title" to title,
        "text" to text,
        "big_text" to bigText,
        "result" to result,
    )
}

fun ListenerStatus.toListenerStatusMap(): Map<String, Any?> {
    return mapOf(
        "connected" to connected,
        "updated_at" to updatedAt,
        "inspector_enabled" to inspectorEnabled,
    )
}
