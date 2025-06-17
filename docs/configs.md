# Configs.md

Config files need to be set for each pipeline run

## config.yaml
* experiment_name:
* GRCh38_path: 
* difficult_regions_path: 
* common_variants_path: 
* ex_samples_path: 
* ms_samples_path: 
* ex_adapters_path: 
* ms_adaptor_1: 
* ms_adaptor_2: 

## ms_samples.csv
* ms_sample
* fastq1
* fastq2

## ex_samples.csv
* ex_sample
* ex_lane 
* adapter
* ms_sample
* fastq1
* fastq2

## ex_adapters.csv
* adapter
* r1start
* r1end
* r2start
* r2end

## download_list.csv (optional)
A list of all files to be downloaded. Works in conjunction with 'utils/download_S3toEC2.py'.
* file_name
* source_dir
* destination_dir