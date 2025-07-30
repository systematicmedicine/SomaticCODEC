# ---
# --- get_metrics.R ---
# 
# Collection of R functions to collect key metrics from codec-opensource/metrics
# 
# Authors: 
#     - Joshua Johnstone
#     - Ben Barry
#     - Chat-GPT
#     - Cameron Fraser
# ---

# Gets the path to the relevant metrics file
find_metric_file_path <- function(sample_dir, function_metric, component_metrics) {
  pattern <- paste(
    component_metrics$metrics_file[grepl(paste0(function_metric, "$"), component_metrics$metric)],
    collapse = "|")
  list.files(sample_dir, pattern = pattern, full.names = TRUE)
}

# Loops through each sample and collects the relevant metric
process_samples_for_metric <- function(function_metric, metric_retrieval) {
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    print(sample_name)
    
    metric_file_path <- find_metric_file_path(sample_dir, function_metric, component_metrics)
    
    if (length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }

    metric_value <- metric_retrieval(metric_file_path, function_metric, sample_name, sample_dir)
    
    results <- rbind(results, data.frame(
      metric = function_metric,
      sample = sample_name,
      value = round(metric_value, digits = 2)
    ))
  }
  
  return(results)
}

# Extracts a specific section from a fastqc_data.txt file
extract_fastqc_section <- function(metric_file_path, function_metric, sample_name, section_header) {
  tmp_dir <- file.path("metrics/tmp", function_metric, sample_name)
  if (!dir.exists(tmp_dir)) dir.create(tmp_dir, recursive = TRUE)
  
  zip_contents <- unzip(metric_file_path, list = TRUE)$Name
  fastqc_data_inside_zip <- zip_contents[grepl("fastqc_data.txt$", zip_contents)][1]
  unzip(metric_file_path, files = fastqc_data_inside_zip, exdir = tmp_dir)
  
  fastqc_data_path <- file.path(tmp_dir, fastqc_data_inside_zip)
  fastqc_data_lines <- readLines(fastqc_data_path)
  
  start_line <- grep(paste0("^", section_header), fastqc_data_lines)
  end_lines <- grep("^>>END_MODULE", fastqc_data_lines)
  end_line <- end_lines[which(end_lines > start_line)[1]]

  # Extract header line + data lines
  header_line <- fastqc_data_lines[start_line + 1]
  data_lines <- fastqc_data_lines[(start_line + 2):(end_line - 1)]
  
  # Combine header and data lines for proper parsing downstream
  section_lines <- c(header_line, data_lines)
  
  return(section_lines)
}


# Get peak of per sequence quality score distribution for raw r1
get_per_sequence_quality_score_r1 <- function() {
  
  # Define function metric and print for logging
  function_metric = "per_sequence_quality_score_r1"
  print(paste("Getting", function_metric))
  
  # Define metric retrieval function
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    section_lines <- extract_fastqc_section(metric_file_path, function_metric, sample_name, ">>Per sequence quality scores")
    
    quality_df <- read.table(text = section_lines, header = FALSE)
    colnames(quality_df) <- c("Quality", "Count")
    
    peak_quality <- round(quality_df$Quality[which.max(quality_df$Count)], digits = 1)
    return(peak_quality)
  }
  
  # Process samples and collect results
  results <- process_samples_for_metric(function_metric, metric_retrieval)
  return(results)
}

# Get peak of per sequence quality score distribution for raw r2
get_per_sequence_quality_score_r2 <- function() {
  
  # Define function metric and print for logging
  function_metric = "per_sequence_quality_score_r2"
  print(paste("Getting", function_metric))
  
  # Define metric retrieval function
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    section_lines <- extract_fastqc_section(metric_file_path, function_metric, sample_name, ">>Per sequence quality scores")
    
    quality_df <- read.table(text = section_lines, header = FALSE)
    colnames(quality_df) <- c("Quality", "Count")
    
    peak_quality <- round(quality_df$Quality[which.max(quality_df$Count)], digits = 1)
    return(peak_quality)
  }
  
  # Process samples and collect results
  results <- process_samples_for_metric(function_metric, metric_retrieval)
  return(results)
}

