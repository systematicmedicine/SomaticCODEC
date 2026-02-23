"""
--- paths.io.ex.core ---

Defines path constants for the core data processing steps of the EX pipeline

Author: Cameron Fraser

"""

# ---------------------------------------------------------------------------------------------------------------
# Preprocess FASTQ
# ---------------------------------------------------------------------------------------------------------------

ADAPTOR_R1_START = "tmp/{ex_lane}/{ex_lane}_r1_start.fasta"
ADAPTOR_R2_START = "tmp/{ex_lane}/{ex_lane}_r2_start.fasta"

UMIXD_FASTQ_R1 = "tmp/{ex_lane}/{ex_lane}_r1_umi_extracted.fastq.gz"
UMIXD_FASTQ_R2 = "tmp/{ex_lane}/{ex_lane}_r2_umi_extracted.fastq.gz"

DEMUXD_FASTQ_R1 = "tmp/{ex_sample}/{ex_sample}_r1_demux.fastq.gz"
DEMUXD_FASTQ_R2 = "tmp/{ex_sample}/{ex_sample}_r2_demux.fastq.gz"

TRIM_FASTQ_INT1_R1 = "tmp/{ex_sample}/{ex_sample}_r1_trim_adapters.fastq.gz"
TRIM_FASTQ_INT1_R2 = "tmp/{ex_sample}/{ex_sample}_r2_trim_adapters.fastq.gz"

TRIM_FASTQ_INT2_R1 = "tmp/{ex_sample}/{ex_sample}_r1_trim_adapters2.fastq.gz"
TRIM_FASTQ_INT2_R2 = "tmp/{ex_sample}/{ex_sample}_r2_trim_adapters2.fastq.gz"

TRIMMED_FASTQ_R1 = "tmp/{ex_sample}/{ex_sample}_r1_trim.fastq.gz"
TRIMMED_FASTQ_R2 = "tmp/{ex_sample}/{ex_sample}_r2_trim.fastq.gz"

FILTERED_FASTQ_R1 = "tmp/{ex_sample}/{ex_sample}_r1_filter.fastq.gz"
FILTERED_FASTQ_R2 = "tmp/{ex_sample}/{ex_sample}_r2_filter.fastq.gz"

# ---------------------------------------------------------------------------------------------------------------
# Alignment
# ---------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------
# Duplex consensus
# ---------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------
# Variant calling
# ---------------------------------------------------------------------------------------------------------------

