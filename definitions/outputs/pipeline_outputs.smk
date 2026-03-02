"""
--- pipeline_outputs.smk ---

Defines pipeline outputs, to be imported into top-level Snakefile

Authors: Cameron Fraser
"""

# Load libraries
import helpers.get_metadata as md
from definitions.paths.io import ex as EX
from definitions.paths.io import ms as MS
from definitions.paths.io import shared as S

# Get lists of sample ids
ex_lane_ids = md.get_ex_lane_ids(config)
ex_sample_ids = md.get_ex_sample_ids(config)
ms_sample_ids = md.get_ms_sample_ids(config)

# ---------------------------------------------------------------------------------------------
# Setup files
# ---------------------------------------------------------------------------------------------
shared_setup = [
    config["sci_params"]["shared"]["reference_genome"] + ".amb",
    config["sci_params"]["shared"]["reference_genome"] + ".ann",
    config["sci_params"]["shared"]["reference_genome"] + ".bwt.2bit.64",
    config["sci_params"]["shared"]["reference_genome"] + ".pac",
    config["sci_params"]["shared"]["reference_genome"] + ".0123",
    config["sci_params"]["shared"]["reference_genome"] + ".fai",
    os.path.splitext(config["sci_params"]["shared"]["reference_genome"])[0] + ".dict",
    config["sci_params"]["shared"]["known_germline_variants"] + ".tbi",
    S.EXCLUDED_CHROMS_BED,
    "logs/shared_rules/check_included_chromosomes_present.done",
    "logs/shared_rules/log_system_resource_usage.done",
    "logs/bin_scripts/run_pipeline.log"
]

# ---------------------------------------------------------------------------------------------
# Processing metrics for MS samples
# ---------------------------------------------------------------------------------------------
ms_processing_metrics = [
    expand(MS.MET_FASTQC_RAW_HTML_R1, ms_sample = ms_sample_ids),
    expand(MS.MET_FASTQC_RAW_HTML_R2, ms_sample = ms_sample_ids),
    expand(MS.MET_FASTQC_RAW_TXT_R1, ms_sample = ms_sample_ids),
    expand(MS.MET_FASTQC_RAW_TXT_R2, ms_sample = ms_sample_ids),
    expand(MS.MET_FASTQC_RAW_SUMMARY_R1, ms_sample = ms_sample_ids),
    expand(MS.MET_FASTQC_RAW_SUMMARY_R2, ms_sample = ms_sample_ids),
    expand(MS.MET_TRIM_FASTQ, ms_sample = ms_sample_ids),
    expand(MS.MET_FILTER_FASTQ, ms_sample = ms_sample_ids),
    expand(MS.MET_FASTQC_FILTER_HTML_R1, ms_sample = ms_sample_ids),
    expand(MS.MET_FASTQC_FILTER_HTML_R2, ms_sample = ms_sample_ids),
    expand(MS.MET_FASTQC_FILTER_TXT_R1, ms_sample = ms_sample_ids),
    expand(MS.MET_FASTQC_FILTER_TXT_R2, ms_sample = ms_sample_ids),
    expand(MS.MET_FASTQC_FILTER_SUMMARY_R1, ms_sample = ms_sample_ids),
    expand(MS.MET_FASTQC_FILTER_SUMMARY_R2, ms_sample = ms_sample_ids),
    expand(MS.MET_DUPLICATION_1, ms_sample = ms_sample_ids),
    expand(MS.MET_DUPLICATION_2, ms_sample = ms_sample_ids),
    expand(MS.MET_ALIGNMENT, ms_sample = ms_sample_ids),
    expand(MS.MET_INSERT_SIZE_TXT, ms_sample = ms_sample_ids),
    expand(MS.MET_INSERT_SIZE_PDF, ms_sample = ms_sample_ids),
    expand(MS.MET_DEPTH_HIST, ms_sample = ms_sample_ids),
    expand(MS.MET_COVERAGE_BY_DEPTH, ms_sample = ms_sample_ids),
    expand(MS.MET_MASKING, ms_sample = ms_sample_ids)
]

