"""
--- paths.io.ms ---

Defines path constants for MS rules

Abbreviations:
    - INT (Intermediate file)
    - MET (Metrics file)

Authors: 
    - Cameron Fraser
    - Joshua Johnstone

"""


# ---------------------------------------------------------------------------------------------------------------
# Core pipeline
# ---------------------------------------------------------------------------------------------------------------

# Preprocess FASTQ

TRIM_FASTQ_INT_R1 = "tmp/{ms_sample}/{ms_sample}_spacer_removed_r1.fastq.gz"
TRIM_FASTQ_INT_R2 = "tmp/{ms_sample}/{ms_sample}_spacer_removed_r2.fastq.gz"
TRIMMED_FASTQ_R1 = "tmp/{ms_sample}/{ms_sample}_trim_r1.fastq.gz"
TRIMMED_FASTQ_R2 = "tmp/{ms_sample}/{ms_sample}_trim_r2.fastq.gz"

FILTERED_FASTQ_R1 = "tmp/{ms_sample}/{ms_sample}_filter_r1.fastq.gz"
FILTERED_FASTQ_R2 = "tmp/{ms_sample}/{ms_sample}_filter_r2.fastq.gz"

# Alignment

RAW_SAM = "tmp/{ms_sample}/{ms_sample}_raw_map.sam"
RAW_BAM = "tmp/{ms_sample}/{ms_sample}_raw_map.bam"

READ_GROUP_BAM = "tmp/{ms_sample}/{ms_sample}_read_group_map.bam"

ADD_MATE_INFORMATION_INT1 = "tmp/{ms_sample}/{ms_sample}_read_group_map_collated.bam"
ADD_MATE_INFORMATION_INT2 = "tmp/{ms_sample}/{ms_sample}_fixmate_map_unsorted.bam"
MATE_INFO_BAM = "tmp/{ms_sample}/{ms_sample}_annotated_map.bam"
MATE_INFO_BAM_INDEX = "tmp/{ms_sample}/{ms_sample}_annotated_map.bam.bai"

REMOVE_DUPLICATES_INT = "tmp/{ms_sample}/{ms_sample}_deduped_map_unsorted.bam"
DEDUPED_BAM = "tmp/{ms_sample}/{ms_sample}_deduped_map.bam"
DEDUPED_BAM_INDEX = "tmp/{ms_sample}/{ms_sample}_deduped_map.bam.bai"

# Masked regions

PILEUP_INT = "tmp/{ms_sample}/{ms_sample}_ms_pileup.bcf"
PILEUP_DEPTH = "tmp/{ms_sample}/{ms_sample}_ms_pileup_depth.vcf"

GERMLINE_RISK_INT1 = "tmp/{ms_sample}/{ms_sample}_ms_pileup_depth_alt.vcf"
GERMLINE_RISK_INT2 = "tmp/{ms_sample}/{ms_sample}_ms_germ_deletions_unformatted.bed"
GERMLINE_RISK_INT3 = "tmp/{ms_sample}/{ms_sample}_ms_germ_insertions_unformatted.bed"
GERMLINE_RISK_INT4 = "tmp/{ms_sample}/{ms_sample}_ms_germ_all_unformatted.bed"
GERMLINE_RISK_INT5 = "tmp/{ms_sample}/{ms_sample}_ms_germ_deletions_unpadded.bed"
GERMLINE_RISK_INT6 = "tmp/{ms_sample}/{ms_sample}_ms_germ_insertions_unpadded.bed"
GERMLINE_RISK_INT7 = "tmp/{ms_sample}/{ms_sample}_ms_germ_deletions.bed"
GERMLINE_RISK_INT8 = "tmp/{ms_sample}/{ms_sample}_ms_germ_insertions.bed"
GERMLINE_RISK_INT9 = "tmp/{ms_sample}/{ms_sample}_ms_germ_all.bed"
GERMLINE_RISK_INT10 = "tmp/{ms_sample}/{ms_sample}_ms_germ_risk_cat_unsorted.bed"
GERMLINE_RISK_INT11 = "tmp/{ms_sample}/{ms_sample}_ms_germ_risk_cat_unmerged.bed"
GERMLINE_RISK_MASK = "tmp/{ms_sample}/{ms_sample}_ms_germ_risk.bed"

LOW_DEPTH_MASK_INT1 = "tmp/{ms_sample}/{ms_sample}_ms_pileup_depth.bed"
LOW_DEPTH_MASK = "tmp/{ms_sample}/{ms_sample}_ms_lowdepth.bed"

COMBINE_MASKS_INT1 = "tmp/{ms_sample}/{ms_sample}_masks_cat.bed"
COMBINE_MASKS_INT2 = "tmp/{ms_sample}/{ms_sample}_masks_sorted.bed"
COMBINED_MASK = "tmp/{ms_sample}/{ms_sample}_combined_mask.bed"

