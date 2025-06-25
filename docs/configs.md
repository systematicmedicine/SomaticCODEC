# configs.md

This document provides guidance on configuring the config files required to run the codec-opensource pipeline.

## config.yaml
This is the master configuration file for the codec-opesource pipeline.  

* experiment_name
    * Optional parameter, used by <I>utils/tar_output.py</I>
    * e.g. `Candidate 0764 pilot`
* ms_adaptor_1
    * Sequenced used for adaptor trimming of matched samples. Will vary based on library preparation.
    * e.g. `CTGTCTCTTATACACATCT`
* ms_adaptor_2
    * Sequenced used for adaptor trimming of matched samples. Will vary based on library preparation.
    * e.g. `ATGTGTATAAGAGACA`
* GRCh38_path
    * Path to reference genome FASTA (e.g. GRCh38)
    * e.g. `tmp/downloads/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna`
* difficult_regions_path
    * Path to BED file with regions you want to mask
    * e.g. `tmp/downloads/GRCh38_alldifficultregions.bed`
* common_variants_path
    * Path to BED file with regions you want to mask
    * e.g. `tmp/downloads/gnomad_common_af01_merged.bed`

The configuration file also contains paths to other configuration files (e.g. ex_sample_path). Do not modify these paths.

## ex_samples.csv
Defines the experimental samples (the samples we want to call somatic variants for)

* ex_sample
    * Assign a name for each sample
    * Must be unique, and not the same as any ms_samples
    * e.g. `S001`
* lane
    * In a typical CODEC workflow, multiple samples are sequenced per flow cell lane
    * A pair of FASTQ files will be generated for each lane, which will typically contain multiple samples
    * This variable defines which lane we expect each sample to belong to
    * Must match a lane defined in ex_lanes.csv
    * E.g. `Lane1`

* adapter
    * The name of the adaptor associated with this sample
    * Must match an adapter defined in ex_adapters.csv
    * e.g. `Quadraplex01`
* ms_sample
    * Each experimental has a corresponding matched sample from the same donor
    * This is used to used to differentiate germline from somatic variants. Pipeline does not support "tumor only" mode.
    * Multiple experimental samples can use the same matched sample (e.g. multiple experimental samples from the same donor)
    * Must match a ms_sample defined in ms_samples.csv
    * e.g. `S013`

## ex_lanes.csv
Defines the lanes used in the experiment (see <I>lane</I> concept described above)

* ex_lane
    * Assign a name for each lane
    * Must be unique, otherwise can take any value
    * Lane specific metrics files will be output to a directory with this name
    * E.g. `Lane1`
* fastq1
    * Local path to the FASTQ file containing R1
    * e.g. `tmp/downloads/QAGRF25050474_22THKGLT4_NoIndex_L006_R1.fastq.gz`
* fastq2
    * Local path to the FASTQ file containing R2
    * e.g. `tmp/downloads/QAGRF25050474_22THKGLT4_NoIndex_L006_R2.fastq.gz`

## ex_adapters.csv
Defines the CODEC adapters used for experimental samples. Note that multiple samples may use the same adapters (if they are in different lanes).

* adapter
    * Assign a name for each adapter
    * Must be unique, otherwise can take any value
    * e.g. `Quadraplex01`
* r1start
    * Sequence for the read 1 sample index
    * e.g. `CTTGAACGGACTGTCCAC`
* r1end
    * Reverse complement of ...
    * e.g. `GTAGTCTAACGCTCGGTG`
* r2start
    * Sequence for the read 2 sample index
    * e.g. `CACCGAGCGTTAGACTAC`
* r2end
    * Reverse complement of ...
    * e.g. `GTGGACAGTCCGTTCAA`

## ms_samples.csv
Defines the matched samples used to differentiate between germline and somatic varants

* ms_sample: 
    * Assign a name for each sample
    * Must be unique, and not the same as any ex_samples
    * e.g. `S013`
* fastq1
    * Local path to the FASTQ file containing R1
    * e.g. `tmp/downloads/Buffy-young_232KFGLT3_TGATGTAAGA-GTGCGTCCTT_r1.fastq.gz`
* fastq2
    * Local path to the FASTQ file containing R2
    * e.g. `tmp/downloads/Buffy-young_232KFGLT3_TGATGTAAGA-GTGCGTCCTT_r2.fastq.gz`

## download_list.csv (optional)
Defines a list of all files to be downloaded. For use in conjunction with <I>utils/download_S3toEC2.py</I>.

* file_name
    * Name of the file to be downloaded
    * e.g. `GCA_000001405.15_GRCh38_no_alt_analysis_set.fna`
* source_dir
    * The directory within the source filesystem where this file is located
    * e.g. `s3://sysmed-ref-s3/reference-files/`
* destination_dir
    * The directory within the destination file system where this file will be downloaded to
    * e.g. `tmp/downloads`