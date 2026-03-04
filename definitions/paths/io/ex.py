"""
--- paths.io.ex ---

Defines path constants for EX rules

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

DEMUX_ADAPTOR_R1 = "tmp/ex/{ex_lane}/{ex_lane}_demux_adaptor_r1.fasta"
DEMUX_ADAPTOR_R2 = "tmp/ex/{ex_lane}/{ex_lane}_demux_adaptor_r2.fasta"

UMIXD_FASTQ_R1 = "tmp/ex/{ex_lane}/{ex_lane}_umiextracted_r1.fastq.gz"
UMIXD_FASTQ_R2 = "tmp/ex/{ex_lane}/{ex_lane}_umiextracted_r2.fastq.gz"

DEMUXD_FASTQ_R1 = "tmp/ex/{ex_sample}/{ex_sample}_demuxed_r1.fastq.gz"
DEMUXD_FASTQ_R2 = "tmp/ex/{ex_sample}/{ex_sample}_demuxed_r2.fastq.gz"

TRIM_FASTQ_INT1_R1 = "tmp/ex/{ex_sample}/{ex_sample}_int1_trimmed_r1.fastq.gz"
TRIM_FASTQ_INT1_R2 = "tmp/ex/{ex_sample}/{ex_sample}_int1_trimmed_r2.fastq.gz"
TRIM_FASTQ_INT2_R1 = "tmp/ex/{ex_sample}/{ex_sample}_int2_trimmed_r1.fastq.gz"
TRIM_FASTQ_INT2_R2 = "tmp/ex/{ex_sample}/{ex_sample}_int2_trimmed_r2.fastq.gz"
TRIMMED_FASTQ_R1 = "tmp/ex/{ex_sample}/{ex_sample}_trimmed_r1.fastq.gz"
TRIMMED_FASTQ_R2 = "tmp/ex/{ex_sample}/{ex_sample}_trimmed_r2.fastq.gz"

FILTERED_FASTQ_R1 = "tmp/ex/{ex_sample}/{ex_sample}_filtered_r1.fastq.gz"
FILTERED_FASTQ_R2 = "tmp/ex/{ex_sample}/{ex_sample}_filtered_r2.fastq.gz"

# Alignment

RAW_SAM = "tmp/ex/{ex_sample}/{ex_sample}_raw_alignment.sam"
RAW_BAM = "tmp/ex/{ex_sample}/{ex_sample}_raw_alignment.bam"

FILTERED_BAM = "tmp/ex/{ex_sample}/{ex_sample}_filtered_alignment.bam"

READ_GROUP_BAM = "tmp/ex/{ex_sample}/{ex_sample}_read_group_alignment.bam"

ADD_MATE_INFORMATION_INT = "tmp/ex/{ex_sample}/{ex_sample}_int_annotated_alignment.bam"
MATE_INFO_BAM = "tmp/ex/{ex_sample}/{ex_sample}_annotated_alignment.bam"

GROUP_BY_UMI_INT1 = "tmp/ex/{ex_sample}/{ex_sample}_int1_umi_grouped_alignment.bam"
GROUP_BY_UMI_INT2 = "tmp/ex/{ex_sample}/{ex_sample}_int2_umi_grouped_alignment.bam"
UMI_GROUPED_BAM = "tmp/ex/{ex_sample}/{ex_sample}_umi_grouped_alignment.bam"

# Duplex consensus

RAW_DSC = "tmp/ex/{ex_sample}/{ex_sample}_raw_dsc.bam"

REALIGN_DSC_INT1 = "tmp/ex/{ex_sample}/{ex_sample}_int1_realigned_dsc.fastq"
REALIGN_DSC_INT2 = "tmp/ex/{ex_sample}/{ex_sample}_int2_realigned_dsc.sam"
REALIGN_DSC_INT3 = "tmp/ex/{ex_sample}/{ex_sample}_int3_realigned_dsc.bam"
REALIGNED_DSC = "tmp/ex/{ex_sample}/{ex_sample}_realigned_dsc.bam"

ANNOTATE_DSC_INT1 = "tmp/ex/{ex_sample}/{ex_sample}_int1_annotated_dsc.bam"
ANNOTATED_DSC = "tmp/ex/{ex_sample}/{ex_sample}_annotated_dsc.bam"
ANNOTATED_DSC_INDEX = "tmp/ex/{ex_sample}/{ex_sample}_annotated_dsc.bam.bai"

FILTER_DSC_INT1 = "tmp/ex/{ex_sample}/{ex_sample}_int1_filtered_dsc.bam"
FILTERED_DSC = "tmp/ex/{ex_sample}/{ex_sample}_filtered_dsc.bam"
FILTERED_DSC_INDEX = "tmp/ex/{ex_sample}/{ex_sample}_filtered_dsc.bam.bai"

# Variant calling

CALL_SOMATIC_SNV_INT1 = "tmp/ex/{ex_sample}/{ex_sample}_bcf_mpileup.bcf"
CALL_SOMATIC_SNV_INT2 = "tmp/ex/{ex_sample}/{ex_sample}_bcf_called.bcf"
CALL_SOMATIC_SNV_INT3 = "tmp/ex/{ex_sample}/{ex_sample}_all_positions.vcf"
CALL_SOMATIC_SNV_INT4 = "tmp/ex/{ex_sample}/{ex_sample}_bcf_biallelic.bcf"
CALLED_SNVS = "results/{ex_sample}/{ex_sample}_called_snvs.vcf"

# ---------------------------------------------------------------------------------------------------------------
# Metrics
# ---------------------------------------------------------------------------------------------------------------

# Preprocess FASTQ

MET_FASTQC_RAW_HTML_R1 = "metrics/ex/{ex_lane}/{ex_lane}_fastqc_raw_metrics_r1.html"
MET_FASTQC_RAW_HTML_R2 = "metrics/ex/{ex_lane}/{ex_lane}_fastqc_raw_metrics_r2.html"
MET_FASTQC_RAW_TXT_R1 = "metrics/ex/{ex_lane}/{ex_lane}_fastqc_raw_metrics_r1.txt"
MET_FASTQC_RAW_TXT_R2 = "metrics/ex/{ex_lane}/{ex_lane}_fastqc_raw_metrics_r2.txt"
MET_FASTQC_RAW_INT_R1 = "metrics/ex/{ex_lane}/{ex_lane}_fastqc_raw_metrics_r1.zip"
MET_FASTQC_RAW_INT_R2 = "metrics/ex/{ex_lane}/{ex_lane}_fastqc_raw_metrics_r2.zip"
MET_FASTQC_RAW_SUMMARY_R1 = "metrics/ex/{ex_lane}/{ex_lane}_fastqc_raw_metrics_summary_r1.json"
MET_FASTQC_RAW_SUMMARY_R2 = "metrics/ex/{ex_lane}/{ex_lane}_fastqc_raw_metrics_summary_r2.json"

MET_DEMULIPLEX_FASTQ = "metrics/ex/{ex_lane}/{ex_lane}_demux_metrics.txt"

MET_DEMUX_COUNTS_GINI = "metrics/ex/{ex_lane}/{ex_lane}_demux_counts_and_gini.json"

MET_TRIM_FASTQ = "metrics/ex/{ex_sample}/{ex_sample}_trim_metrics.txt"

MET_TRIM_SUMMARY = "metrics/ex/{ex_sample}/{ex_sample}_trim_metrics_summary.json"

MET_FILTER_FASTQ = "metrics/ex/{ex_sample}/{ex_sample}_filter_metrics.txt"

MET_FASTQC_FILTER_HTML_R1 = "metrics/ex/{ex_sample}/{ex_sample}_fastqc_filter_metrics_r1.html"
MET_FASTQC_FILTER_HTML_R2 = "metrics/ex/{ex_sample}/{ex_sample}_fastqc_filter_metrics_r2.html"
MET_FASTQC_FILTER_TXT_R1 = "metrics/ex/{ex_sample}/{ex_sample}_fastqc_filter_metrics_r1.txt"
MET_FASTQC_FILTER_TXT_R2 = "metrics/ex/{ex_sample}/{ex_sample}_fastqc_filter_metrics_r2.txt"
MET_FASTQC_FILTER_INT_R1 = "metrics/ex/{ex_sample}/{ex_sample}_fastqc_filter_metrics_r1.zip"
MET_FASTQC_FILTER_INT_R2 = "metrics/ex/{ex_sample}/{ex_sample}_fastqc_filter_metrics_r2.zip"
MET_FASTQC_FILTER_SUMMARY_R1 = "metrics/ex/{ex_sample}/{ex_sample}_fastqc_filter_metrics_summary_r1.json"
MET_FASTQC_FILTER_SUMMARY_R2 = "metrics/ex/{ex_sample}/{ex_sample}_fastqc_filter_metrics_summary_r2.json"

# Alignment

MET_ALIGNMENT = "metrics/ex/{ex_sample}/{ex_sample}_alignment_metrics.txt"

MET_MULTIMAPPING_RAW = "metrics/ex/{ex_sample}/{ex_sample}_multimapping_raw_metrics.json"

MET_INSERT_SIZE_TXT = "metrics/ex/{ex_sample}/{ex_sample}_insert_metrics.txt"
MET_INSERT_SIZE_PDF = "metrics/ex/{ex_sample}/{ex_sample}_insert_metrics.pdf"

MET_GROUP_BY_UMI = "metrics/ex/{ex_sample}/{ex_sample}_map_umi_metrics.txt"

MET_DUPLICATION = "metrics/ex/{ex_sample}/{ex_sample}_duplication_metrics.json"

# Duplex consensus

MET_CALL_DSC = "metrics/ex/{ex_sample}/{ex_sample}_call_dsc_metrics.txt"

MET_CALL_DSC_READ_LOSS = "metrics/ex/{ex_sample}/{ex_sample}_call_dsc_read_loss.json"

MET_DSC_REMAP = "metrics/ex/{ex_sample}/{ex_sample}_dsc_remap_metrics.json"

MET_MULTIMAPPING_DSC = "metrics/ex/{ex_sample}/{ex_sample}_multimapping_dsc_metrics.json"

MET_DUPLEX_OVERLAP = "metrics/ex/{ex_sample}/{ex_sample}_duplex_overlap_metrics.json"

MET_DSC_DEPTH = "metrics/ex/{ex_sample}/{ex_sample}_dsc_depth_metrics.json"
MET_DSC_COVERAGE_JSON = "metrics/ex/{ex_sample}/{ex_sample}_dsc_coverage_metrics.json"
MET_DSC_COVERAGE_PLOT = "metrics/ex/{ex_sample}/{ex_sample}_dsc_coverage_plot.html"
MET_COVERAGE_OVERLAP = "metrics/ex/{ex_sample}/{ex_sample}_dsc_coverage_overlap_metrics.json"

MET_SOFTCLIPPING = "metrics/ex/{ex_sample}/{ex_sample}_softclipping_metrics.json"

MET_TOTAL_READ_LOSS = "metrics/ex/{ex_sample}/{ex_sample}_total_read_loss.json"

MET_VAR_CALL_DISAGREE = "metrics/ex/{ex_sample}/{ex_sample}_variant_call_disagree_metrics.json"

# Variant calling

MET_SOMATIC_VARIANT_RATE = "results/{ex_sample}/{ex_sample}_somatic_variant_rate.json"
MET_CHROM_VARIANT_RATE = "results/{ex_sample}/{ex_sample}_chromosomal_variant_rate_metrics.json"

MET_TRINUC_PROPORTIONS = "results/{ex_sample}/{ex_sample}_trinuc_proportions.csv"
MET_TRINUC_SIMILARITIES = "results/{ex_sample}/{ex_sample}_trinuc_similarities.csv"
MET_TRINUC_PLOTS = "results/{ex_sample}/{ex_sample}_trinuc_plots_normalised.pdf"

MET_SNV_DISTANCE = "results/{ex_sample}/{ex_sample}_snv_distance_metrics.json"
MET_SNV_POSITION_JSON = "results/{ex_sample}/{ex_sample}_snv_position_metrics.json"
MET_SNV_POSITION_PDF = "results/{ex_sample}/{ex_sample}_snv_position_plot.pdf"

MET_GNOMAD_OVERLAP_VCF = "results/{ex_sample}/{ex_sample}_gnomad_matches.vcf"
MET_GNOMAD_OVERLAP_JSON = "results/{ex_sample}/{ex_sample}_gnomad_overlap_metrics.json"
MET_GNOMAD_OVERLAP_INT_BGZ = "tmp/ex/{ex_sample}/{ex_sample}_int_gnomad_overlap.bgz"
MET_GNOMAD_OVERLAP_INT_TBI = "tmp/ex/{ex_sample}/{ex_sample}_int_gnomad_overlap.bgz.tbi"

MET_SNV_GERMLINE_CONTEXT = "results/{ex_sample}/{ex_sample}_somatic_variant_germline_contexts.vcf"

MET_RECURRENT_VARIANTS_VCF = "results/batch/batch_recurrent_variants.vcf"
MET_RECURRENT_VARIANTS_JSON = "results/batch/batch_recurrent_variant_metrics.json"


