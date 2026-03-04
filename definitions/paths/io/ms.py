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

TRIM_FASTQ_INT_R1 = "tmp/ms/{ms_sample}/{ms_sample}_int1_trimmed_r1.fastq.gz"
TRIM_FASTQ_INT_R2 = "tmp/ms/{ms_sample}/{ms_sample}_int1_trimmed_r2.fastq.gz"
TRIMMED_FASTQ_R1 = "tmp/ms/{ms_sample}/{ms_sample}_trimmed_r1.fastq.gz"
TRIMMED_FASTQ_R2 = "tmp/ms/{ms_sample}/{ms_sample}_trimmed_r2.fastq.gz"

FILTERED_FASTQ_R1 = "tmp/ms/{ms_sample}/{ms_sample}_filtered_r1.fastq.gz"
FILTERED_FASTQ_R2 = "tmp/ms/{ms_sample}/{ms_sample}_filtered_r2.fastq.gz"

# Alignment

RAW_SAM = "tmp/ms/{ms_sample}/{ms_sample}_raw_alignment.sam"
RAW_BAM = "tmp/ms/{ms_sample}/{ms_sample}_raw_alignment.bam"

READ_GROUP_BAM = "tmp/ms/{ms_sample}/{ms_sample}_read_group_alignment.bam"

ADD_MATE_INFORMATION_INT1 = "tmp/ms/{ms_sample}/{ms_sample}_int1_annotated_alignment.bam"
ADD_MATE_INFORMATION_INT2 = "tmp/ms/{ms_sample}/{ms_sample}_int2_annotated_alignment.bam"
MATE_INFO_BAM = "tmp/ms/{ms_sample}/{ms_sample}_annotated_alignment.bam"
MATE_INFO_BAM_INDEX = "tmp/ms/{ms_sample}/{ms_sample}_annotated_alignment.bam.bai"

REMOVE_DUPLICATES_INT = "tmp/ms/{ms_sample}/{ms_sample}_int_deduped_alignment.bam"
DEDUPED_BAM = "tmp/ms/{ms_sample}/{ms_sample}_deduped_alignment.bam"
DEDUPED_BAM_INDEX = "tmp/ms/{ms_sample}/{ms_sample}_deduped_alignment.bam.bai"

# Masked regions

PILEUP_INT = "tmp/ms/{ms_sample}/{ms_sample}_int_pileup.bcf"
PILEUP_DEPTH = "tmp/ms/{ms_sample}/{ms_sample}_high_depth_pileup.vcf"

GERMLINE_RISK_INT1 = "tmp/ms/{ms_sample}/{ms_sample}_germ_risk.vcf"
GERMLINE_RISK_INT2 = "tmp/ms/{ms_sample}/{ms_sample}_germ_deletions_unformatted.bed"
GERMLINE_RISK_INT3 = "tmp/ms/{ms_sample}/{ms_sample}_germ_insertions_unformatted.bed"
GERMLINE_RISK_INT4 = "tmp/ms/{ms_sample}/{ms_sample}_germ_all_unformatted.bed"
GERMLINE_RISK_INT5 = "tmp/ms/{ms_sample}/{ms_sample}_germ_deletions_unpadded.bed"
GERMLINE_RISK_INT6 = "tmp/ms/{ms_sample}/{ms_sample}_germ_insertions_unpadded.bed"
GERMLINE_RISK_INT7 = "tmp/ms/{ms_sample}/{ms_sample}_germ_deletions.bed"
GERMLINE_RISK_INT8 = "tmp/ms/{ms_sample}/{ms_sample}_germ_insertions.bed"
GERMLINE_RISK_INT9 = "tmp/ms/{ms_sample}/{ms_sample}_germ_all.bed"
GERMLINE_RISK_INT10 = "tmp/ms/{ms_sample}/{ms_sample}_germ_risk_cat_unsorted.bed"
GERMLINE_RISK_INT11 = "tmp/ms/{ms_sample}/{ms_sample}_germ_risk_cat_unmerged.bed"
GERMLINE_RISK_MASK = "tmp/ms/{ms_sample}/{ms_sample}_germ_risk.bed"

LOW_DEPTH_MASK_INT1 = "tmp/ms/{ms_sample}/{ms_sample}_int_lowdepth.bed"
LOW_DEPTH_MASK = "tmp/ms/{ms_sample}/{ms_sample}_lowdepth.bed"

COMBINE_MASKS_INT1 = "tmp/ms/{ms_sample}/{ms_sample}_int1_combined_mask.bed"
COMBINE_MASKS_INT2 = "tmp/ms/{ms_sample}/{ms_sample}_int2_combined_mask.bed"
COMBINED_MASK = "tmp/ms/{ms_sample}/{ms_sample}_combined_mask.bed"

INCLUDE_BED = "tmp/ms/{ex_sample}/{ex_sample}_include.bed"

# ---------------------------------------------------------------------------------------------------------------
# Metrics
# ---------------------------------------------------------------------------------------------------------------

# Preprocess FASTQ

