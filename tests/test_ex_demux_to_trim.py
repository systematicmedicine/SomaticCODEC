"""
--- test_ex_demux_to_trim.py ---

Test demultiplexing and trimming steps for CODECseq experimental pipeline.

Author: James Phie
"""

import subprocess
import json
from pathlib import Path
import pandas as pd
import gzip


def run_pipeline():
    snakemake_cmd = [
        "snakemake",
        "-s", "tests/snakefiles/Snakefile_test_ex_demux_to_trim",
        "--cores", "all",
        "--configfile", "tests/configs/test_ex_demux_to_trim_config.yaml",
        "--notemp",
        "--forceall",
        "--rerun-incomplete"
    ]
    subprocess.run(snakemake_cmd, check=True)


def extract_first_3_bases_from_fastq(fq_path):
    with gzip.open(fq_path, "rt") as f:
        bases = []
        for _ in range(3):  # 3 read pairs
            f.readline()  # name
            seq = f.readline().strip()
            f.readline(); f.readline()  # + and qual
            bases.append(seq[:3])
        return bases


def get_adapter_counts(metrics, sample):
    r1_count = next((a["total_matches"] for a in metrics["adapters_read1"] if a["name"] == sample), 0)
    r2_count = next((a["total_matches"] for a in metrics["adapters_read2"] if a["name"] == sample), 0)
    return r1_count, r2_count


def test_ex_demux_trim_output(clean_workspace_fixture):
    run_pipeline()

    ex_samples_df = pd.read_csv("tests/configs/test_ex_demux_trim_exsamples.csv")
    ex_lanes_df = pd.read_csv("tests/configs/test_ex_demux_trim_exlanes.csv")
    ex_lane_to_sample = ex_samples_df.groupby("lane")["ex_sample"].apply(list).to_dict()

    for lane, samples in ex_lane_to_sample.items():
        demux_json_path = Path(f"metrics/{lane}/{lane}_demux_metrics.json")
        assert demux_json_path.exists(), f"Demux metrics JSON not found: {demux_json_path}"
        with open(demux_json_path) as f:
            demux_metrics = json.load(f)

# Validate that S001, S003 and S004 are present exactly once after demultiplexing
        for sample in ["S001", "S003", "S004"]:
            r1_count, r2_count = get_adapter_counts(demux_metrics, sample)
            assert r1_count == 1, f"{sample} should have 1 R1 read, got {r1_count}"
            assert r2_count == 1, f"{sample} should have 1 R2 read, got {r2_count}"
        r1_count, r2_count = get_adapter_counts(demux_metrics, "S002")
        assert r1_count == 0, f"S002 should have 0 R1 reads, got {r1_count}"
        assert r2_count == 0, f"S002 should have 0 R2 reads, got {r2_count}"

        raw_r1_path = "tests/data/ex_demux_trim_r1.fastq.gz"
        raw_r2_path = "tests/data/ex_demux_trim_r2.fastq.gz"
        umi_r1_list = extract_first_3_bases_from_fastq(raw_r1_path)
        umi_r2_list = extract_first_3_bases_from_fastq(raw_r2_path)
        umi_expected_list = [r1 + r2 for r1, r2 in zip(umi_r1_list, umi_r2_list)]

        umi_r1_path = f"tmp/{lane}/{lane}_r1_umi_extracted.fastq.gz"
        umi_r2_path = f"tmp/{lane}/{lane}_r2_umi_extracted.fastq.gz"

# Validate that the 6bp umi created from 3bp R1 and 3bp R2 is appended to the readname of both R1 and R2
        with gzip.open(umi_r1_path, "rt") as f1, gzip.open(umi_r2_path, "rt") as f2:
            for i in range(3):
                r1_name = f1.readline().strip()
                f1.readline(); f1.readline(); f1.readline()
                r2_name = f2.readline().strip()
                f2.readline(); f2.readline(); f2.readline()

                umi_expected = umi_expected_list[i]
                r1_umi = r1_name.split(":")[-1]
                r2_umi = r2_name.split(":")[-1]

                assert r1_umi == umi_expected, f"R1 read {i+1} UMI mismatch: expected {umi_expected}, got {r1_umi}"
                assert r2_umi == umi_expected, f"R2 read {i+1} UMI mismatch: expected {umi_expected}, got {r2_umi}"
                assert len(r1_umi) == 6, f"R1 read {i+1} UMI length != 6: {r1_umi}"

    # Validate S003 R2 3' adapter trimming occurs in exactly one read, and 2bp of the read are remaining after the trim
    r2_3prime_json_path = Path("metrics/S003/S003_r2_trim_3prime_metrics.json")
    assert r2_3prime_json_path.exists(), "S003 R2 3' trim metrics JSON not found"
    with open(r2_3prime_json_path) as f:
        r2_trim_metrics = json.load(f)

    r2_matches = r2_trim_metrics["adapters_read1"][0]["three_prime_end"]["matches"]
    assert r2_matches == 1, f"S003 R2 3' adapter should have matched once, got {r2_matches}"

    r2_output_bases = r2_trim_metrics["basepair_counts"]["output_read1"]
    assert r2_output_bases == 2, f"S003 R2 output after 3' trimming should be 2 bp, got {r2_output_bases}"

    # Validate S003 filtering removed the short R2 read assessed above
    filter_json_path = Path("metrics/S003/S003_filter_metrics.json")
    assert filter_json_path.exists(), "S003 filter metrics JSON not found"
    with open(filter_json_path) as f:
        filter_metrics = json.load(f)

    short_filtered = filter_metrics["read_counts"]["filtered"].get("too_short", 0)
    assert short_filtered == 1, f"S003 should have 1 read filtered, got {short_filtered}"