# Get percent reads filtered out during processing
get_percent_reads_filtered <- function() {
  
  # Define function metric and print for logging
  function_metric = "percent_reads_filtered"
  print(paste("Getting", function_metric))
  
  # Define metric retrieval function
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    cutadapt <- read.delim(metric_file_path)
    total_reads <- as.numeric(cutadapt$in_reads)
    written_reads <- as.numeric(cutadapt$out_reads)
    
    # Calculate percent filtered
    percent_reads_filtered <- round((1 - written_reads / total_reads) * 100, digits = 1)
    return(percent_reads_filtered)
  }
  
  # Process samples and collect results
  results <- process_samples_for_metric(function_metric, metric_retrieval)
  return(results)
}

# Get percent reads filtered out due to length
get_percent_reads_filtered_readlength <- function() {
  
  function_metric <- "percent_reads_filtered_readlength"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    cutadapt <- fromJSON(metric_file_path)
    total_reads <- as.numeric(cutadapt$summary$before_filtering$total_reads)
    too_short_reads <- as.numeric(cutadapt$filtering_result$too_short_reads)
    percent_reads_filtered_readlength <- round((too_short_reads / total_reads) * 100, digits = 1)
    return(percent_reads_filtered_readlength)
  }
  
  results <- process_samples_for_metric(function_metric, metric_retrieval)
  return(results)
}

# Get percent reads filtered out due to low mean quality
get_percent_reads_filtered_meanquality <- function() {
  
  function_metric <- "percent_reads_filtered_meanquality"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    cutadapt <- fromJSON(metric_file_path)
    total_reads <- as.numeric(cutadapt$summary$before_filtering$total_reads)
    low_quality_reads <- as.numeric(cutadapt$filtering_result$low_quality_reads)
    percent_reads_filtered_meanquality <- round((low_quality_reads / total_reads) * 100, digits = 1)
    return(percent_reads_filtered_meanquality)
  }
  
  results <- process_samples_for_metric(function_metric, metric_retrieval)
  return(results)
}

# Get read alignment rate
get_read_alignment_rate <- function() {
  
  function_metric <- "read_alignment_rate"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    
    alignment_stats_lines <- readLines(metric_file_path)
    
    if (any(grepl("_alignment_stats\\.txt$", metric_file_path))) {
      total_reads <- as.numeric(sub("SN\\s+sequences:\\s+", "", 
                                    grep("^SN\\s+sequences:", alignment_stats_lines, value = TRUE)))
      reads_aligned <- as.numeric(sub("SN\\s+reads mapped:\\s+", "", 
                                      grep("^SN\\s+reads mapped:", alignment_stats_lines, value = TRUE)))
    } else {
      total_reads <- as.numeric(sub(" .*", "", grep("in total", alignment_stats_lines, value = TRUE)))
      reads_aligned <- as.numeric(sub(" .*", "", grep("mapped \\(", alignment_stats_lines, value = TRUE)))[1]
    }
    
    alignment_rate <- round((reads_aligned / total_reads) * 100, digits = 2)
    return(alignment_rate)
  }
  
  results <- process_samples_for_metric(function_metric, metric_retrieval)
  return(results)
}

# Get percentage of reference genome masked by combined mask
get_mask_coverage <- function() {
  
  function_metric <- "mask_coverage"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    mask_metrics_lines <- readLines(metric_file_path)
    combined_mask_line <- grep("combined_mask\\.bed", mask_metrics_lines, value = TRUE)
    percent_coverage <- round(
      as.numeric(sub("%", "", strsplit(combined_mask_line, "\t")[[1]][3])),
      digits = 1
    )
    return(percent_coverage)
  }
  
  results <- process_samples_for_metric(function_metric, metric_retrieval)
  return(results)
}