MET_FASTQC_RAW_HTML_R1 = "metrics/ms/{ms_sample}/{ms_sample}_fastqc_raw_metrics_r1.html"
MET_FASTQC_RAW_HTML_R2 = "metrics/ms/{ms_sample}/{ms_sample}_fastqc_raw_metrics_r2.html"
MET_FASTQC_RAW_TXT_R1 = "metrics/ms/{ms_sample}/{ms_sample}_fastqc_raw_metrics_r1.txt"
MET_FASTQC_RAW_TXT_R2 = "metrics/ms/{ms_sample}/{ms_sample}_fastqc_raw_metrics_r2.txt"
MET_FASTQC_RAW_INT_R1 = "metrics/ms/{ms_sample}/{ms_sample}_fastqc_raw_metrics_r1.zip"
MET_FASTQC_RAW_INT_R2 = "metrics/ms/{ms_sample}/{ms_sample}_fastqc_raw_metrics_r2.zip"
MET_FASTQC_RAW_SUMMARY_R1 = "metrics/ms/{ms_sample}/{ms_sample}_fastqc_raw_metrics_summary_r1.json"
MET_FASTQC_RAW_SUMMARY_R2 = "metrics/ms/{ms_sample}/{ms_sample}_fastqc_raw_metrics_summary_r2.json"

MET_TRIM_FASTQ = "metrics/ms/{ms_sample}/{ms_sample}_trim_metrics.txt"

MET_FILTER_FASTQ = "metrics/ms/{ms_sample}/{ms_sample}_filter_metrics.txt"

MET_FASTQC_FILTER_HTML_R1 = "metrics/ms/{ms_sample}/{ms_sample}_fastqc_filter_metrics_r1.html"
MET_FASTQC_FILTER_HTML_R2 = "metrics/ms/{ms_sample}/{ms_sample}_fastqc_filter_metrics_r2.html"
MET_FASTQC_FILTER_TXT_R1 = "metrics/ms/{ms_sample}/{ms_sample}_fastqc_filter_metrics_r1.txt"
MET_FASTQC_FILTER_TXT_R2 = "metrics/ms/{ms_sample}/{ms_sample}_fastqc_filter_metrics_r2.txt"
MET_FASTQC_FILTER_INT_R1 = "metrics/ms/{ms_sample}/{ms_sample}_fastqc_filter_metrics_r1.zip"
MET_FASTQC_FILTER_INT_R2 = "metrics/ms/{ms_sample}/{ms_sample}_fastqc_filter_metrics_r2.zip"
MET_FASTQC_FILTER_SUMMARY_R1 = "metrics/ms/{ms_sample}/{ms_sample}_fastqc_filter_metrics_summary_r1.json"
MET_FASTQC_FILTER_SUMMARY_R2 = "metrics/ms/{ms_sample}/{ms_sample}_fastqc_filter_metrics_summary_r2.json"

# Alignment

MET_DEDUP_REPORT = "metrics/ms/{ms_sample}/{ms_sample}_dedup_report.json"
MET_DUPLICATION = "metrics/ms/{ms_sample}/{ms_sample}_duplication_metrics.json"

MET_ALIGNMENT = "metrics/ms/{ms_sample}/{ms_sample}_alignment_metrics.txt"

MET_MULTIMAPPING = "metrics/ms/{ms_sample}/{ms_sample}_multimapping_metrics.json"

MET_INSERT_SIZE_TXT = "metrics/ms/{ms_sample}/{ms_sample}_insert_metrics.txt"
MET_INSERT_SIZE_PDF = "metrics/ms/{ms_sample}/{ms_sample}_insert_metrics.pdf"

MET_DEPTH_INT1 = "tmp/ms/{ms_sample}/{ms_sample}_int1_depth_metrics.txt"
MET_DEPTH_INT2 = "tmp/ms/{ms_sample}/{ms_sample}_int2_depth_metrics.txt"
MET_DEPTH_INT3 = "tmp/ms/{ms_sample}/{ms_sample}_int3_depth_metrics.txt"
MET_DEPTH = "metrics/ms/{ms_sample}/{ms_sample}_depth_metrics.txt"
MET_COVERAGE = "metrics/ms/{ms_sample}/{ms_sample}_coverage_metrics.json"

# Masked regions

MET_GERM_RISK_VARIANTS = "metrics/ms/{ms_sample}/{ms_sample}_germ_risk_variant_metrics.txt"
MET_GERM_RISK_RATE = "metrics/ms/{ms_sample}/{ms_sample}_germ_risk_rate.json"

MET_MASKING_INT1 = "tmp/ms/{ms_sample}/{ms_sample}_int1_mask_metrics.txt"
MET_MASKING_INT2 = "tmp/ms/{ms_sample}/{ms_sample}_int2_mask_metrics.txt"
MET_MASKING_INT3 = "tmp/ms/{ms_sample}/{ms_sample}_int3_mask_metrics.txt"
MET_MASKING = "metrics/ms/{ms_sample}/{ms_sample}_mask_metrics.json"
