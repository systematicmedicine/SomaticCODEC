"""
--- paths.log ---

Defines path constants for logs

Author: Joshua Johnstone

"""

# ---------------------------------------------------------------------------------------------------------------
# Shared
# ---------------------------------------------------------------------------------------------------------------

# Setup

RUN_PIPELINE = "logs/bin_scripts/run_pipeline.log"
ENSURE_PIPELINE_LOG_EXISTS = "logs/shared_rules/ensure_pipeline_log_exists.log"

LOG_SYSTEM_RESOURCE_USAGE = "logs/shared_rules/log_system_resource_usage.log"
SYSTEM_RESOURCE_USAGE = "logs/shared_rules/system_resource_usage.csv"
LOG_SYSTEM_RESOURCE_USAGE_DONE = "logs/shared_rules/log_system_resource_usage.done"

CHECK_INCLUDED_CHROMOSOMES_PRESENT = "logs/shared_rules/check_included_chromosomes_present.log"
CHECK_INCLUDED_CHROMOSOMES_PRESENT_DONE = "logs/shared_rules/check_included_chromosomes_present.done"

COMPLETE_SETUP = "logs/shared_rules/complete_setup.log"
SETUP_DONE = "logs/shared_rules/setup.done"

# Processing

BWAMEM_INDEX_FILES = "logs/shared_rules/bwamem_index_files.log"
PICARD_SEQUENCE_DICT = "logs/shared_rules/picard_sequence_dict.log"
SAMTOOLS_INDEX_FILES = "logs/shared_rules/samtools_index_files.log"
TABIX_INDEX_FILES = "logs/shared_rules/tabix_index_files.log"

INCLUDED_EXCLUDED_CHROMOSOMES_BEDS = "logs/shared_rules/included_excluded_chromosomes_beds.log"

# Metrics
COLLATE_BENCHMARKS = "logs/shared_rules/collate_benchmarks.log"
COMBINED_BENCHMARKS = "logs/shared_rules/combined_benchmarks.csv"

CREATE_JOB_LOG = "logs/shared_rules/create_job_log.log"
JOB_LOG = "logs/shared_rules/job_log.csv"

CREATE_METRICS_REPORT = "logs/shared_rules/create_metrics_report.log"

WRITE_GIT_METADATA = "logs/shared_rules/write_git_metadata.log"
GIT_METADATA = "logs/shared_rules/git_metadata.json"


# ---------------------------------------------------------------------------------------------------------------
# EX - Core pipeline
# ---------------------------------------------------------------------------------------------------------------

# Preprocess FASTQ

EX_EXTRACT_FASTQ_UMIS = "logs/{ex_lane}/ex_extract_fastq_umis.log"

EX_GENERATE_DEMUX_ADAPTORS = "logs/shared_rules/{ex_lane}/ex_generate_demux_adaptors.log"

EX_DEMULTIPLEX_FASTQ = "logs/shared_rules/ex_demultiplex_fastq.log"

EX_TRIM_FASTQ = "logs/{ex_sample}/ex_trim_fastq.log"

EX_FILTER_FASTQ = "logs/{ex_sample}/ex_filter_fastq.log"

# Alignment

EX_ALIGNMENT = "logs/{ex_sample}/ex_alignment.log"

EX_FILTER_BAM = "logs/{ex_sample}/ex_filter_bam.log"

EX_ADD_READ_GROUPS = "logs/{ex_sample}/ex_add_read_groups.log"

EX_ADD_MATE_INFORMATION = "logs/{ex_sample}/ex_add_mate_information.log"

EX_GROUP_BY_UMI = "logs/{ex_sample}/ex_group_by_umi.log"

# Duplex consensus

EX_CALL_DSC = "logs/{ex_sample}/ex_call_dsc.log"

EX_ANNOTATE_DSC = "logs/{ex_sample}/ex_annotate_dsc.log"

EX_FILTER_DSC = "logs/{ex_sample}/ex_filter_dsc.log"

EX_REALIGN_DSC = "logs/{ex_sample}/ex_realign_dsc.log"

# Variant calling

EX_CALL_SOMATIC_SNV = "logs/{ex_sample}/ex_call_somatic_snv.log"

# ---------------------------------------------------------------------------------------------------------------
# EX - Metrics
# ---------------------------------------------------------------------------------------------------------------

# Preprocess FASTQ

EX_FASTQCRAW_METRICS = "logs/{ex_lane}/ex_fastqcraw_metrics.log"
EX_FASTQC_RAW_SUMMARY_METRICS = "logs/{ex_lane}/ex_fastqc_raw_summary_metrics.log"

EX_DEMUX_COUNTS_AND_GINI = "logs/{ex_lane}/ex_demux_counts_and_gini.log"

EX_TRIM_SUMMARY_METRICS = "logs/{ex_sample}/ex_trim_summary_metrics.log"

EX_FASTQCFILTER_METRICS = "logs/{ex_sample}/ex_fastqcfilter_metrics.log"
EX_FASTQC_FILTER_SUMMARY_METRICS = "logs/{ex_sample}/ex_fastqc_filter_summary_metrics.log"

# Alignment

EX_ALIGNMENT_METRICS = "logs/{ex_sample}/ex_alignment_metrics.log"

EX_MULTIMAPPING_RAW_METRICS = "logs/{ex_sample}/ex_multimapping_raw_metrics.log"

EX_INSERT_METRICS = "logs/{ex_sample}/ex_insert_metrics.log"

