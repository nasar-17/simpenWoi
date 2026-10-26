#!/usr/bin/env python3
"""
Generate JSONL dataset from learning_log table for ML training.
Usage: python generate_dataset.py
"""

import json
import sqlite3
import os
import sys

def export_learning_log_to_jsonl(db_path, output_path):
    """
    Export learning_log table to JSONL format.
    
    Args:
        db_path (str): Path to SQLite database
        output_path (str): Output JSONL file path
    """
    if not os.path.exists(db_path):
        print(f"Error: Database file not found: {db_path}")
        sys.exit(1)
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Query learning_log table
    cursor.execute("SELECT id, input_text, action_json, outcome, created_at FROM learning_log ORDER BY id")
    rows = cursor.fetchall()
    
    exported_count = 0
    with open(output_path, 'w', encoding='utf-8') as f:
        for row in rows:
            entry_id, input_text, action_json, outcome, created_at = row
            
            # Parse action JSON
            try:
                action_data = json.loads(action_json)
            except json.JSONDecodeError:
                action_data = {}
            
            # Create JSON entry
            entry = {
                "id": entry_id,
                "input_text": input_text,
                "action": action_data,
                "outcome": outcome,
                "created_at": created_at
            }
            
            # Write as JSON line
            f.write(json.dumps(entry, ensure_ascii=False) + "\n")
            exported_count += 1
    
    conn.close()
    print(f"Exported {exported_count} entries to {output_path}")

def main():
    # Default paths - adjust as needed
    db_path = "../build/app_flutter/app_flutter.db"
    output_path = "learning_dataset.jsonl"
    
    # Allow custom paths via command line
    if len(sys.argv) > 1:
        db_path = sys.argv[1]
    if len(sys.argv) > 2:
        output_path = sys.argv[2]
    
    print(f"Exporting from: {db_path}")
    print(f"Exporting to: {output_path}")
    
    export_learning_log_to_jsonl(db_path, output_path)

if __name__ == "__main__":
    main()