# ---------------------------------------------------------------------------------------------
# Processing metrics for EX samples
# ---------------------------------------------------------------------------------------------
ex_processing_metrics = [
    expand(EX.MET_FASTQC_RAW_HTML_R1, ex_lane = ex_lane_ids),
    expand(EX.MET_FASTQC_RAW_HTML_R2, ex_lane = ex_lane_ids),
    expand(EX.MET_FASTQC_RAW_TXT_R1, ex_lane = ex_lane_ids),
    expand(EX.MET_FASTQC_RAW_TXT_R2, ex_lane = ex_lane_ids),
    expand(EX.MET_FASTQC_RAW_SUMMARY_R1, ex_lane = ex_lane_ids),
    expand(EX.MET_FASTQC_RAW_SUMMARY_R2, ex_lane = ex_lane_ids),
    expand(EX.MET_DEMULIPLEX_FASTQ, ex_lane = ex_lane_ids),
    expand(EX.MET_DEMUX_COUNTS_GINI, ex_lane = ex_lane_ids),
    expand(EX.MET_TRIM_FASTQ, ex_sample = ex_sample_ids),
    expand(EX.MET_TRIM_READ_LENGTHS, ex_sample = ex_sample_ids),
    expand(EX.MET_BASES_TRIMMED, ex_sample = ex_sample_ids),
    expand(EX.MET_FILTER_FASTQ, ex_sample = ex_sample_ids),
    expand(EX.MET_FASTQC_FILTER_HTML_R1, ex_sample = ex_sample_ids),
    expand(EX.MET_FASTQC_FILTER_HTML_R2, ex_sample = ex_sample_ids),
    expand(EX.MET_FASTQC_FILTER_TXT_R1, ex_sample = ex_sample_ids),
    expand(EX.MET_FASTQC_FILTER_TXT_R2, ex_sample = ex_sample_ids),
    expand(EX.MET_FASTQC_FILTER_SUMMARY_R1, ex_sample = ex_sample_ids),
    expand(EX.MET_FASTQC_FILTER_SUMMARY_R2, ex_sample = ex_sample_ids),
    expand(EX.MET_ALIGNMENT, ex_sample = ex_sample_ids),
    expand(EX.MET_INSERT_SIZE_TXT, ex_sample = ex_sample_ids),
    expand(EX.MET_INSERT_SIZE_PDF, ex_sample = ex_sample_ids),
    expand(EX.MET_GROUP_BY_UMI, ex_sample = ex_sample_ids),
    expand(EX.MET_DUPLICATION, ex_sample = ex_sample_ids),
    expand(EX.MET_CALL_DSC, ex_sample = ex_sample_ids),
    expand(EX.MET_CALL_DSC_READ_LOSS, ex_sample = ex_sample_ids),
    expand(EX.MET_DSC_REMAP, ex_sample = ex_sample_ids),
    expand(EX.MET_DUPLEX_OVERLAP, ex_sample = ex_sample_ids),
    expand(EX.MET_DSC_DEPTH, ex_sample = ex_sample_ids),
    expand(EX.MET_DSC_COVERAGE_JSON, ex_sample = ex_sample_ids),
    expand(EX.MET_DSC_COVERAGE_PLOT, ex_sample = ex_sample_ids),
    expand(EX.MET_COVERAGE_OVERLAP, ex_sample = ex_sample_ids),
    expand(EX.MET_SOFTCLIPPING, ex_sample = ex_sample_ids),
    expand(EX.MET_TOTAL_READ_LOSS, ex_sample = ex_sample_ids),
    expand(EX.MET_VAR_CALL_DISAGREE, ex_sample = ex_sample_ids)

]

# ---------------------------------------------------------------------------------------------
# Somatic varaint calling
# ---------------------------------------------------------------------------------------------
ex_variant_calling = [
    expand(EX.CALLED_SNVS, ex_sample = ex_sample_ids)
]

# ---------------------------------------------------------------------------------------------
# Analysis of called variants
# ---------------------------------------------------------------------------------------------
ex_variant_analysis = [
    expand(EX.MET_SOMATIC_VARIANT_RATE, ex_sample = ex_sample_ids),
    expand(EX.MET_CHROM_VARIANT_RATE, ex_sample = ex_sample_ids),
    expand(EX.MET_TRINUC_PROPORTIONS, ex_sample = ex_sample_ids),
    expand(EX.MET_TRINUC_SIMILARITIES, ex_sample = ex_sample_ids),
    expand(EX.MET_TRINUC_PLOTS, ex_sample = ex_sample_ids),
    expand(EX.MET_SNV_DISTANCE, ex_sample = ex_sample_ids),
    expand(EX.MET_SNV_POSITION_JSON, ex_sample = ex_sample_ids),
    expand(EX.MET_SNV_POSITION_PDF, ex_sample = ex_sample_ids),
    expand(EX.MET_GNOMAD_OVERLAP_VCF, ex_sample = ex_sample_ids),
    expand(EX.MET_GNOMAD_OVERLAP_JSON, ex_sample = ex_sample_ids),
    expand(EX.MET_SNV_GERMLINE_CONTEXT, ex_sample = ex_sample_ids),
    EX.MET_RECURRENT_VARIANTS_VCF,
    EX.MET_RECURRENT_VARIANTS_JSON
]

# ---------------------------------------------------------------------------------------------
# Shared metrics
# ---------------------------------------------------------------------------------------------
shared_metrics = [
    S.MET_COMPONENT_METRICS_REPORT,
    S.MET_COMPONENT_METRICS_HEATMAP,
    S.MET_SYSTEM_METRICS_REPORT,
    S.MET_SYSTEM_METRICS_HEATMAP,
    "logs/shared_rules/git_metadata.json",
    "logs/shared_rules/combined_benchmarks.csv",
    "logs/shared_rules/system_resource_usage.csv",
    "logs/shared_rules/job_log.csv",
    "logs/shared_rules/create_run_timeline_plot.log"
]