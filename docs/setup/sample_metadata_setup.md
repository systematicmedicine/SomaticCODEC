# sample_metadata_setup.md

There are four sample metadata CSVs:

- **ex_adapters.csv**: Defines the sequences for each CODEC adapter quadruplex.
- **ex_lanes.csv**: Defines the FASTQ files for each ex_lane ID.
- **ex_samples.csv**: Defines the ex_lane ID, ex_sample ID, ex_adapter ID, and ms_sample ID for each ex_sample.
- **ms_samples.csv**: Defines the FASTQ files for each ms_sample ID.

### ex_adapters.csv

ex_adapters.csv contains the following columns:

- ex_adapter: A unique name assigned to each adapter quadruplex (e.g. QD001)
- r1_start: P5 adapter sequence (e.g. CTTGAACGGACTGTCCAC)
- r1_end: Reverse complement of P7 adapter sequence (e.g. GTAGTCTAACGCTCGGTG)
- r2_start: Reverse complement of P7 bridge sequence (e.g. CACCGAGCGTTAGACTAC)
- r2_end: 

- For each adapter quadruplex, add the r1_start, r1_end, r2_start, and r2_end sequences 

### ex_lanes.csv



### ex_samples.csv

### ms_samples.csv

