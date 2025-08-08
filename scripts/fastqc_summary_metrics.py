"""
--- fastqc_summary_metrics.py ---

Generates a summary file with key fastqc metrics

To be used with all rules that generate fastqc reports

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import pandas as pd
import glob
import json

# Initiate logging
sys.stdout = open(snakemake.log[0], "a")
sys.stderr = open(snakemake.log[0], "a")
print("[INFO] Starting fastqc_summary_metrics.py")

# Parses fastqc_data.txt into a dictionary of dataframes
def parse_fastqc_data(file_path):
    modules = {}
    with open(file_path) as f:
        lines = [line.strip() for line in f]

    i = 0
    while i < len(lines):
        if lines[i].startswith(">>") and not lines[i].startswith(">>END_MODULE"):
            module_name = lines[i].split("\t")[0][2:]
            i += 1
            header, data = None, []
            while i < len(lines) and not lines[i].startswith(">>END_MODULE"):
                line = lines[i]
                if line.startswith("#"):
                    header = line.lstrip("#").split("\t")
                elif line:
                    data.append(line.split("\t"))
                i += 1
            if header and data:
                modules[module_name] = pd.DataFrame(data, columns=header)
        i += 1
    return modules

# Load sample name
sample = snakemake.params.sample

fastqc_file_paths = glob.glob(f"metrics/{sample}/*fastqc*.txt")

# For each fastqc_data file, pull out key metrics and output in json
for file_path in fastqc_file_paths:
        
    output_json = file_path.replace(".txt", "_summary.json") 

    modules = parse_fastqc_data(file_path)

    total_reads = int(modules["Basic Statistics"].set_index("Measure").loc["Total Sequences", "Value"])
    per_sequence_quality = round(float(modules["Per sequence quality scores"]["Quality"].astype(float).mode()[0]), 2)
    per_base_quality = round(float(modules["Per base sequence quality"]["Lower Quartile"].astype(float).min()), 2)
    per_tile_quality = round(100 * (modules["Per tile sequence quality"]["Mean"].astype(float) < 36).mean(), 2)
    read_length = int(modules["Sequence Length Distribution"].sort_values("Count", ascending=False)["Length"].iloc[0].split('-')[0])
    overrepresented_sequences = round(float(modules["Overrepresented sequences"]["Percentage"].astype(float).max()) if "Overrepresented sequences" in modules and not modules["Overrepresented sequences"].empty else 0.0, 2)
    gc_deviation = round(((modules["Per sequence GC content"]["Count"].astype(float).sum() - modules["Per sequence GC content"]["Count"].astype(float).max()) / modules["Per sequence GC content"]["Count"].astype(float).sum()) * 100, 2)
    per_base_content_diff = round(modules["Per base sequence content"][["A", "T", "C", "G"]].astype(float).pipe(lambda df: ((df["A"] - df["T"]).abs().combine((df["C"] - df["G"]).abs(), max))).max(), 2)
    per_base_N_content = round(float(modules["Per base N content"]["N-Count"].astype(float).max()), 2)


    result = {
    "description": (
        "Summary of key metrics from fastqc report (see component metrics csv for definitions)"
    ),
    "sample": sample,
    "fastqc_file": file_path,
    "total_reads": total_reads,
    "per_sequence_quality": per_sequence_quality,
    "per_base_quality": per_base_quality,
    "per_tile_quality": per_tile_quality,
    "read_length": read_length,
    "overrepresented_sequences": overrepresented_sequences,
    "gc_deviation": gc_deviation,
    "per_base_content_diff": per_base_content_diff,
    "per_base_N_content": per_base_N_content
    }

    with open(output_json, 'w') as f:
        json.dump(result, f, indent=4)

print("[INFO] Completed fastqc_summary_metrics.py")








