# ML Dataset Generation

This directory contains optional tooling for exporting the app's `learning_log`
data for analysis or model training. It is not part of the Flutter app and never
runs automatically.

## Export from the app (recommended)

Open **Pengaturan > Pembelajaran > Ekspor log pembelajaran** and choose a
`.jsonl` destination. The app writes one JSON object per line:

```json
{
  "id": 1,
  "input_text": "makan siang 50rb",
  "action_json": "{\"type\":\"add_transaction\",\"amount\":50000}",
  "outcome": "accepted",
  "created_at": "2023-01-01T12:00:00.000"
}
```

`action_json` is a JSON string, not an object.

## Export with the Python script

Use this only when you have a copy of the SQLite database:

```bash
python ml/generate_dataset.py <database_path> <output_path>
```

Example:

```bash
python ml/generate_dataset.py learning.db learning_dataset.jsonl
```

The script parses `action_json` into an `action` object:

```json
{
  "id": 1,
  "input_text": "makan siang 50rb",
  "action": {
    "type": "add_transaction",
    "amount": 50000
  },
  "outcome": "accepted",
  "created_at": "2023-01-01T12:00:00"
}
```

The default path in the script (`../build/app_flutter/app_flutter.db`) is only a
development fallback. It is usually not valid for an Android install, so pass
the database path explicitly.

## Notes

- Requires Python 3.x and the built-in `sqlite3` module.
- Output is UTF-8 and ordered by `learning_log.id`.
- The script is offline-only and makes no network requests.
- The app export is preferred because it does not require locating the private
  app database.