# Get percentage of reads contributed by each sample
get_percent_read_contribution <- function() {
  
  function_metric <- "percent_read_contribution"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    demux_metrics <- fromJSON(metric_file_path)
    r1 <- demux_metrics$adapters_read1
    r2 <- demux_metrics$adapters_read2
    r1$read <- "r1"
    r2$read <- "r2"
    
    combined <- rbind(
      r1[, c("name", "total_matches", "read")],
      r2[, c("name", "total_matches", "read")]
    )
    
    adaptor_counts <- aggregate(total_matches ~ name, data = combined, sum)
    total_adaptors <- sum(adaptor_counts$total_matches)
    adaptor_counts$percent_contrib <- (adaptor_counts$total_matches / total_adaptors) * 100
    percent_contrib_diff <- max(adaptor_counts$percent_contrib) - min(adaptor_counts$percent_contrib)
    
    return(round(percent_contrib_diff, 1))
  }
  
  results <- process_samples_for_metric(function_metric, metric_retrieval)
  return(results)
}

# Get correct product ratio
get_correct_product_ratio <- function() {
  
  function_metric <- "correct_product_ratio"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    correct_product_metrics <- read.delim(metric_file_path)
    correct_product_ratio <- round(
      as.numeric(correct_product_metrics$correct_aligned_. / 100),
      digits = 2
    )
    return(correct_product_ratio)
  }
  
  results <- process_samples_for_metric(function_metric, metric_retrieval)
  return(results)
}

# Get duplex coverage
get_duplex_coverage <- function() {
  
  function_metric <- "duplex_coverage"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    dsc_depth_metrics_lines <- readLines(metric_file_path)
    data_line <- grep("^ex_dsc_coverage_wholegenome", dsc_depth_metrics_lines, value = TRUE)
    duplex_coverage <- round(
      as.numeric(sub("%", "", strsplit(data_line, "\t")[[1]][2])),
      digits = 1
    )
    return(duplex_coverage)
  }
  
  results <- process_samples_for_metric(function_metric, metric_retrieval)
  return(results)
}

# Get mean analyzable duplex depth
get_mean_analyzable_duplex_depth <- function() {
  
  function_metric <- "mean_analyzable_duplex_depth"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    dsc_depth_metrics_lines <- readLines(metric_file_path)
    data_line <- grep("^ex_mean_analyzable_duplex_depth", dsc_depth_metrics_lines, value = TRUE)
    mean_analyzable_duplex_depth <- round(
      as.numeric(strsplit(data_line, "\t")[[1]][2]),
      digits = 1
    )
    return(mean_analyzable_duplex_depth)
  }
  
  results <- process_samples_for_metric(function_metric, metric_retrieval)
  return(results)
}

# Get percentage of genome eligible for variant calling
get_variant_call_eligible <- function() {
  
  function_metric <- "variant_call_eligible"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    dsc_depth_metrics_lines <- readLines(metric_file_path)
    data_line <- grep("^ex_dsc_coverage_bedregions", dsc_depth_metrics_lines, value = TRUE)
    variant_call_eligible <- round(
      as.numeric(sub("%", "", strsplit(data_line, "\t")[[1]][2])),
      digits = 1
    )
    return(variant_call_eligible)
  }
  
  results <- process_samples_for_metric(function_metric, metric_retrieval)
  return(results)
}

# Get duplex realignment
get_duplex_realignment <- function() {
  
  function_metric <- "duplex_realignment"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    dsc_remap_metrics_lines <- readLines(metric_file_path)
    data_line <- grep("^Percentage mapped", dsc_remap_metrics_lines, value = TRUE)
    duplex_realignment <- round(
      as.numeric(sub("%", "", strsplit(data_line, "\t")[[1]][2])),
      digits = 1
    )
    return(duplex_realignment)
  }
  
  results <- process_samples_for_metric(function_metric, metric_retrieval)
  return(results)
}

# Get duplex reads with MAPQ > 60
get_duplex_mapQ <- function() {
  
  function_metric <- "duplex_mapQ"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    dsc_remap_metrics_lines <- readLines(metric_file_path)
    data_line <- grep("^Percentage with MAPQ ≥ 60 (of mapped)", dsc_remap_metrics_lines, value = TRUE)
    duplex_mapQ <- round(
      as.numeric(sub("%", "", strsplit(data_line, "\t")[[1]][2])),
      digits = 1
    )
    return(duplex_mapQ)
  }
  
  results <- process_samples_for_metric(function_metric, metric_retrieval)
  return(results)
}

