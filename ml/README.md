# ML Dataset Generation

This directory contains scripts and tools for generating ML training datasets from the app's learning logs.

## Files

- `generate_dataset.py` - Python script to export learning_log table to JSONL format
- `README.md` - This file

## Usage

### Generate Dataset

To generate a JSONL dataset from the learning_log table:

```bash
python generate_dataset.py
```

Or specify custom paths:

```bash
python generate_dataset.py <database_path> <output_path>
```

#### Default Paths

- Database: `../build/app_flutter/app_flutter.db` (Flutter build database)
- Output: `learning_dataset.jsonl`

#### Example

```bash
python generate_dataset.py ../build/app_flutter/app_flutter.jsonl
```

## Output Format

The output is in JSONL (JSON Lines) format, with one JSON object per line. Each entry contains:

```json
{
  "id": 1,
  "input_text": "makan siang 50rb",
  "action": {
    "amount": 50000,
    "type": "expense",
    "walletId": 1,
    "categoryId": 1,
    "note": "makan siang",
    "merchant": null,
    "excludeFromTarget": false,
    "createdAt": "2023-01-01T12:00:00"
  },
  "outcome": "accepted",
  "created_at": "2023-01-01T12:00:00"
}
```

## Notes

- The script requires Python 3.x and the `sqlite3` module (built-in)
- Database path should point to the Flutter app's database (usually in `build/app_flutter/`)
- The script handles JSON parsing of the action field and falls back to empty dict on errors
- All entries are ordered by ID (chronological order)
- Output encoding is UTF-8 to support Indonesian text

## Integration

This script is intended for offline use and is not part of the Flutter app. It should be run separately when you want to export learning data for ML model training or analysis.