# Preparing sample metadata sheets

Download and fill in the following [metadata CSVs](https://github.com/systematicmedicine/SomaticCODEC/tree/master/config):

- ***config/ex_adapters.csv***: Defines the sequences for each CODEC adapter quadruplex.
- ***config/ex_lanes.csv***: Defines the FASTQ files for each ex_lane ID.
- ***config/ex_samples.csv***: Defines the ex_lane ID, ex_sample ID, ex_adapter ID, and ms_sample ID for each ex_sample.
- ***config/ms_samples.csv***: Defines the FASTQ files for each ms_sample ID.
- ***config/download_list.csv***: Defines which files to download from S3 (only required if using *bin/download_S3.py* for file staging)

### config/ex_adapters.csv

*config/ex_adapters.csv* contains the following fields:

- `ex_adapter`: A unique name assigned to each adapter quadruplex
- `r1_start`: The P5 adapter sequence
- `r1_end`: The P7 bridge sequence
- `r2_start`: The P7 adapter sequence
- `r2_end`: The P5 bridge sequence

Example using quadruplex 1 from Bae *et al.* 2023:

```
ex_adapter,r1_start,r1_end,r2_start,r2_end
QD001,CTTGAACGGACTGTCCAC,GTAGTCTAACGCTCGGTG,CACCGAGCGTTAGACTAC,GTGGACAGTCCGTTCAAG
```

### config/ex_lanes.csv

*config/ex_lanes.csv* contains the following fields:

- `ex_lane`: A unique ID assigned to each sequencing lane
- `fastq1`: The path to the R1 FASTQ for each lane (relative to the SomaticCODEC directory)
- `fastq2`: The path to the R2 FASTQ for each lane (relative to the SomaticCODEC directory)

Example:

```
ex_lane,fastq1,fastq2
LN001,tmp/downloads/L001_R1.fastq.gz,tmp/downloads/L001_R2.fastq.gz
```

### config/ex_samples.csv

*config/ex_samples.csv* contains the following fields:

- `ex_sample`: A unique ID assigned to each sample following demultiplexing of the ex_lane
- `ex_lane`: The ex_lane ID for the sequencing lane that contains the ex_sample
- `ex_adapter`: The ex_adapter ID that will be used to identify the ex_sample during demultiplexing
- `ms_sample`: The ID of the matched sample that corrsponds to the ex_sample
- `donor_id`: An ID shared between the ex_sample and the ms_sample to ensure a correct match
- `comments`: Any comments about the sample (this field is not used by the pipeline)

Example:

```
ex_sample,ex_lane,ex_adapter,ms_sample,donor_id,comments
S001,LN001,QD001,S002,D001,"Buffy coat sample, 43yo male"
```

### config/ms_samples.csv

*config/ms_samples.csv* contains the following fields:

- `ms_sample`: A unique ID assigned to each matched sample
- `fastq1`: The path to the R1 FASTQ for each sample (relative to the SomaticCODEC directory)
- `fastq2`: The path to the R2 FASTQ for each sample (relative to the SomaticCODEC directory)
- `donor_id`: An ID shared between the ex_sample and the ms_sample to ensure a correct match
- `comments`: Any comments about the sample (this field is not used by the pipeline)

Example:

```
ms_sample,fastq1,fastq2,donor_id,comments
S002,tmp/downloads/Buffy_D001_Age43_R1.fastq.gz,tmp/downloads/Buffy_D001_Age43_R2.fastq.gz,D001,"Buffy coat sample, 43yo male"
```

### config/download_list.csv

*config/download_list.csv* contains the following fields:

- `file_name`: The name of the file to be downloaded
- `source_dir`: The absolute path to the file on S3
- `destination_dir`: The path to the destination directory (relative to the SomaticCODEC directory, typically tmp/downloads)
- `expected_md5sum`: The md5sum of the file (checked after download)

Example:

```
file_name,source_dir,destination_dir,expected_md5sum
UCSC-GCRh38-p14-filtered.fa,s3://<bucket>/reference-genomes/UCSC-GCRh38-p14-filtered/,tmp/downloads,5e43e66f74da7ecf87f7060a310a26bf
```