# Get germline variant call metrics
get_germline_variants <- function() {
  
  function_metric <- "germline_variants"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    lines <- readLines(metric_file_path)
    
    SN_data <- grep("^SN\t", lines, value = TRUE)
    df <- read.delim(textConnection(SN_data), header = TRUE)
    colnames(df) <- c("SN", "ID", "key", "value")
    
    total_variants <- df %>%
      dplyr::filter(key == "number of records:") %>%
      dplyr::pull(value) %>%
      as.numeric()
    
    return(total_variants / 1e6)
  }
  
  results <- process_samples_for_metric(function_metric, metric_retrieval)
  return(results)
}

# Get ratio of SNVs to INDELs
get_SNV_indel_ratio <- function() {
  
  function_metric <- "SNV_indel_ratio"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    lines <- readLines(metric_file_path)
    
    SN_data <- grep("^SN\t", lines, value = TRUE)
    
    df <- read.delim(textConnection(SN_data), header = TRUE)
    colnames(df) <- c("SN", "ID", "key", "value")
    
    snp <- as.numeric(df$value[df$key == "number of SNPs:"])
    indel <- as.numeric(df$value[df$key == "number of indels:"])
    ratio <- round(snp / indel, digits = 1)
    return(ratio)
  }
  
  results <- process_samples_for_metric(function_metric, metric_retrieval)
  return(results)
}

# Get ratio of insertions to deletions
get_insertion_deletion_ratio <- function() {
  
  function_metric <- "insertion_deletion_ratio"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    lines <- readLines(metric_file_path)
    
    IDD_data <- grep("^IDD\t", lines, value = TRUE)
    
    df <- read.delim(textConnection(IDD_data), header = TRUE)
    colnames(df) <- c("IDD", "id", "indel_len", "num_sites", "genotypes", "mean_VAF")
    
    ins_del_count <- df %>%
      dplyr::select(indel_len, num_sites) %>%
      dplyr::mutate(type = dplyr::case_when(
        indel_len > 0 ~ "insertion",
        indel_len < 0 ~ "deletion",
        TRUE ~ NA_character_
      )) %>%
      dplyr::filter(!is.na(type)) %>%
      dplyr::group_by(type) %>%
      dplyr::summarise(count = sum(num_sites), .groups = "drop")
    
    ins_count <- ins_del_count$count[ins_del_count$type == "insertion"]
    del_count <- ins_del_count$count[ins_del_count$type == "deletion"]
    
    ratio <- round(ins_count / del_count, digits = 1)
    return(ratio)
  }
  
  results <- process_samples_for_metric(function_metric, metric_retrieval)
  return(results)
}

# Get number of MNPs/other variants
get_MNP_other_variants <- function() {
  
  function_metric <- "MNP_other_variants"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    lines <- readLines(metric_file_path)
    
    SN_data <- grep("^SN\t", lines, value = TRUE)
    
    df <- read.delim(textConnection(SN_data), header = TRUE)
    colnames(df) <- c("SN", "ID", "key", "value")
    
    MNP <- as.numeric(df$value[df$key == "number of MNPs:"])
    other <- as.numeric(df$value[df$key == "number of others:"])
    
    return(MNP + other)
  }
  
  results <- process_samples_for_metric(function_metric, metric_retrieval)
  return(results)
}

# Get ratio of transitions to transversions
get_transition_transversion_ratio <- function() {
  
  function_metric <- "transition_transversion_ratio"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    lines <- readLines(metric_file_path)
    
    TSTV_data <- grep("^TSTV", lines, value = TRUE)
    df <- read.delim(textConnection(TSTV_data), header = FALSE)
    colnames(df) <- c("TSTV", "id", "ts", "tv", "ts_tv", "ts_1st_alt", "tv_1st_alt", "ts_tv_1st_alt")
    
    ratio <- round(df$ts_tv, digits = 1)
    return(ratio)
  }
  
  results <- process_samples_for_metric(function_metric, metric_retrieval)
  return(results)
}

