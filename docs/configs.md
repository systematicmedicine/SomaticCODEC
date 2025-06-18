# Configs.md

Config files need to be set for each pipeline run

## config.yaml
* experiment_name
    * Used for naming the tar file containing all your outputs (optional)
* GRCh38_path
    * Path to reference genome FASTA (e.g. GRCh38)
* difficult_regions_path
    * Path to BED file with regions you want to mask
* common_variants_path
    * Path to BED file with regions you want to mask
* ex_samples_path
    * path to ex_samples.csv
* ms_samples_path
    * path to ms_samples.csv
* ex_adapters_path
    * path to ex_adapters.csv
* ms_adaptor_1
    * .
* ms_adaptor_2
    * .

## ms_samples.csv
* ms_sample: 
    * Sample name
    * Must be unique
    * Must not be the same as an ex_sample
* fastq1
    * Local path to the FASTQ file containing R1
* fastq2
    * Local path to the FASTQ file containing R2

## ex_samples.csv
* ex_sample
    * Sample name
    * Must be unique
    * Must not be the same as a ms_sample
* ex_lane
    * Lane name
    * This pipeline assumes that FASTQ files of sequenced CODEC libraries are not demultiplexed by sequencing platform
    * All samples within a single lane on a flowcell are typically grouped together in a single pair of FASTQ files 
    * All samples within the same FASTQ file must have the same value for lane
* adapter
    * CODEC Adapter name
    * Must match an adapter name in ex_adapters.csv
* ms_sample
    * Name of sample from same donor used to determine germline variants
    * Must exist in ms_samples.csv
    * Pipeline cannot be run without this matched sample (e.g. "tumor only" mode)
* fastq1
    * Local path to the FASTQ file containing R1
* fastq2
    * Local path to the FASTQ file containing R2

## ex_adapters.csv
* adapter
    * Adapter name (must be unique)
* r1start
    * .
* r1end
    * .
* r2start
    * .
* r2end
    * .

## download_list.csv (optional)
A list of all files to be downloaded. Works in conjunction with 'utils/download_S3toEC2.py'.
* file_name
* source_dir
* destination_dir