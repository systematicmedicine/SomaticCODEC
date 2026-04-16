# Preparing sample sheets

Download the following CSV files from `experiment/` and populate them for your experiment using the instructions below.

- ***experiment/ex_adapters.csv***: Defines the sequences for each CODEC adapter quadruplex.
- ***experiment/ex_lanes.csv***: Defines the sample ID and FASTQ files for each `ex_lane`.
- ***experiment/ex_samples.csv***: Defines the sample ID for each `ex_sample`, the `ex_lane` it derives from, and the `ms_sample` it pairs with.
- ***experiment/ms_samples.csv***: Defines the sample ID and FASTQ files for each `ms_sample`.
- ***experiment/ms_adapters.csv***: Defines the sequences for matched sample adapters.
- ***experiment/download_list.csv***: Optional. Only required if staging files using *bin/download_S3.py*.

### experiment/ex_adapters.csv

*experiment/ex_adapters.csv* contains the following fields:

- `ex_adapter`: A unique name assigned to each adapter quadruplex
- `r1_start`: The P5 adapter sequence
- `r1_end`: The P7 bridge sequence
- `r2_start`: The P7 adapter sequence
- `r2_end`: The P5 bridge sequence

Example using quadruplex 1 from [Bae *et al.* 2023](https://doi.org/10.1038/s41588-023-01376-0):

| ex_adapter | r1_start | r1_end | r2_start | r2_end |
|------------|----------|--------|----------|--------|
| QD001 | CTTGAACGGACTGTCCAC | GTAGTCTAACGCTCGGTG |CACCGAGCGTTAGACTAC | GTGGACAGTCCGTTCAAG |

### experiment/ex_lanes.csv

*experiment/ex_lanes.csv* contains the following fields:

- `ex_lane`: A unique ID assigned to each sequencing lane
- `fastq1`: The path to the R1 FASTQ for each lane
- `fastq2`: The path to the R2 FASTQ for each lane

Example:

| ex_lane | fastq1 | fastq2 |
|---------|--------|--------|
| LN001 | tmp/downloads/L001_R1.fastq.gz | tmp/downloads/L001_R2.fastq.gz |

### experiment/ex_samples.csv

*experiment/ex_samples.csv* contains the following fields:

- `ex_sample`: A unique ID assigned to each ex_sample following demultiplexing of the ex_lane
- `ex_lane`: The ex_lane ID for the sequencing lane that contains the ex_sample
- `ex_adapter`: The ex_adapter ID that will be used to identify the ex_sample during demultiplexing
- `ms_sample`: The ID of the matched sample that corresponds to the ex_sample
- `donor_id`: An ID shared between the ex_sample and the ms_sample to ensure a correct match
- `comments`: Optional. This field is intended to be user facing and is not used by the pipeline.

Example:

| ex_sample | ex_lane | ex_adapter | ms_sample | donor_id | comments |
|-----------|---------|------------|-----------|----------|----------|
| S001 | LN001 | QD001 | S002 | D001 | Blood 40M |

### experiment/ms_samples.csv

*experiment/ms_samples.csv* contains the following fields:

- `ms_sample`: A unique ID assigned to each matched sample
- `fastq1`: The path to the R1 FASTQ for each sample
- `fastq2`: The path to the R2 FASTQ for each sample
- `donor_id`: An ID shared between the ex_sample and the ms_sample to ensure a correct match
- `comments`: Optional. This field is intended to be user facing and is not used by the pipeline.

Example:

| ms_sample | fastq1 | fastq2 | donor_id | comments |
|-----------|--------|--------|----------|----------|
| S002 | tmp/downloads/Buffy_D001_Age43_R1.fastq.gz | tmp/downloads/Buffy_D001_Age43_R2.fastq.gz | D001 | Blood 40M |

### experiment/ms_adapters.csv

*experiment/ms_adapters.csv* contains the following fields:

- `ms_adapter_r1`: The expected adapter sequence for R1
- `ms_adapter_r2`: The expected adapter sequence for R2

Example:

| ms_adapter_r1 | ms_adapter_r2 |
|-----------------------------------|-----------------------------------|
| AGATCGGAAGAGCACACGTCTGAACTCCAGTCA | AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT |

### experiment/download_list.csv (optional)

*experiment/download_list.csv* contains the following fields:

A download list is only required if you are staging files using *bin/download_S3.py*.

- `file_name`: The name of the file to be downloaded
- `source_dir`: The absolute path to the file on S3
- `destination_dir`: The path to the destination directory (typically tmp/downloads)
- `expected_md5sum`: The md5sum of the file (checked after download)

Example:

| file_name | source_dir | destination_dir | expected_md5sum |
|-----------|------------|-----------------|-----------------|
| UCSC-GRCh38-p14-filtered.fa | s3://sm-unrestricted-public/somaticcodec/reference-data/refs-v1/ | tmp/downloads | 5e43e66f74da7ecf87f7060a310a26bf |
