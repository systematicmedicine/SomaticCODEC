"""
--- get_metadata.py --

Helper functions for loading metadata

Authors:
    - Chat-GPT
    - Cameron Fraser
"""

import pandas as pd
import yaml

""" Get ex sample ids"""
def get_ex_sample_ids(config):
    metadata = load_metadata(config)
    return metadata["ex_samples"]["ex_sample"].dropna().unique().tolist()

""" Get ex lane ids"""
def get_ex_lane_ids(config):
    metadata = load_metadata(config)
    return metadata["ex_lanes"]["ex_lane"].dropna().unique().tolist()

""" Get ms sample ids"""
def get_ms_sample_ids(config):
    metadata = load_metadata(config)
    return metadata["ms_samples"]["ms_sample"].dropna().unique().tolist()

""" Load sample metadata into dictionary """
def load_metadata(config):

    metadata = {}

    metadata["ex_samples"] = pd.read_csv(config["ex_samples_path"])
    metadata["ms_samples"] = pd.read_csv(config["ms_samples_path"])
    metadata["ex_lanes"] = pd.read_csv(config["ex_lanes_path"])
    metadata["ex_adapters"] = pd.read_csv(config["ex_adapters_path"])

    return metadata

"""Load the Snakemake config.yaml file.""" 
def load_config(path="config/config.yaml"):
       
    with open(path, "r") as f:
        return yaml.safe_load(f)