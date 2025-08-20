"""
--- get_metadata.py --

Helper functions for loading metadata

Authors:
    - Chat-GPT
    - Cameron Fraser
"""

import pandas as pd
import yaml


""" 
Returns a list of ex sample ids 
"""
def get_ex_sample_ids(config):
    metadata = load_metadata(config)
    return metadata["ex_samples"]["ex_sample"].dropna().unique().tolist()


""" 
Returns a list of ex lane ids
"""
def get_ex_lane_ids(config):
    metadata = load_metadata(config)
    return metadata["ex_lanes"]["ex_lane"].dropna().unique().tolist()


""" 
Returns a list of ms sample ids
"""
def get_ms_sample_ids(config):
    metadata = load_metadata(config)
    return metadata["ms_samples"]["ms_sample"].dropna().unique().tolist()


""" 
Returns a nested dictionary mapping ex_lane, ex_sample and region to an adapter sequence
    dict[ex_lane][ex_sample][region] -> adapter sequence
"""
def get_ex_lane_adapter_dict(config):
    metadata = load_metadata(config)
    ex_samples = metadata["ex_samples"]
    ex_adapters = metadata["ex_adapters"].set_index("ex_adapter")

    nested_dict = {}

    for _, row in ex_samples.iterrows():
        lane = row["ex_lane"]
        sample = row["ex_sample"]
        adapter = row["ex_adapter"]

        if lane not in nested_dict:
            nested_dict[lane] = {}

        nested_dict[lane][sample] = {
            region: ex_adapters.loc[adapter, region]
            for region in ["r1_start", "r1_end", "r2_start", "r2_end"]
        }

    return nested_dict


"""
Returns a nested dictionary mapping ex_sample and region to an adapter sequence
    dict[ex_sample][region] -> adapter sequence
"""
def get_ex_sample_adapter_dict(config):
    metadata = load_metadata(config)

    ex_samples = metadata["ex_samples"]
    ex_adapters = metadata["ex_adapters"]

    # Merge ex_samples with adapter sequences using the adapter name
    merged = ex_samples[["ex_sample", "ex_adapter"]].merge(
        ex_adapters,
        how="left",
        on="ex_adapter"
    )

    # Build the nested dictionary
    sample_adapter_dict = {}
    for _, row in merged.iterrows():
        sample = row["ex_sample"]
        sample_adapter_dict[sample] = {
            "r1_start": row["r1_start"],
            "r1_end": row["r1_end"],
            "r2_start": row["r2_start"],
            "r2_end": row["r2_end"]
        }

    return sample_adapter_dict


"""
Returns a dictionary mapping ex_lane to FASTQ file paths
    dict[ex_lane] -> (fastq1_path, fastq2_path)
"""
def get_ex_lane_fastqs(config):
    metadata = load_metadata(config)
    df = metadata["ex_lanes"]
    return {
        row["ex_lane"]: (row["fastq1"], row["fastq2"])
        for _, row in df.iterrows()
    }


"""
Returns a dictionary mapping ex_lane to ex_sample
    dict[ex_lane] -> list(ex_samples)
"""
def get_ex_lane_samples(config):
    metadata = load_metadata(config)
    df = metadata["ex_samples"]

    return (
        df.groupby("ex_lane")["ex_sample"]
        .apply(list)
        .to_dict()
    )


"""
Returns a dictionary mapping ex_sample to its corresponding ms_sample
    dict[ex_sample] -> ms_sample
"""
def get_ex_to_ms_sample_map(config):
    df = load_metadata(config)["ex_samples"]
    return dict(zip(df["ex_sample"], df["ms_sample"]))


"""
Returns a dictionary mapping ex_sample to its corresponding donor_id
    dict[ex_sample] -> donor_id
"""
def get_ex_to_donor_id_map(config):
    df = load_metadata(config)["ex_samples"]
    return dict(zip(df["ex_sample"], df["donor_id"]))


"""
Returns a dictionary mapping ms_sample to its corresponding donor_id
    dict[ms_sample] -> donor_id
"""
def get_ms_to_donor_id_map(config):
    df = load_metadata(config)["ms_samples"]
    return dict(zip(df["ms_sample"], df["donor_id"]))


"""
Returns a dictionary mapping ex_sample to its corresponding age
    dict[ex_sample] -> age
"""
def get_ex_to_age_map(config):
    df = load_metadata(config)["ex_samples"]
    return dict(zip(df["ex_sample"], df["age"]))


"""
Returns a dictionary mapping ms_sample to its corresponding age
    dict[ms_sample] -> age
"""
def get_ms_to_age_map(config):
    df = load_metadata(config)["ms_samples"]
    return dict(zip(df["ms_sample"], df["age"]))


"""
Returns a dictionary mapping ex_sample to its corresponding sample_type
    dict[ex_sample] -> sample_type
"""
def get_ex_to_sample_type_map(config):
    df = load_metadata(config)["ex_samples"]
    return dict(zip(df["ex_sample"], df["ex_sample_type"]))


"""
Returns a dictionary mapping ms_sample to its corresponding sample_type
    dict[ms_sample] -> sample_type
"""
def get_ms_to_sample_type_map(config):
    df = load_metadata(config)["ms_samples"]
    return dict(zip(df["ms_sample"], df["ms_sample_type"]))


"""
Returns a dictionary mapping ms_sample to its corresponding ms_sample_type in ex_samples.csv
    dict[ms_sample] -> ms_sample_type
"""
def get_ms_to_sample_type_in_ex_samples_csv_map(config):
    df = load_metadata(config)["ms_samples"]
    return dict(zip(df["ms_sample"], df["ms_sample_type"]))


"""
Returns a dictionary mapping ms_sample to its FASTQ file paths
    dict[ms_sample] -> (fastq1_path, fastq2_path)
"""
def get_ms_sample_fastqs(config):
    metadata = load_metadata(config)
    df = metadata["ms_samples"]

    return {
        row["ms_sample"]: (row["fastq1"], row["fastq2"])
        for _, row in df.iterrows()
    }


""" 
Load sample metadata from CSV files into dictionary 
"""
def load_metadata(config):

    metadata = {}

    metadata["ex_samples"] = pd.read_csv(config["ex_samples_path"])
    metadata["ms_samples"] = pd.read_csv(config["ms_samples_path"])
    metadata["ex_lanes"] = pd.read_csv(config["ex_lanes_path"])
    metadata["ex_adapters"] = pd.read_csv(config["ex_adapters_path"])

    return metadata


"""
Load the Snakemake config.yaml file
""" 
def load_config(path="config/config.yaml"):
    with open(path, "r") as f:
        return yaml.safe_load(f)