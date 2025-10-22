"""
--- fastqc_summary_metrics.py ---

Generates a summary file with key fastqc metrics

To be used with all rules that generate fastqc reports

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import pandas as pd
from pathlib import Path
import json
import sys
import numpy as np, scipy.stats

def main(snakemake):
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

    # Load fastqc file paths
    fastqc_file_paths = snakemake.input.fastqc_files

    # For each fastqc_data file, pull out key metrics and output in json
    for file_path in fastqc_file_paths:
            
        file_path = Path(file_path)
        output_json = file_path.with_name(file_path.stem + "_summary.json")

        modules = parse_fastqc_data(file_path)

        total_reads = int(modules["Basic Statistics"].set_index("Measure").loc["Total Sequences", "Value"])

        per_sequence_quality = round(modules["Per sequence quality scores"].astype(float).loc[modules["Per sequence quality scores"].astype(float)["Count"].idxmax(), "Quality"], 2)

        per_base_quality = round(float(modules["Per base sequence quality"]["Lower Quartile"].astype(float).min()), 2)

        per_tile_quality = round(100 * modules["Per tile sequence quality"].assign(Mean=lambda df: df["Mean"].astype(float)).groupby("Tile")["Mean"].apply(lambda x: (x <= -5).any()).mean(), 2)

        read_length = int(modules["Sequence Length Distribution"].sort_values("Count", ascending=False)["Length"].iloc[0].split('-')[0])

        overrepresented_sequences = round(float(modules["Overrepresented sequences"]["Percentage"].astype(float).max()) if "Overrepresented sequences" in modules and not modules["Overrepresented sequences"].empty else 0.0, 2)

        gc_deviation = round(100 * (lambda b,c,n,m,s: np.abs(c - scipy.stats.norm.pdf(b,m,s)*n).sum() / n)(*(lambda df: (
        df.index.astype(float),
        df["Count"].values,
        df["Count"].sum(),
        np.average(df.index.astype(float), weights=df["Count"]),
        np.sqrt(np.average((df.index.astype(float) - np.average(df.index.astype(float), weights=df["Count"]))**2, weights=df["Count"]))))(modules["Per sequence GC content"].astype(float))), 2)

        per_base_content_diff = round(modules["Per base sequence content"][["A", "T", "C", "G"]].astype(float).pipe(lambda df: ((df["A"] - df["T"]).abs().combine((df["C"] - df["G"]).abs(), max))).max(), 2)

        per_base_N_content = round(float(modules["Per base N content"]["N-Count"].astype(float).max()), 2)

        result = {
        "description": (
            "Summary of key metrics from fastqc report",
            "Definitions:",
            "total_reads: Total raw reads obtained from standard Illumina sequencing (x million reads)",
            "per_sequence_quality: Peak in distribution of mean sequence quality across all reads (Phred score)",
            "per_base_quality: Minimum IQR lower quartile for base quality at any position in reads (Phred score)",
            "per_tile_quality: Percentage of flow cell tiles where mean quality score at any read position is >=5 less than the global mean quality for that position",
            "read_length: Peak of read length distribution (bp)",
            "overrepresented_sequences: Percentage of sequences made up by any one identical sequence",
            "gc_deviation: Percentage of reads deviating from a normal distribution for mean GC content",
            "per_base_content_diff: Percentage difference in the proportion of A/T or C/G at each position in reads",
            "per_base_N_content: Maximum percentage of bases recorded as N at any one position in reads"

        ),
        "sample": sample,
        "fastqc_file": str(file_path),
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

if __name__ == "__main__":
    main(snakemake)