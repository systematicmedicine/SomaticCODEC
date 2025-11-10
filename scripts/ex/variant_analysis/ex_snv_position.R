#!/usr/bin/env Rscript
# =============================================================================
#   ex_snv_position.R
#
#   Create a plot of the positional distribution of SNVs called by the pipeline
#  
#   Author: Cameron Fraser
#
# ==============================================================================


# ------------------------------------------------------------------------------
# Setup
# ------------------------------------------------------------------------------

# Load libraries
library(dplyr)
library(jsonlite)
library(ggplot2)
library(argparse)

# Snakemake parameter injection
parser <- ArgumentParser()
parser$add_argument("--vcf_path", required = TRUE)
parser$add_argument("--index_path", required = TRUE)
parser$add_argument("--metrics_json", required = TRUE)
parser$add_argument("--metrics_plot", required = TRUE)
parser$add_argument("--included_chroms", required = TRUE, nargs = "+")
parser$add_argument("--run_name", required = TRUE)
parser$add_argument("--log", required = TRUE)
args <- parser$parse_args()

VCF_PATH <- args$vcf_path
FAI_PATH <- args$index_path
METRICS_PATH <- args$metrics_json
PLOT_PATH <- args$metrics_plot
INCLUDED_CHROMS <- args$included_chroms
RUN_NAME <- args$run_name

LOG_PATH <- args$log

# Start logging
log_con <- file(LOG_PATH, open = "wt")
sink(log_con, type = "message")
message(sprintf("[INFO] Script started at %s\n", Sys.time()))


# ------------------------------------------------------------------------------
# Calculate genomic percentiles
# ------------------------------------------------------------------------------

genomic_percentiles <- function(fai_path, vcf_path){

    # Load reference genome FAI
    fai <- read.table(fai_path, header = FALSE, sep = "\t", stringsAsFactors = FALSE) %>%
    rename(Chrom = V1, Length = V2) %>%
    select(Chrom, Length) %>%
    filter(Chrom %in% INCLUDED_CHROMS)

    # Load SNV VCF
    vcf.header.line <- max(grep("^#CHROM", readLines(VCF_PATH)))

    vcf <- read.table(vcf_path, header = TRUE, sep = "\t", stringsAsFactors = FALSE, comment.char = "", skip = vcf.header.line - 1, check.names = FALSE) %>%
        rename(Chrom = `#CHROM`, Pos = POS) %>%
        select(Chrom, Pos) %>%
        left_join(fai, by = "Chrom") %>%
        mutate(Percentile = Pos / Length * 100)
}

snv.pos <- genomic_percentiles(FAI_PATH, VCF_PATH)


# ------------------------------------------------------------------------------
# Calculate mean absolute deviation
# ------------------------------------------------------------------------------

mad_vs_uniform <- function(genomic_percentiles){
    
    # Expected distribution
    expected <- seq(0, 100, length = length(genomic_percentiles))

    # Sort percentiles vector
    genomic_percentiles <- sort(genomic_percentiles)

    # Calulate MAD
    mad <- mean(abs(genomic_percentiles - expected))

    # Round
    mad <- round(mad, 2)

    # Return result
    return(mad)
}

chr.mad <- snv.pos %>%
    group_by(Chrom) %>%
    summarise(MAD = mad_vs_uniform(Percentile))


# ------------------------------------------------------------------------------
# Write out metrics file
# ------------------------------------------------------------------------------

metrics_json <- list(
  description = "For each SNV, genomic position percentiles were calculated (0 = start, 50 = middle, 100 = end). These percentiles were compared to a uniform distribution, and the mean absolute deviation calculated",
  chromosomes_MAD = setNames(as.list(chr.mad$MAD), chr.mad$Chrom),
  mean_MAD = mean(chr.mad$MAD, na.rm = TRUE),
  median_MAD = median(chr.mad$MAD, na.rm = TRUE),
  max_MAD = max(chr.mad$MAD, na.rm = TRUE),
  percentiles_MAD = setNames(as.list(quantile(chr.mad$MAD, probs = seq(0, 1, 0.1), na.rm = TRUE)), paste0(seq(0, 100, 10), "th"))
)

# Write JSON to disk
write_json(metrics_json, METRICS_PATH, pretty = TRUE, auto_unbox = TRUE)

# ------------------------------------------------------------------------------
# Create plot
# ------------------------------------------------------------------------------

plt <- ggplot(data = snv.pos, aes(x = Chrom, y = Percentile, colour = Chrom)) +
    geom_jitter(size = 0.5, alpha = 0.5, width = 0.1, height = 0) +
    scale_y_continuous(limits = c(0, 100.0)) +
    ggtitle(
        "Positional distribution of called SNVs", 
        paste(Sys.Date(), RUN_NAME)
        ) +
    xlab("") +
    ylab("Genomic percentile") +
    theme_classic() +
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1), 
        legend.position = "none")

# Write plot to disk
ggsave(PLOT_PATH, plt)


# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------

# Release logging
message(sprintf("[INFO] Script finished at %s\n", Sys.time()))
sink(type = "message")
close(log_con)