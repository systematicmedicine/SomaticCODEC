"""
--- collate_benchmarks.py

Searches for all benchmark files, and conbines them into a single CSV

Designed to be used exclusively with the rule "collate_benchmarks"

Authors:
    - Chat-GPT
    - Cameron Fraser

"""

import pandas as pd
from pathlib import Path

# Resolve the script's directory and logs directory
script_dir = Path(__file__).resolve().parent
logs_dir = script_dir.parent / "logs"

# Match all *.benchmark.txt files
benchmark_files = list(logs_dir.rglob("*.benchmark.txt"))

df_list = []
for file in benchmark_files:
    try:
        # Read benchmark file
        df = pd.read_csv(file, sep=r"\s+", engine="python")

        # Rule name: file stem before '.benchmark.txt'
        rule_name = file.name.replace(".benchmark.txt", "")

        # Scope: name of immediate subdirectory of /logs/, or "global" if directly in /logs/
        try:
            relative_parts = file.relative_to(logs_dir).parts
            scope = relative_parts[0] if len(relative_parts) > 1 else "global"
        except ValueError:
            scope = "global"

        # Source (full relative path from project root)
        source = str(file.relative_to(script_dir.parent))

        # Add metadata columns
        df.insert(0, "rule", rule_name)
        df.insert(1, "scope", scope)
        df["source"] = source

        df_list.append(df)
    except Exception as e:
        print(f"Warning: Failed to read {file}: {e}")

# Combine and write output
if df_list:
    combined_df = pd.concat(df_list, ignore_index=True)
    output_file = Path(snakemake.output.file_path)
    combined_df.to_csv(output_file, index=False)
    print(f"Wrote combined benchmarks to {output_file} with {len(combined_df)} entries.")
else:
    print("No benchmark files found or successfully read.")
