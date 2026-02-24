"""
--- paths.io.ex ---

Defines path constants for EX rules

Abbreviations:
    - INT (Intermediate file)
    - MET (Metrics file)

Author: Cameron Fraser

"""

# ---------------------------------------------------------------------------------------------------------------
# Core pipeline
# ---------------------------------------------------------------------------------------------------------------

# Preprocess FASTQ

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

# Alignment

RAW_SAM = "tmp/{ex_sample}/{ex_sample}_map_tmp.sam"
RAW_BAM = "tmp/{ex_sample}/{ex_sample}_map.bam"

FILTERED_BAM = "tmp/{ex_sample}/{ex_sample}_map_correct.bam"

READ_GROUP_BAM = "tmp/{ex_sample}/{ex_sample}_map_read_group.bam"

ADD_MATE_INFORMATION_INT = "tmp/{ex_sample}/{ex_sample}_map_collated_tmp.bam"
MATE_INFO_BAM = "tmp/{ex_sample}/{ex_sample}_map_anno.bam"

GROUP_BY_UMI_INT1 = "tmp/{ex_sample}/{ex_sample}_map_moveumi_tmp.bam"
GROUP_BY_UMI_INT2 = "tmp/{ex_sample}/{ex_sample}_map_moveumi_sorted_tmp.bam"
UMI_GROUPED_BAM = "tmp/{ex_sample}/{ex_sample}_map_umi_grouped.bam"

# Duplex consensus

RAW_DSC = "tmp/{ex_sample}/{ex_sample}_unmap_dsc.bam"

REALIGN_DSC_INT1 = "tmp/{ex_sample}/{ex_sample}_unmap_dsc_tmp.fastq"
REALIGN_DSC_INT2 = "tmp/{ex_sample}/{ex_sample}_map_dsc_unsorted_tmp.sam"
REALIGN_DSC_INT3 = "tmp/{ex_sample}/{ex_sample}_map_dsc_unsorted_tmp.bam"
REALIGNED_DSC = "tmp/{ex_sample}/{ex_sample}_map_dsc.bam"

ANNOTATE_DSC_INT1 = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_unsorted_tmp.bam"
ANNOTATED_DSC = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno.bam"
ANNOTATED_DSC_INDEX = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno.bam.bai"

FILTER_DSC_INT1 = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered_unsorted.bam"
FILTERED_DSC = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam"
FILTERED_DSC_INDEX = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam.bai"

# Variant calling

CALL_SOMATIC_SNV_INT1 = "tmp/{ex_sample}/{ex_sample}_bcf_mpileup.bcf"
CALL_SOMATIC_SNV_INT2 = "tmp/{ex_sample}/{ex_sample}_bcf_called.bcf"
CALL_SOMATIC_SNV_INT3 = "tmp/{ex_sample}/{ex_sample}_all_positions.vcf"
CALL_SOMATIC_SNV_INT4 = "tmp/{ex_sample}/{ex_sample}_bcf_biallelic.bcf"
CALLED_SNVS = "results/{ex_sample}/{ex_sample}_variants.vcf"

# ---------------------------------------------------------------------------------------------------------------
# Metrics
# ---------------------------------------------------------------------------------------------------------------

# Preprocess FASTQ

MET_DEMULIPLEX_FASTQ = "metrics/{ex_lane}/{ex_lane}_demux_metrics.txt"

MET_TRIM_FASTQ_TRIM5P = "metrics/{ex_sample}/{ex_sample}_trim_5prime_metrics.json"
MET_TRIM_FASTQ_TRIM3PR1 = "metrics/{ex_sample}/{ex_sample}_r1_trim_3prime_metrics.json"
MET_TRIM_FASTQ_TRIM3PR2 = "metrics/{ex_sample}/{ex_sample}_r2_trim_3prime_metrics.json"

MET_FILTER_FASTQ = "metrics/{ex_sample}/{ex_sample}_filter_metrics_ex.txt"

# Alignment

MET_GROUP_BY_UMI = "metrics/{ex_sample}/{ex_sample}_map_umi_metrics.txt"

# Duplex consensus

MET_CALL_DSC = "metrics/{ex_sample}/{ex_sample}_call_codec_consensus_metrics.txt"

# Variant calling