# Get ratio of het/hom variants
get_het_hom_ratio <- function() {
  
  function_metric <- "het_hom_ratio"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    lines <- readLines(metric_file_path)
    psc_line <- grep("^PSC", lines, value = TRUE)
    fields <- strsplit(psc_line, "\t")[[1]]
    het <- as.numeric(fields[6])
    hom <- as.numeric(fields[5])
    het_hom_ratio <- round(het / hom, digits = 1)
    return(het_hom_ratio)
  }
  
  results <- process_samples_for_metric(function_metric, metric_retrieval)
  return(results)
}

# Get multimapping rate
get_multimapping_rate <- function() {
  
  function_metric <- "multimapping_rate"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    alignment_stats_lines <- readLines(metric_file_path)
    
    if (any(grepl("_alignment_stats\\.txt$", metric_file_path))) {
      raw_total_sequences <- grep("^SN\\s+sequences:", alignment_stats_lines, value = TRUE) %>%
        sub("^SN\\s+sequences:", "", .) %>%
        as.numeric()
      
      reads_multimapped <- grep("^SN\tnon-primary alignments:", alignment_stats_lines, value = TRUE) %>%
        sub("SN\tnon-primary alignments:\t", "", .) %>%
        as.numeric()
    } else {
      raw_total_sequences <- grep("in total", alignment_stats_lines, value = TRUE) %>%
        sub(" .*", "", .) %>%
        as.numeric()
      
      reads_multimapped <- grep("secondary", alignment_stats_lines, value = TRUE) %>%
        sub(" .*", "", .) %>%
        as.numeric()
    }
    
    multimapping <- round((reads_multimapped / raw_total_sequences) * 100, digits = 1)
    return(multimapping)
  }
  
  results <- process_samples_for_metric(function_metric, metric_retrieval)
  return(results)
}

# Get duplication rate
get_duplication_rate <- function() {
  function_metric = "duplication_rate"
  print(paste("Getting", function_metric))
  
  # This assumes "metrics" directory contains a single metrics file for all samples
  metric_file_path <- find_metric_file_path("metrics", function_metric, component_metrics)
  
  if(length(metric_file_path) == 0) {
    # Return empty with NA if missing
    return(data.frame(metric = function_metric, sample = NA, value = NA))
  }
  
  df <- read.delim(metric_file_path, stringsAsFactors = FALSE)
  df$dup_rate_percent <- round(df$Duplication.rate * 100, digits = 2)
  
  results <- data.frame(
    metric = function_metric,
    sample = df$Sample,
    value = df$dup_rate_percent,
    stringsAsFactors = FALSE
  )
  
  return(results)
}

# Get total reads r1
get_total_reads_r1 <- function() {
  function_metric = "total_reads_r1"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    section <- extract_fastqc_section(metric_file_path, function_metric, sample_name, ">>Basic Statistics")
    
    df <- read.delim(text = section, header = FALSE, sep = "\t")
    total_reads <- as.numeric(df[df$V1 == "Total Sequences", "V2"]) / 1000000
    return(total_reads)
  }
  
  results <- process_samples_for_metric(function_metric, metric_retrieval)
  return(results)
}

# Get total reads r2
get_total_reads_r2 <- function() {
  function_metric = "total_reads_r2"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    section <- extract_fastqc_section(metric_file_path, function_metric, sample_name, ">>Basic Statistics")
    
    df <- read.delim(text = section, header = FALSE, sep = "\t")
    total_reads <- as.numeric(df[df$V1 == "Total Sequences", "V2"]) / 1000000
    return(total_reads)
  }
  
  results <- process_samples_for_metric(function_metric, metric_retrieval)
  return(results)
}

