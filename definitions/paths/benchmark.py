"""
--- paths.benchmark.txt ---

Defines path constants for benchmarks

Author: Joshua Johnstone

"""

# ---------------------------------------------------------------------------------------------------------------
# Shared
# ---------------------------------------------------------------------------------------------------------------

# Setup

ENSURE_PIPELINE_LOG_EXISTS = "logs/shared_rules/ensure_pipeline_log_exists.benchmark.txt"

LOG_SYSTEM_RESOURCE_USAGE = "logs/shared_rules/log_system_resource_usage.benchmark.txt"

CHECK_INCLUDED_CHROMOSOMES_PRESENT = "logs/shared_rules/check_included_chromosomes_present.benchmark.txt"

COMPLETE_SETUP = "logs/shared_rules/complete_setup.benchmark.txt"

# Processing

BWAMEM_INDEX_FILES = "logs/shared_rules/bwamem_index_files.benchmark.txt"

PICARD_SEQUENCE_DICT = "logs/shared_rules/picard_sequence_dict.benchmark.txt"

SAMTOOLS_INDEX_FILES = "logs/shared_rules/samtools_index_files.benchmark.txt"

TABIX_INDEX_FILES = "logs/shared_rules/tabix_index_files.benchmark.txt"

INCLUDED_EXCLUDED_CHROMOSOMES_BEDS = "logs/shared_rules/included_excluded_chromosomes_beds.benchmark.txt"

# Metrics

CREATE_JOB_LOG = "logs/shared_rules/create_job_log.benchmark.txt"

CREATE_METRICS_REPORT = "logs/shared_rules/create_metrics_report.benchmark.txt"

WRITE_GIT_METADATA = "logs/shared_rules/write_git_metadata.benchmark.txt"

# ---------------------------------------------------------------------------------------------------------------
# EX - Core pipeline
# ---------------------------------------------------------------------------------------------------------------

# Preprocess FASTQ

EX_EXTRACT_FASTQ_UMIS = "logs/{ex_lane}/ex_extract_fastq_umis.benchmark.txt"

EX_GENERATE_DEMUX_ADAPTORS = "logs/shared_rules/{ex_lane}/ex_generate_demux_adaptors.benchmark.txt"

EX_DEMULTIPLEX_FASTQ = "logs/shared_rules/ex_demultiplex_fastq.benchmark.txt"

EX_TRIM_FASTQ = "logs/{ex_sample}/ex_trim_fastq.benchmark.txt"

EX_FILTER_FASTQ = "logs/{ex_sample}/ex_filter_fastq.benchmark.txt"

# Alignment

EX_ALIGNMENT = "logs/{ex_sample}/ex_alignment.benchmark.txt"

EX_FILTER_BAM = "logs/{ex_sample}/ex_filter_bam.benchmark.txt"

EX_ADD_READ_GROUPS = "logs/{ex_sample}/ex_add_read_groups.benchmark.txt"

EX_ADD_MATE_INFORMATION = "logs/{ex_sample}/ex_add_mate_information.benchmark.txt"

EX_GROUP_BY_UMI = "logs/{ex_sample}/ex_group_by_umi.benchmark.txt"

# Duplex consensus

EX_CALL_DSC = "logs/{ex_sample}/ex_call_dsc.benchmark.txt"

EX_ANNOTATE_DSC = "logs/{ex_sample}/ex_annotate_dsc.benchmark.txt"

EX_FILTER_DSC = "logs/{ex_sample}/ex_filter_dsc.benchmark.txt"

EX_REALIGN_DSC = "logs/{ex_sample}/ex_realign_dsc.benchmark.txt"

# Variant calling

EX_CALL_SOMATIC_SNV = "logs/{ex_sample}/ex_call_somatic_snv.benchmark.txt"

# ---------------------------------------------------------------------------------------------------------------
# EX - Metrics
# ---------------------------------------------------------------------------------------------------------------

# Preprocess FASTQ

EX_FASTQCRAW_METRICS = "logs/{ex_lane}/ex_fastqcraw_metrics.benchmark.txt"
EX_FASTQC_RAW_SUMMARY_METRICS = "logs/{ex_lane}/ex_fastqc_raw_summary_metrics.benchmark.txt"

EX_DEMUX_COUNTS_AND_GINI = "logs/{ex_lane}/ex_demux_counts_and_gini.benchmark.txt"

EX_TRIM_SUMMARY_METRICS = "logs/{ex_sample}/ex_trim_summary_metrics.benchmark.txt"

EX_FASTQCFILTER_METRICS = "logs/{ex_sample}/ex_fastqcfilter_metrics.benchmark.txt"
EX_FASTQC_FILTER_SUMMARY_METRICS = "logs/{ex_sample}/ex_fastqc_filter_summary_metrics.benchmark.txt"

# Alignment

EX_ALIGNMENT_METRICS = "logs/{ex_sample}/ex_alignment_metrics.benchmark.txt"

EX_MULTIMAPPING_RAW_METRICS = "logs/{ex_sample}/ex_multimapping_raw_metrics.benchmark.txt"

EX_INSERT_METRICS = "logs/{ex_sample}/ex_insert_metrics.benchmark.txt"

EX_DUPLICATION_METRICS = "logs/{ex_sample}/ex_duplication_metrics.benchmark.txt"

# Duplex consensus

EX_CALL_DSC_READ_LOSS = "logs/{ex_sample}/ex_call_dsc_read_loss.benchmark.txt"

EX_DSC_REMAP_METRICS = "logs/{ex_sample}/ex_dsc_remap_metrics.benchmark.txt"