EX_DUPLICATION_METRICS = "logs/{ex_sample}/ex_duplication_metrics.log"

# Duplex consensus

EX_CALL_DSC_READ_LOSS = "logs/{ex_sample}/ex_call_dsc_read_loss.log"

EX_DSC_REMAP_METRICS = "logs/{ex_sample}/ex_dsc_remap_metrics.log"

EX_MULTIMAPPING_DSC_METRICS = "logs/{ex_sample}/ex_multimapping_dsc_metrics.log"

EX_DUPLEX_OVERLAP_METRICS = "logs/{ex_sample}/ex_duplex_overlap_metrics.log"

EX_DEPTH_METRICS = "logs/{ex_sample}/ex_depth_metrics.log"
EX_DSC_COVERAGE_METRICS = "logs/{ex_sample}/ex_dsc_coverage_metrics.log"
EX_COVERAGE_OVERLAP_METRICS = "logs/{ex_sample}/ex_coverage_overlap_metrics.log"

EX_SOFTCLIPPING_METRICS = "logs/{ex_sample}/ex_softclipping_metrics.log"

EX_TOTAL_READ_LOSS = "logs/{ex_sample}/ex_total_read_loss.log"

EX_VARIANT_CALL_ELIGIBLE_DISAGREE_RATE = "logs/{ex_sample}/ex_variant_call_eligible_disagree_rate.log"

# Variant analysis

EX_SOMATIC_VARIANT_RATE = "logs/{ex_sample}/ex_somatic_variant_rate.log"
EX_CHROMOSOMAL_VARIANT_RATE_METRICS = "logs/{ex_sample}/ex_chromosomal_variant_rate_metrics.log"

EX_TRINUCLEOTIDE_CONTEXT_METRICS = "logs/{ex_sample}/ex_trinucleotide_context_metrics.log"

EX_SNV_DISTANCE_METRICS = "logs/{ex_sample}/ex_snv_distance_metrics.log"
EX_SNV_POSITION_METRICS = "logs/{ex_sample}/ex_snv_position_metrics.log"

EX_GNOMAD_OVERLAP = "logs/{ex_sample}/ex_gnomAD_overlap.log"

EX_SOMATIC_VARIANT_GERMLINE_CONTEXTS = "logs/{ex_sample}/ex_somatic_variant_germline_contexts.log"

EX_SNV_READ_POSITION_METRICS = "logs/{ex_sample}/ex_snv_read_position_metrics.log"

EX_RECURRENT_VARIANT_METRICS = "logs/shared_rules/ex_recurrent_variant_metrics.log"

# ---------------------------------------------------------------------------------------------------------------
# MS - Core pipeline
# ---------------------------------------------------------------------------------------------------------------

# Preprocess FASTQ

MS_TRIM_FASTQ = "logs/{ms_sample}/ms_trim_fastq.log"

MS_FILTER_FASTQ = "logs/{ms_sample}/ms_filter_fastq.log"

# Alignment

MS_ALIGNMENT = "logs/{ms_sample}/ms_alignment.log"

MS_ADD_READ_GROUPS = "logs/{ms_sample}/ms_add_read_groups.log"

MS_ADD_MATE_INFORMATION = "logs/{ms_sample}/ms_add_mate_information.log"

MS_REMOVE_DUPLICATES = "logs/{ms_sample}/ms_remove_duplicates.log"

# Masked regions

MS_PILEUP = "logs/{ms_sample}/ms_pileup.log"

MS_GERMLINE_RISK = "logs/{ms_sample}/ms_germline_risk.log"

MS_LOW_DEPTH = "logs/{ms_sample}/ms_low_depth.log"

COMBINE_MASKS = "logs/{ms_sample}/combine_masks.log"

GENERATE_INCLUDE_BED = "logs/{ex_sample}/generate_include_bed.log"

# ---------------------------------------------------------------------------------------------------------------
# Metrics
# ---------------------------------------------------------------------------------------------------------------

# Preprocess FASTQ

MS_RAW_FASTQ_METRICS = "logs/{ms_sample}/ms_raw_fastq_metrics.log"
MS_PROCESSED_FASTQ_METRICS = "logs/{ms_sample}/ms_processed_fastq_metrics.log"
MS_FASTQC_SUMMARY_METRICS = "logs/{ms_sample}/ms_fastqc_summary_metrics.log"

# Alignment

MS_ALIGNMENT_METRICS = "logs/{ms_sample}/ms_alignment_metrics.log"

MS_MULTIMAPPING_METRICS = "logs/{ms_sample}/ms_multimapping_metrics.log"

MS_INSERT_METRICS = "logs/{ms_sample}/ms_insert_metrics.log"

MS_DUPLICATION_METRICS = "logs/{ms_sample}/ms_duplication_metrics.log"

MS_DEPTH_HISTOGRAM_METRICS = "logs/{ms_sample}/ms_depth_histogram_metrics.log"
MS_COVERAGE_BY_DEPTH_METRICS = "logs/{ms_sample}/ms_coverage_by_depth_metrics.log"

# Masked regions

MS_GERM_RISK_VARIANT_METRICS = "logs/{ms_sample}/ms_germ_risk_variant_metrics.log"
MS_GERMLINE_RISK_RATE = "logs/{ms_sample}/ms_germline_risk_rate.log"

MS_MASKING_METRICS = "logs/{ms_sample}/ms_masking_metrics.log"