# Get mean insert size
get_insert_size <- function() {
  function_metric <- "insert_size"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    lines <- readLines(metric_file_path)
    table_start <- grep("^MEDIAN_INSERT_SIZE", lines)
    
    insert_metrics_table <- read.delim(metric_file_path,
                                       skip = table_start - 1,
                                       nrows = 1,
                                       header = TRUE)
    round(insert_metrics_table$MEAN_INSERT_SIZE, 1)
  }
  
  process_samples_for_metric(function_metric, metric_retrieval)
}

# Get overrespresented sequences in r1
get_overrepresented_sequences_r1 <- function() {
  function_metric <- "overrepresented_sequences_r1"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    section_lines <- extract_fastqc_section(metric_file_path, function_metric, sample_name, ">>Overrepresented sequences")
    
    if (any(grepl("pass", section_lines))) {
      return(0)
    }
    
    df <- read.delim(text = section_lines, header = TRUE)
    round(max(df$Percentage), 1)
  }
  
  process_samples_for_metric(function_metric, metric_retrieval)
}

# Get overrespresented sequences in r2
get_overrepresented_sequences_r2 <- function() {
  function_metric <- "overrepresented_sequences_r2"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    section_lines <- extract_fastqc_section(metric_file_path, function_metric, sample_name, ">>Overrepresented sequences")
    
    if (any(grepl("pass", section_lines))) {
      return(0)
    }
    
    df <- read.delim(text = section_lines, header = TRUE)
    round(max(df$Percentage), 1)
  }
  
  process_samples_for_metric(function_metric, metric_retrieval)
}

# Get devation from GC distribution r1
get_gc_deviation_r1 <- function() {
  function_metric <- "gc_deviation_r1"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    section_lines <- extract_fastqc_section(metric_file_path, function_metric, sample_name, ">>Per sequence GC content")
    gc_content_df <- read.delim(text = section_lines, header = TRUE)
    colnames(gc_content_df) <- c("GC_content", "Count")
    
    total_reads <- sum(gc_content_df$Count)
    mean_gc <- sum(gc_content_df$GC_content * gc_content_df$Count) / total_reads
    sd_gc <- sqrt(sum(gc_content_df$Count * (gc_content_df$GC_content - mean_gc)^2) / total_reads)
    
    expected_counts <- dnorm(gc_content_df$GC_content, mean = mean_gc, sd = sd_gc) * total_reads
    gc_deviation <- round(sum(abs(gc_content_df$Count - expected_counts)) / total_reads * 100, digits = 1)
    return(gc_deviation)
  }
  
  process_samples_for_metric(function_metric, metric_retrieval)
}

# Get devation from GC distribution r2
get_gc_deviation_r2 <- function() {
  function_metric <- "gc_deviation_r2"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    section_lines <- extract_fastqc_section(metric_file_path, function_metric, sample_name, ">>Per sequence GC content")
    gc_content_df <- read.delim(text = section_lines, header = TRUE)
    colnames(gc_content_df) <- c("GC_content", "Count")
    
    total_reads <- sum(gc_content_df$Count)
    mean_gc <- sum(gc_content_df$GC_content * gc_content_df$Count) / total_reads
    sd_gc <- sqrt(sum(gc_content_df$Count * (gc_content_df$GC_content - mean_gc)^2) / total_reads)
    
    expected_counts <- dnorm(gc_content_df$GC_content, mean = mean_gc, sd = sd_gc) * total_reads
    gc_deviation <- round(sum(abs(gc_content_df$Count - expected_counts)) / total_reads * 100, digits = 1)
    return(gc_deviation)
  }
  
  process_samples_for_metric(function_metric, metric_retrieval)
}

# Get per base sequence content difference r1
get_per_base_content_diff_r1 <- function() {
  function_metric <- "per_base_content_diff_r1"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    section_lines <- extract_fastqc_section(metric_file_path, function_metric, sample_name, ">>Per base sequence content")
    sequence_content_df <- read.delim(text = section_lines, skip = 1, header = TRUE)
    colnames(sequence_content_df) <- c("Base", "G", "A", "T", "C")
    
    # Calculate max difference between A and T or C and G per base
    diffs <- apply(sequence_content_df[, c("A", "T", "C", "G")], 1, function(row) {
      max(abs(row["A"] - row["T"]), abs(row["C"] - row["G"]))
    })
    
    round(max(diffs), digits = 1)
  }
  
  process_samples_for_metric(function_metric, metric_retrieval)
}