EX_MULTIMAPPING_DSC_METRICS = "logs/{ex_sample}/ex_multimapping_dsc_metrics.benchmark.txt"

EX_DUPLEX_OVERLAP_METRICS = "logs/{ex_sample}/ex_duplex_overlap_metrics.benchmark.txt"

EX_DEPTH_METRICS = "logs/{ex_sample}/ex_depth_metrics.benchmark.txt"
EX_DSC_COVERAGE_METRICS = "logs/{ex_sample}/ex_dsc_coverage_metrics.benchmark.txt"
EX_COVERAGE_OVERLAP_METRICS = "logs/{ex_sample}/ex_coverage_overlap_metrics.benchmark.txt"

EX_SOFTCLIPPING_METRICS = "logs/{ex_sample}/ex_softclipping_metrics.benchmark.txt"

EX_TOTAL_READ_LOSS = "logs/{ex_sample}/ex_total_read_loss.benchmark.txt"

EX_VARIANT_CALL_ELIGIBLE_DISAGREE_RATE = "logs/{ex_sample}/ex_variant_call_eligible_disagree_rate.benchmark.txt"

# Variant analysis

EX_SOMATIC_VARIANT_RATE = "logs/{ex_sample}/ex_somatic_variant_rate.benchmark.txt"
EX_CHROMOSOMAL_VARIANT_RATE_METRICS = "logs/{ex_sample}/ex_chromosomal_variant_rate_metrics.benchmark.txt"

EX_TRINUCLEOTIDE_CONTEXT_METRICS = "logs/{ex_sample}/ex_trinucleotide_context_metrics.benchmark.txt"

EX_SNV_DISTANCE_METRICS = "logs/{ex_sample}/ex_snv_distance_metrics.benchmark.txt"
EX_SNV_POSITION_METRICS = "logs/{ex_sample}/ex_snv_position_metrics.benchmark.txt"

EX_GNOMAD_OVERLAP = "logs/{ex_sample}/ex_gnomAD_overlap.benchmark.txt"

EX_SOMATIC_VARIANT_GERMLINE_CONTEXTS = "logs/{ex_sample}/ex_somatic_variant_germline_contexts.benchmark.txt"

EX_SNV_READ_POSITION_METRICS = "logs/{ex_sample}/ex_snv_read_position_metrics.benchmark.txt"

EX_RECURRENT_VARIANT_METRICS = "logs/shared_rules/ex_recurrent_variant_metrics.benchmark.txt"

# ---------------------------------------------------------------------------------------------------------------
# MS - Core pipeline
# ---------------------------------------------------------------------------------------------------------------

# Preprocess FASTQ

MS_TRIM_FASTQ = "logs/{ms_sample}/ms_trim_fastq.benchmark.txt"

MS_FILTER_FASTQ = "logs/{ms_sample}/ms_filter_fastq.benchmark.txt"

# Alignment

MS_ALIGNMENT = "logs/{ms_sample}/ms_alignment.benchmark.txt"

MS_ADD_READ_GROUPS = "logs/{ms_sample}/ms_add_read_groups.benchmark.txt"

MS_ADD_MATE_INFORMATION = "logs/{ms_sample}/ms_add_mate_information.benchmark.txt"

MS_REMOVE_DUPLICATES = "logs/{ms_sample}/ms_remove_duplicates.benchmark.txt"

# Masked regions

MS_PILEUP = "logs/{ms_sample}/ms_pileup.benchmark.txt"

MS_GERMLINE_RISK = "logs/{ms_sample}/ms_germline_risk.benchmark.txt"

MS_LOW_DEPTH = "logs/{ms_sample}/ms_low_depth.benchmark.txt"

COMBINE_MASKS = "logs/{ms_sample}/combine_masks.benchmark.txt"

GENERATE_INCLUDE_BED = "logs/{ex_sample}/generate_include_bed.benchmark.txt"

# ---------------------------------------------------------------------------------------------------------------
# Metrics
# ---------------------------------------------------------------------------------------------------------------

# Preprocess FASTQ

MS_RAW_FASTQ_METRICS = "logs/{ms_sample}/ms_raw_fastq_metrics.benchmark.txt"
MS_PROCESSED_FASTQ_METRICS = "logs/{ms_sample}/ms_processed_fastq_metrics.benchmark.txt"
MS_FASTQC_SUMMARY_METRICS = "logs/{ms_sample}/ms_fastqc_summary_metrics.benchmark.txt"

# Alignment

MS_ALIGNMENT_METRICS = "logs/{ms_sample}/ms_alignment_metrics.benchmark.txt"

MS_MULTIMAPPING_METRICS = "logs/{ms_sample}/ms_multimapping_metrics.benchmark.txt"

MS_INSERT_METRICS = "logs/{ms_sample}/ms_insert_metrics.benchmark.txt"

MS_DUPLICATION_METRICS = "logs/{ms_sample}/ms_duplication_metrics.benchmark.txt"

MS_DEPTH_HISTOGRAM_METRICS = "logs/{ms_sample}/ms_depth_histogram_metrics.benchmark.txt"
MS_COVERAGE_BY_DEPTH_METRICS = "logs/{ms_sample}/ms_coverage_by_depth_metrics.benchmark.txt"

# Masked regions

MS_GERM_RISK_VARIANT_METRICS = "logs/{ms_sample}/ms_germ_risk_variant_metrics.benchmark.txt"
MS_GERMLINE_RISK_RATE = "logs/{ms_sample}/ms_germline_risk_rate.benchmark.txt"

MS_MASKING_METRICS = "logs/{ms_sample}/ms_masking_metrics.benchmark.txt"
