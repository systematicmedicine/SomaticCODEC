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

MET_FASTQC_RAW_HTML_R1 = "metrics/{ex_lane}/{ex_lane}_r1_fastqc_raw_metrics.html"
MET_FASTQC_RAW_HTML_R2 = "metrics/{ex_lane}/{ex_lane}_r2_fastqc_raw_metrics.html"
MET_FASTQC_RAW_TXT_R1 = "metrics/{ex_lane}/{ex_lane}_r1_fastqc_raw_metrics.txt"
MET_FASTQC_RAW_TXT_R2 = "metrics/{ex_lane}/{ex_lane}_r2_fastqc_raw_metrics.txt"
MET_FASTQC_RAW_INT_R1 = "metrics/{ex_lane}/{ex_lane}_r1_fastqc_raw_metrics.zip"
MET_FASTQC_RAW_INT_R2 = "metrics/{ex_lane}/{ex_lane}_r2_fastqc_raw_metrics.zip"

MET_FASTQC_RAW_SUMMARY_R1 = "metrics/{ex_lane}/{ex_lane}_r1_fastqc_raw_metrics_summary.json"
MET_FASTQC_RAW_SUMMARY_R2 = "metrics/{ex_lane}/{ex_lane}_r2_fastqc_raw_metrics_summary.json"

MET_DEMULIPLEX_FASTQ = "metrics/{ex_lane}/{ex_lane}_demux_metrics.txt"
MET_DEMUX_COUNTS_GINI = "metrics/{ex_lane}/{ex_lane}_demux_counts_and_gini.json"

MET_TRIM_FASTQ_TRIM5P = "metrics/{ex_sample}/{ex_sample}_trim_5prime_metrics.json"
MET_TRIM_FASTQ_TRIM3PR1 = "metrics/{ex_sample}/{ex_sample}_r1_trim_3prime_metrics.json"
MET_TRIM_FASTQ_TRIM3PR2 = "metrics/{ex_sample}/{ex_sample}_r2_trim_3prime_metrics.json"
MET_TRIM_READ_LENGTHS = "metrics/{ex_sample}/{ex_sample}_trimmed_read_length_metrics.json"
MET_BASES_TRIMMED = "metrics/{ex_sample}/{ex_sample}_bases_trimmed.json"

MET_FILTER_FASTQ = "metrics/{ex_sample}/{ex_sample}_filter_metrics_ex.txt"
MET_FASTQC_FILTER_HTML_R1 = "metrics/{ex_sample}/{ex_sample}_r1_fastqc_filter_metrics.html"
MET_FASTQC_FILTER_HTML_R2 = "metrics/{ex_sample}/{ex_sample}_r2_fastqc_filter_metrics.html"
MET_FASTQC_FILTER_TXT_R1 = "metrics/{ex_sample}/{ex_sample}_r1_fastqc_filter_metrics.txt"
MET_FASTQC_FILTER_TXT_R2 = "metrics/{ex_sample}/{ex_sample}_r2_fastqc_filter_metrics.txt"
MET_FASTQC_FILTER_INT_R1 = "metrics/{ex_sample}/{ex_sample}_r1_fastqc_filter_metrics.zip"
MET_FASTQC_FILTER_INT_R2 = "metrics/{ex_sample}/{ex_sample}_r2_fastqc_filter_metrics.zip"
MET_FASTQC_FILTER_SUMMARY_R1 = "metrics/{ex_sample}/{ex_sample}_r1_fastqc_filter_metrics_summary.json"
MET_FASTQC_FILTER_SUMMARY_R2 = "metrics/{ex_sample}/{ex_sample}_r2_fastqc_filter_metrics_summary.json"

# Alignment

MET_ALIGNMENT = "metrics/{ex_sample}/{ex_sample}_map_metrics.txt"
MET_INSERT_SIZE_TXT = "metrics/{ex_sample}/{ex_sample}_insert_metrics.txt"
MET_INSERT_SIZE_PDF = "metrics/{ex_sample}/{ex_sample}_insert_metrics.pdf"

MET_GROUP_BY_UMI = "metrics/{ex_sample}/{ex_sample}_map_umi_metrics.txt"

MET_DUPLICATION = "metrics/{ex_sample}/{ex_sample}_duplication_metrics.json"

# Duplex consensus

MET_CALL_DSC = "metrics/{ex_sample}/{ex_sample}_call_codec_consensus_metrics.txt"
MET_READS_LOST_CALL_DSC = "metrics/{ex_sample}/{ex_sample}_call_dsc_metrics.json"

MET_DSC_REMAP = "metrics/{ex_sample}/{ex_sample}_dsc_remap_metrics.json"

MET_DUPLEX_OVERLAP = "metrics/{ex_sample}/{ex_sample}_duplex_overlap_metrics.json"

MET_DSC_DEPTH = "metrics/{ex_sample}/{ex_sample}_depth_metrics.json"
MET_DSC_COVERAGE_JSON = "metrics/{ex_sample}/{ex_sample}_dsc_coverage_metrics.json"
MET_DSC_COVERAGE_PLOT = "metrics/{ex_sample}/{ex_sample}_dsc_coverage_plot.html"
MET_COVERAGE_OVERLAP = "metrics/{ex_sample}/{ex_sample}_coverage_overlap_metrics.json"

MET_SOFTCLIPPING = "metrics/{ex_sample}/{ex_sample}_softclipping_metrics.json"

MET_TOTAL_READ_LOSS = "metrics/{ex_sample}/{ex_sample}_total_read_loss.json"

MET_VAR_CALL_DISAGREE = "metrics/{ex_sample}/{ex_sample}_variant_call_disagree_metrics.json"

# Variant calling

MET_SOMATIC_VARIANT_RATE = "results/{ex_sample}/{ex_sample}_somatic_variant_rate.json"
MET_CHROM_VARIANT_RATE = "results/{ex_sample}/{ex_sample}_chromosomal_variant_rate_metrics.json"

MET_GNOMAD_OVERLAP_VCF = "results/{ex_sample}/{ex_sample}_germline_matches.vcf"
MET_GNOMAD_OVERLAP_JSON = "results/{ex_sample}/{ex_sample}_gnomAD_overlap_metrics.json"
MET_GNOMAD_OVERLAP_INT_BGZ = "tmp/{ex_sample}/{ex_sample}_indexed_somatic_vcf.bgz"
MET_GNOMAD_OVERLAP_INT_TBI = "tmp/{ex_sample}/{ex_sample}_indexed_somatic_vcf.bgz.tbi"

MET_RECURRENT_VARIANTS_VCF = "results/batch/batch_recurrent_variants.vcf"
MET_RECURRENT_VARIANTS_JSON = "results/batch/batch_recurrent_variant_metrics.json"

MET_SNV_DISTANCE = "results/{ex_sample}/{ex_sample}_snv_distance.json"
MET_SNV_POSITION_JSON = "results/{ex_sample}/{ex_sample}_snv_position_metrics.json"
MET_SNV_POSITION_PDF = "results/{ex_sample}/{ex_sample}_snv_position_plot.pdf"

MET_SNV_GERMLINE_CONTEXT = "results/{ex_sample}/{ex_sample}_somatic_variant_germline_contexts.vcf"

MET_TRINUC_PROPORTIONS = "results/{ex_sample}/{ex_sample}_trinuc_proportions.csv"
MET_TRINUC_SIMILARITIES = "results/{ex_sample}/{ex_sample}_trinuc_similarities.csv"
MET_TRINUC_PLOTS = "results/{ex_sample}/{ex_sample}_trinuc_plots_normalised.pdf"