# Get per base sequence content difference r2
get_per_base_content_diff_r2 <- function() {
  function_metric <- "per_base_content_diff_r2"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    section_lines <- extract_fastqc_section(metric_file_path, function_metric, sample_name, ">>Per base sequence content")
    sequence_content_df <- read.delim(text = section_lines, header = TRUE)
    colnames(sequence_content_df) <- c("Base", "G", "A", "T", "C")
    
    diffs <- apply(sequence_content_df[, c("A", "T", "C", "G")], 1, function(row) {
      max(abs(row["A"] - row["T"]), abs(row["C"] - row["G"]))
    })
    
    round(max(diffs), digits = 1)
  }
  
  process_samples_for_metric(function_metric, metric_retrieval)
}

# Get per base sequence quality r1
get_per_base_sequencing_quality_r1 <- function() {
  function_metric <- "per_base_sequencing_quality_r1"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    section_lines <- extract_fastqc_section(metric_file_path, function_metric, sample_name, ">>Per base sequence quality")
    sequence_quality_df <- read.delim(text = section_lines, header = TRUE, sep = "\t", stringsAsFactors = FALSE)
    round(min(sequence_quality_df$Lower.Quartile), digits = 1)
  }
  
  process_samples_for_metric(function_metric, metric_retrieval)
}

# Get per base sequence quality r2
get_per_base_sequencing_quality_r2 <- function() {
  function_metric <- "per_base_sequencing_quality_r2"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    section_lines <- extract_fastqc_section(metric_file_path, function_metric, sample_name, ">>Per base sequence quality")
    sequence_quality_df <- read.delim(text = section_lines, header = TRUE, sep = "\t", stringsAsFactors = FALSE)
    round(min(sequence_quality_df$Lower.Quartile), digits = 1)
  }
  
  process_samples_for_metric(function_metric, metric_retrieval)
}

# Get per tile sequence quality r1
get_per_tile_sequencing_quality_r1 <- function() {
  function_metric <- "per_tile_sequencing_quality_r1"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    # Extract Per base sequence quality section for global mean
    base_section <- extract_fastqc_section(metric_file_path, function_metric, sample_name, ">>Per base sequence quality")
    base_df <- read.delim(text = base_section, header = TRUE)
    mean_seq_quality <- mean(base_df$Mean)
    
    # Extract Per tile sequence quality section
    tile_section <- extract_fastqc_section(metric_file_path, function_metric, sample_name, ">>Per tile sequence quality")
    
    tile_df <- read.delim(text = tile_section, header = TRUE)
    colnames(tile_df) <- c("tile", "base", "mean_deviation")
    tile_df$mean_qual_global <- mean_seq_quality
    tile_df$mean_qual_tile_pos <- tile_df$mean_qual_global + tile_df$mean_deviation
    
    library(dplyr)
    per_tile_quality <- tile_df %>%
      group_by(tile) %>%
      summarise(mean_quality = mean(mean_qual_tile_pos))
    
    num_tiles <- nrow(per_tile_quality)
    num_tiles_low_qual <- sum(per_tile_quality$mean_quality < 36)
    round((num_tiles_low_qual / num_tiles) * 100, digits = 1)
  }
  
  process_samples_for_metric(function_metric, metric_retrieval)
}

