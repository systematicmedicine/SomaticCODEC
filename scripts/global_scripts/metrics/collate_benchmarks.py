#!/usr/bin/env python3
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
import sys
from datetime import timedelta
import re
import argparse
import os

def main(args):

    # Redirect stdout and stderr to the Snakemake log file
    sys.stdout = open(args.log, "a")
    sys.stderr = open(args.log, "a")

    # Define logs directory
    logs_dir = Path("logs")

    # Match all *.benchmark.txt files
    benchmark_files = list(logs_dir.rglob("*.benchmark.txt"))

    expected_columns = [
        "s", "h:m:s", "max_rss", "max_vms", "max_uss",
        "max_pss", "io_in", "io_out", "mean_load", "cpu_time"
    ]

    def parse_duration_to_seconds(s):
        """Parses a string like '2 days, 5:38:03' or '5:38:03' into total seconds."""
        try:
            s = s.strip()
            match = re.match(r"(?:(\d+)\s+days?,\s+)?(\d+):(\d+):(\d+)", s)
            if not match:
                return float("nan")
            days = int(match.group(1)) if match.group(1) else 0
            hours = int(match.group(2))
            minutes = int(match.group(3))
            seconds = int(match.group(4))
            td = timedelta(days=days, hours=hours, minutes=minutes, seconds=seconds)
            return td.total_seconds()
        except Exception:
            return float("nan")

    df_list = []
    for file in benchmark_files:
        try:
            with open(file, "r") as f:
                lines = f.readlines()

            # Skip empty or malformed files
            if len(lines) < 2:
                raise ValueError("Benchmark file has no data.")

            # Parse header
            header = lines[0].strip().split()
            if header != expected_columns:
                print(f"Warning: Unexpected header in {file}: {header}")

            parsed_rows = []
            for line in lines[1:]:
                parts = line.strip().split()

                if len(parts) > 10:
                    try:
                        s_value = parts[0]

                        # find the first token that looks like hh:mm:ss
                        for i, token in enumerate(parts[1:], start=1):
                            if ":" in token:
                                time_str = " ".join(parts[1:i]) + " " + token if i > 1 else token
                                rest = parts[i+1:]
                                break
                        else:
                            raise ValueError("Could not parse h:m:s field")

                        row = [s_value, time_str] + rest
                    except Exception as e:
                        print(f"Warning: Failed to parse row in {file}: {line.strip()} -- {e}")
                        continue
                else:
                    row = parts

                if len(row) != 10:
                    print(f"Warning: Skipping malformed row in {file}: {row}")
                    continue

                parsed_rows.append(row)

            df = pd.DataFrame(parsed_rows, columns=expected_columns)

            # Convert numeric columns
            for col in ["s", "max_rss", "max_vms", "max_uss", "max_pss", "io_in", "io_out", "mean_load", "cpu_time"]:
                df[col] = pd.to_numeric(df[col], errors="coerce")

            # Optionally: parse h:m:s to duration in seconds
            df["parsed_duration_s"] = df["h:m:s"].apply(parse_duration_to_seconds)

            # Rule name and scope
            rule_name = file.name.replace(".benchmark.txt", "")
            try:
                relative_parts = file.relative_to(logs_dir).parts
                scope = relative_parts[0] if len(relative_parts) > 1 else "global"
            except ValueError:
                scope = "global"
            source = os.path.relpath(file, Path.cwd())

            df.insert(0, "rule", rule_name)
            df.insert(1, "scope", scope)
            df["source"] = source

            df_list.append(df)

        except Exception as e:
            print(f"Warning: Failed to read {file}: {e}")

    # Combine and write output
    if df_list:
        combined_df = pd.concat(df_list, ignore_index=True)
        output_file = Path(args.combined_benchmarks)
        combined_df.to_csv(output_file, index=False)
        print(f"Wrote combined benchmarks to {output_file} with {len(combined_df)} entries.")
    else:
        raise RuntimeError("No benchmark files found or successfully read.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--combined_benchmarks", required=True)
    parser.add_argument("--log", required=True)
    args = parser.parse_args()
    main(args=args)