INCLUDE_BED = "tmp/{ex_sample}/{ex_sample}_include.bed"

# ---------------------------------------------------------------------------------------------------------------
# Metrics
# ---------------------------------------------------------------------------------------------------------------

# Preprocess FASTQ

MET_FASTQC_RAW_HTML_R1 = "metrics/{ms_sample}/{ms_sample}_r1_raw_fastqc.html"
MET_FASTQC_RAW_HTML_R2 = "metrics/{ms_sample}/{ms_sample}_r2_raw_fastqc.html"
MET_FASTQC_RAW_TXT_R1 = "metrics/{ms_sample}/{ms_sample}_r1_raw_fastqc.txt"
MET_FASTQC_RAW_TXT_R2 = "metrics/{ms_sample}/{ms_sample}_r2_raw_fastqc.txt"
MET_FASTQC_RAW_INT_R1 = "metrics/{ms_sample}/{ms_sample}_r1_raw_fastqc.zip"
MET_FASTQC_RAW_INT_R2 = "metrics/{ms_sample}/{ms_sample}_r2_raw_fastqc.zip"
MET_FASTQC_RAW_SUMMARY_R1 = "metrics/{ms_sample}/{ms_sample}_r1_raw_fastqc_summary.json"
MET_FASTQC_RAW_SUMMARY_R2 = "metrics/{ms_sample}/{ms_sample}_r2_raw_fastqc_summary.json"

MET_TRIM_FASTQ = "metrics/{ms_sample}/{ms_sample}_trim_metrics.txt"

MET_FILTER_FASTQ = "metrics/{ms_sample}/{ms_sample}_filter_metrics_ms.txt"

MET_FASTQC_FILTER_HTML_R1 = "metrics/{ms_sample}/{ms_sample}_filter_r1_fastqc.html"
MET_FASTQC_FILTER_HTML_R2 = "metrics/{ms_sample}/{ms_sample}_filter_r2_fastqc.html"
MET_FASTQC_FILTER_TXT_R1 = "metrics/{ms_sample}/{ms_sample}_filter_r1_fastqc.txt"
MET_FASTQC_FILTER_TXT_R2 = "metrics/{ms_sample}/{ms_sample}_filter_r2_fastqc.txt"
MET_FASTQC_FILTER_INT_R1 = "metrics/{ms_sample}/{ms_sample}_filter_r1_fastqc.zip"
MET_FASTQC_FILTER_INT_R2 = "metrics/{ms_sample}/{ms_sample}_filter_r2_fastqc.zip"
MET_FASTQC_FILTER_SUMMARY_R1 = "metrics/{ms_sample}/{ms_sample}_filter_r1_fastqc_summary.json"
MET_FASTQC_FILTER_SUMMARY_R2 = "metrics/{ms_sample}/{ms_sample}_filter_r2_fastqc_summary.json"

# Alignment

MET_DUPLICATION_1 = "metrics/{ms_sample}/{ms_sample}_dedup_metrics.json"
MET_DUPLICATION_2 = "metrics/{ms_sample}/{ms_sample}_duplication_metrics_ms.json"

MET_ALIGNMENT = "metrics/{ms_sample}/{ms_sample}_alignment_stats.txt"

MET_INSERT_SIZE_TXT = "metrics/{ms_sample}/{ms_sample}_insert_size_metrics.txt"
MET_INSERT_SIZE_PDF = "metrics/{ms_sample}/{ms_sample}_insert_size_histogram.pdf"

MET_DEPTH_HIST_INT1 = "tmp/{ms_sample}/{ms_sample}_depth_per_base.txt"
MET_DEPTH_HIST_INT2 = "tmp/{ms_sample}/{ms_sample}_depth_values.txt"
MET_DEPTH_HIST_INT3 = "tmp/{ms_sample}/{ms_sample}_depth_values_sorted.txt"
MET_DEPTH_HIST = "metrics/{ms_sample}/{ms_sample}_depth_histogram_counts.txt"
MET_COVERAGE_BY_DEPTH = "metrics/{ms_sample}/{ms_sample}_coverage_by_depth.json"

# Masked regions

MET_GERM_RISK_VARIANTS = "metrics/{ms_sample}/{ms_sample}_germ_risk_variant_metrics.txt"
MET_GERMLINE_RISK_RATE = "metrics/{ms_sample}/{ms_sample}_germline_risk_rate.json"

MET_MASKING_INT1 = "tmp/{ms_sample}/{ms_sample}_germ_risk_all_samples.txt"
MET_MASKING_INT2 = "tmp/{ms_sample}/{ms_sample}_masks_sorted.txt"
MET_MASKING_INT3 = "tmp/{ms_sample}/{ms_sample}_masks_merged.txt"
MET_MASKING = "metrics/{ms_sample}/{ms_sample}_mask_metrics.json"