# Get per tile sequence quality r2
get_per_tile_sequencing_quality_r2 <- function() {
  function_metric <- "per_tile_sequencing_quality_r2"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    base_section <- extract_fastqc_section(metric_file_path, function_metric, sample_name, ">>Per base sequence quality")
    base_df <- read.delim(text = base_section, header = TRUE)
    mean_seq_quality <- mean(base_df$Mean)
    
    tile_section <- extract_fastqc_section(metric_file_path, function_metric, sample_name, ">>Per tile sequence quality")
    tile_df <- read.delim(text = tile_section, header = TRUE)
    colnames(tile_df) <- c("tile", "base", "mean_deviation")
    tile_df$mean_qual_global <- mean_seq_quality
    tile_df$mean_qual_tile_pos <- tile_df$mean_qual_global + tile_df$mean_deviation
    
    library(dplyr)
    per_tile_quality <- tile_df %>%
      group_by(tile) %>%
      summarise(mean_quality = mean(mean_qual_tile_pos))
    
    num_tiles <- nrow(per_tile_quality)
    num_tiles_low_qual <- sum(per_tile_quality$mean_quality < 36)
    round((num_tiles_low_qual / num_tiles) * 100, digits = 1)
  }
  
  process_samples_for_metric(function_metric, metric_retrieval)
}

# Get sequence length for r1
get_sequence_length_r1 <- function() {
  function_metric <- "sequence_length_r1"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    section_lines <- extract_fastqc_section(metric_file_path, function_metric, sample_name, ">>Sequence Length Distribution")
    seq_len_df <- read.delim(text = section_lines, header = TRUE)
    colnames(seq_len_df) <- c("Length", "Count")
    seq_len_df$Length[which.max(seq_len_df$Count)]
  }
  
  process_samples_for_metric(function_metric, metric_retrieval)
}

# Get sequence length for r2
get_sequence_length_r2 <- function() {
  function_metric <- "sequence_length_r2"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    section_lines <- extract_fastqc_section(metric_file_path, function_metric, sample_name, ">>Sequence Length Distribution")
    seq_len_df <- read.delim(text = section_lines, header = TRUE)
    colnames(seq_len_df) <- c("Length", "Count")
    seq_len_df$Length[which.max(seq_len_df$Count)]
  }
  
  process_samples_for_metric(function_metric, metric_retrieval)
}

# Get per base N content for r1
get_per_base_N_content_r1 <- function() {
  function_metric <- "per_base_N_content_r1"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    section_lines <- extract_fastqc_section(metric_file_path, function_metric, sample_name, ">>Per base N content")
    N_content_df <- read.delim(text = section_lines, header = TRUE)
    colnames(N_content_df) <- c("base", "percent_N")
    round(max(N_content_df$percent_N), digits = 2)
  }
  
  process_samples_for_metric(function_metric, metric_retrieval)
}

# Get per base N content for r2
get_per_base_N_content_r2 <- function() {
  function_metric <- "per_base_N_content_r2"
  print(paste("Getting", function_metric))
  
  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
    section_lines <- extract_fastqc_section(metric_file_path, function_metric, sample_name, ">>Per base N content")
    N_content_df <- read.delim(text = section_lines, header = TRUE)
    colnames(N_content_df) <- c("base", "percent_N")
    round(max(N_content_df$percent_N), digits = 2)
  }
  
  process_samples_for_metric(function_metric, metric_retrieval)
}

# Get number of soft clipped bases for 90th percentile most softclipped reads
get_dsc_softclipping <- function(){
  function_metric <- "dsc_softclipping"
  print(paste("Getting", function_metric))

  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
  soft_clip_stats <- fromJSON(metric_file_path)
  ninetieth_percentle <- as.numeric(soft_clip_stats$softclip_bases_per_read_percentiles[["90th_percentile"]])
  return(ninetieth_percentle)
  }

  process_samples_for_metric(function_metric, metric_retrieval)
}

# Get percentage of reads lost between start and end of ex pipeline
get_lane_total_read_loss <- function(){
  function_metric <- "lane_total_read_loss"
  print(paste("Getting", function_metric))

  metric_retrieval <- function(metric_file_path, function_metric, sample_name, sample_dir) {
  read_loss_stats <- fromJSON(metric_file_path)
  pct_lost <- as.numeric(read_loss_stats$percent_reads_lost)
  pct_lost <- round(pct_lost, 2)
  return(pct_lost)
  }

  process_samples_for_metric(function_metric, metric_retrieval)
}