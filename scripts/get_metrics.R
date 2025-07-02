# ---
# --- get_metrics.R ---
# 
# Collection of R functions to collect key metrics from codec-opensource/metrics
# 
# Authors: 
#     - Joshua Johnstone
#     - Ben Barry
# ---

# Gets the path to the relevant metrics file
find_metric_file_path <- function(sample_dir, function_metric, component_metrics) {
  pattern <- paste(
    component_metrics$metrics_file[grepl(paste0(function_metric, "$"), component_metrics$metric)],
    collapse = "|")
  list.files(sample_dir, pattern = pattern, full.names = TRUE)
}

# Get peak of per sequence quality score distribution for raw r1
get_per_sequence_quality_score_r1 <- function() {
  
  # Store metric name
  function_metric = "per_sequence_quality_score_r1"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- find_metric_file_path(sample_dir, function_metric, component_metrics)
    
    # If missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip file
    zip_base <- basename(metric_file_path)
    zip_name <- sub("\\.zip$", "", zip_base)
    
    # Create tmp directory for unzipped file
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(metric_file_path, files = paste0(zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
    # Get path for unzipped data file
    fastqc_data_path <- file.path(tmp_dir, zip_name, "fastqc_data.txt")
    
    # Put all lines of txt file into character vector
    fastqc_data_lines <- readLines(fastqc_data_path)
    
    # Find start and end of the per sequence quality scores section
    start_line <- grep("^>>Per sequence quality scores", fastqc_data_lines)
    end_lines <- grep("^>>END_MODULE", fastqc_data_lines)
    end_line <- end_lines[which(end_lines > start_line)[1]]
    
    # Extract per sequence quality scores section lines (skip headers and end module lines)
    section_lines <- fastqc_data_lines[(start_line + 2):(end_line - 1)]
    
    # Parse to dataframe
    quality_df <- read.table(text = section_lines, header = FALSE)
    colnames(quality_df) <- c("Quality", "Count")
    
    # Get peak quality score
    peak_quality <- round(quality_df$Quality[which.max(quality_df$Count)], digits = 1)
    
    # Add to results
    results <- rbind(results, data.frame(metric = function_metric,
                                         sample = sample_name,
                                         value = peak_quality))
    
    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
    
  }
  
  return(results)
}

# Get peak of per sequence quality score distribution for raw r2
get_per_sequence_quality_score_r2 <- function() {
    
    # Store metric name
    function_metric = "per_sequence_quality_score_r2"
    
    # Print progress indicator
    print(paste("Getting", function_metric))
    
    # Get list of sample directories within metrics directory
    sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
    results <- data.frame(metric = character(), sample = character(), value = numeric())
    
    for (sample_dir in sample_dirs) {
      sample_name <- basename(sample_dir)
      
      # Print sample name for progress
      print(sample_name)
      
      # Get path to metrics file
      metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
      
      # If missing metrics file enter NA value, then skip sample
      if(length(metric_file_path) == 0) {
        results <- rbind(results, data.frame(
          metric = function_metric,
          sample = sample_name,
          value = NA
        ))
        next
      }
    
    # Unzip fastqc_data.txt from zip file (could standardise file names to simplify)
    zip_base <- basename(metric_file_path)
    zip_name <- sub("\\.zip$", "", zip_base)
    
    # Create tmp directory for unzipped file
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(metric_file_path, files = paste0(zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
    # Get path for unzipped metrics file
    fastqc_data_path <- file.path(tmp_dir, zip_name, "fastqc_data.txt")
    
    # Put all lines of txt file into character vector
    fastqc_data_lines <- readLines(fastqc_data_path)
    
    # Find start and end of the per sequence quality scores section
    start_line <- grep("^>>Per sequence quality scores", fastqc_data_lines)
    end_lines <- grep("^>>END_MODULE", fastqc_data_lines)
    end_line <- end_lines[which(end_lines > start_line)[1]]
    
    # Extract per sequence quality scores section lines (skip headers and end module lines)
    section_lines <- fastqc_data_lines[(start_line + 2):(end_line - 1)]
    
    # Parse to dataframe
    quality_df <- read.table(text = section_lines, header = FALSE)
    colnames(quality_df) <- c("Quality", "Count")
    
    # Get peak quality score
    peak_quality <- round(quality_df$Quality[which.max(quality_df$Count)], digits = 1)
    
    # Add to results
    results <- rbind(results, data.frame(metric = function_metric,
                                         sample = sample_name,
                                         value = peak_quality))
    
    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
    
  }
  
  return(results)
}

# Get percent reads filtered out during processing
get_percent_reads_filtered <- function() {
  
  # Store metric name
  function_metric = "percent_reads_filtered"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # If missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Read report lines
    cutadapt_lines <- readLines(metric_file_path)
    
    # Get total read pairs processed
    total_line <- grep("^Total read pairs processed:", cutadapt_lines, value = TRUE)
    total_reads <- as.numeric(gsub(",", "", sub("Total read pairs processed:\\s*", "", total_line)))
    
    # Extract "Reads written (passing filters)"
    written_line <- grep("^Reads written \\(passing filters\\):", cutadapt_lines, value = TRUE)
    written_reads <- as.numeric(gsub(",", "", sub(" .*", "", sub("Reads written \\(passing filters\\):\\s*", "", written_line))))
    
    # Calculate percent remaining
    percent_remaining <- round((written_reads / total_reads) * 100, digits = 1)
    
    # Add to results
    results <- rbind(results, data.frame(
      metric = function_metric,
      sample = sample_name,
      value = percent_remaining
    ))
  }
  
  return(results)
}

# Get read alignment rate
get_read_alignment_rate <- function() {
  
  # Store metric name
  function_metric = "read_alignment_rate"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # If missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Put all lines of txt file into character vector
    alignment_stats_lines <- readLines(metric_file_path)
    
    # Calculate alignment rate
    if(any(grepl("_alignment_stats\\.txt$", metric_file_path))){
      total_reads <- as.numeric(sub("SN	sequences:\t", "", 
                                    grep("^SN	sequences:", alignment_stats_lines, value = TRUE)))
      reads_aligned <- as.numeric(sub("SN	reads mapped:\t", "", 
                                      grep("^SN	reads mapped:", alignment_stats_lines, value = TRUE)))
    } else {
      total_reads <- as.numeric(sub(" .*", "", grep("in total", alignment_stats_lines, value = TRUE)))
      reads_aligned <- as.numeric(sub(" .*", "", grep("mapped \\(", alignment_stats_lines, value = TRUE)))
      
    }
    
    alignment_rate <- round((reads_aligned / total_reads) * 100, digits = 1)
    
    # Add to results
    results <- rbind(results, data.frame(
      metric = function_metric,
      sample = sample_name,
      value = alignment_rate
    ))
  }
  
  return(results)
}

# Get percentage of reference genome masked by combined mask
get_mask_coverage <- function(){
  
  # Store metric name
  function_metric = "mask_coverage"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # If missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Put all lines of txt file into character vector
    mask_metrics_lines <- readLines(metric_file_path)
    
    # Get percent coverage of combined mask
    combined_mask_line <- grep("^combined_mask\\.bed", mask_metrics_lines, value = TRUE)
    percent_coverage <- round(as.numeric(sub("%", "", 
                                             strsplit(combined_mask_line, "\t")[[1]][3])), digits = 1)
    
    # Add to results
    results <- rbind(results, data.frame(
      metric = function_metric,
      sample = sample_name,
      value = percent_coverage
    ))
  }
  
  return(results)
}

# Get percentage of reads contributed by each sample
get_percent_read_contribution <- function(){
  
  library(jsonlite)
  
  # Store metric name
  function_metric = "percent_read_contribution"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # If missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Pull json file contents into list
    demux_metrics <- fromJSON(metric_file_path)
    
    # Extract R1 and R2 adapter tables
    r1 <- demux_metrics$adapters_read1
    r2 <- demux_metrics$adapters_read2
    
    # Add read type column
    r1$read <- "r1"
    r2$read <- "r2"
    
    # Combine and group by name
    combined <- rbind(r1[, c("name", "total_matches", "read")],
                      r2[, c("name", "total_matches", "read")])
    
    # Aggregate total_matches per sample
    adaptor_counts <- aggregate(total_matches ~ name, data = combined, sum)
    
    total_adaptors <- sum(adaptor_counts$total_matches)
    sample_adaptors <- adaptor_counts$total_matches[adaptor_counts$name == sample_name]
    
    percent_contribution <- round((sample_adaptors / total_adaptors) * 100, digits = 1)
    
    results <- rbind(results, data.frame(
      metric = function_metric,
      sample = sample_name,
      value = percent_contribution
      ))
  }
  
  return(results)
}

# Get percentage of contaminating adaptors in each sample
get_percent_adaptor_contamination <- function(){
  
  # Store metric name
  function_metric = "percent_adaptor_contamination"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # If missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Pull metrics into data frame
    contamination_metrics <- read.delim(metric_file_path)
    
    # Get percent adaptor contamination
    percent_contamination <- format(round(as.numeric(sub("%", "", contamination_metrics$Percentage.of.demuxed[
      contamination_metrics$Sample == sample_name])), digits = 4), scientific = FALSE)
    
    # Add to results
    results <- rbind(results, data.frame(
      metric = function_metric,
      sample = sample_name,
      value = percent_contamination
    ))
  }
  
  return(results)
}

# Get correct product ratio
get_correct_product_ratio <- function(){
  
  # Store metric name
  function_metric = "correct_product_ratio"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # If missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Pull metrics into data frame
    correct_product_metrics <- read.delim(metric_file_path)
    
    # Get correct product ratio
    correct_product_ratio <- round(as.numeric(correct_product_metrics$correct_aligned_. / 100), 
                                   digits = 2)
    
    # Add to results
    results <- rbind(results, data.frame(
      metric = function_metric,
      sample = sample_name,
      value = correct_product_ratio
    ))
  }
  
  return(results)
}

# Get duplex coverage
get_duplex_coverage <- function(){
  
  # Store metric name
  function_metric = "duplex_coverage"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # If missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
   
   # Read lines and find line after header
   dsc_depth_metrics_lines <- readLines(metric_file_path)
   header_line <- grep("^GENOME_TERRITORY", dsc_depth_metrics_lines)
   data_line <- dsc_depth_metrics_lines[header_line + 1]
   
  # Get mean duplex coverage
   duplex_coverage <- round(as.numeric(strsplit(data_line, "\t")[[1]][2]), digits = 1)
   
   # Add to results
   results <- rbind(results, data.frame(
     metric = function_metric,
     sample = sample_name,
     value = duplex_coverage
   ))
  }
  return(results)
}

# Get germline variant call metrics
get_germline_variants <- function(){
  
  # Store metric name
  function_metric = "germline_variants"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # If missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # read file
    lines <- readLines(metric_file_path)
    
    # Get the data from "SN"
    SN_data <- grep(paste0("^", "SN", "\t"), lines, value = TRUE)
    
    #idenfity the line the data came from
    SN_info_index <- min(grep(paste("SN", "\t", sep=""), lines))
    
    # Clean the decription of the data
    SN_info <- gsub("\\[[0-9]+\\]", "", 
                    unlist(strsplit(gsub("# ", "", lines[SN_info_index]), "\t")))
    
    #parse into a DF
    df <- read.delim(textConnection(SN_data), header = FALSE, skip = 1, col.names = SN_info)
    
    #select the total variants
    total_variants <- df %>%
      filter(key == "number of records:") %>%
      pull(value) %>%
      as.numeric()
    
    #put into the results frame
    results <- rbind(results, data.frame(
      sample = sample_name,
      metric = function_metric,
      value = total_variants,
      stringsAsFactors = FALSE
    )
    )
    
  }
  return(results)
}

get_SNV_indel_ratio <- function(){
  
  # Store metric name
  function_metric = "SNV_indel_ratio"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # If missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # read file
    lines <- readLines(metric_file_path)
    
    # Get the data from "SN"
    SN_data <- grep(paste0("^", "SN", "\t"), lines, value = TRUE)
    
    #idenfity the line the data came from
    SN_info_index <- min(grep(paste("SN", "\t", sep=""), lines))
    
    # Clean the decription of the data
    SN_info <- gsub("\\[[0-9]+\\]", "", 
                    unlist(strsplit(gsub("# ", "", lines[SN_info_index]), "\t")))
    
    #parse into a DF
    df <- read.delim(textConnection(SN_data), header = FALSE, skip = 1, col.names = SN_info)
    
    
    # calculate the snv/indel ratio
    snp <- as.numeric(df$value[df$key == "number of SNPs:"])
    indel <- as.numeric(df$value[df$key == "number of indels:"])
    ratio <- round(snp / indel, digits = 1)
    
    #parse into results frame
    results <- rbind(results, data.frame(
      sample = sample_name,
      metric = function_metric,
      value = ratio,
      stringsAsFactors = FALSE
    )
    )
    
  }
  return(results)
}

get_insertion_deletion_ratio <- function(){
  
  # Store metric name
  function_metric = "insertion_deletion_ratio"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # If missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # read file
    lines <- readLines(metric_file_path)
    
    # Get the data from "SN"
    IDD_data <- grep(paste0("^", "IDD", "\t"), lines, value = TRUE)
    
    #idenfity the line the data came from
    IDD_info_index <- min(grep(paste("IDD", "\t", sep=""), lines))
    
    # Clean the decription of the data
    IDD_info <- gsub("\\[[0-9]+\\]", "", 
                     unlist(strsplit(gsub("# ", "", lines[IDD_info_index]), "\t")))
    
    #parse into a DF
    df <- read.delim(textConnection(IDD_data), header = FALSE, skip = 1, col.names = IDD_info) %>%
      rename(indel_len = `length..deletions.negative.`)
    
    #select the total variants
    insetions_deletions <- df %>%
      dplyr::select(indel_len, `number.of.sites`)
    
    #count insertions and deletions 
    ins_del_count <- insetions_deletions %>%
      dplyr::mutate(type = case_when(
        indel_len > 0 ~ "insertion",
        indel_len < 0 ~ "deletion")
      ) %>%
      dplyr::group_by(type) %>%
      dplyr::summarise(count = sum(number.of.sites)) %>%
      dplyr::ungroup()
    
    ins_count <- ins_del_count$count[ins_del_count$type == "insertion"]
    del_count <- ins_del_count$count[ins_del_count$type == "deletion"]
    ratio <- round(ins_count/del_count, digits = 1)
    
    #put into the results frame
    results <- rbind(results, data.frame(
      sample = sample_name,
      metric = function_metric,
      value = ins_count/del_count,
      stringsAsFactors = FALSE
    )
    )
    
  }
  return(results)
}

get_MNP_other_variants <- function(){
  
  # Store metric name
  function_metric = "MNP_other_variants"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # If missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # read file
    lines <- readLines(metric_file_path)
    
    # Get the data from "SN"
    SN_data <- grep(paste0("^", "SN", "\t"), lines, value = TRUE)
    
    #idenfity the line the data came from
    SN_info_index <- min(grep(paste("SN", "\t", sep=""), lines))
    
    # Clean the decription of the data
    SN_info <- gsub("\\[[0-9]+\\]", "", 
                    unlist(strsplit(gsub("# ", "", lines[SN_info_index]), "\t")))
    
    #parse into a DF
    df <- read.delim(textConnection(SN_data), header = FALSE, skip = 1, col.names = SN_info)
    
    #select the total variants
    MNP <- df$value[df$key == "number of MNPs:"]
    other <- df$value[df$key == "number of others:"]
    
    #put into the results frame
    results <- rbind(results, data.frame(
      sample = sample_name,
      metric = function_metric,
      value = MNP + other,
      stringsAsFactors = FALSE
    )
    )
    
  }
  return(results)
} 

get_transition_transversion_ratio <- function(){
  
  # Store metric name
  function_metric = "transition_transversion_ratio"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # If missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # read file
    lines <- readLines(metric_file_path)
    
    # Get the data from "SN"
    TSTV_data <- grep(paste0("^", "TSTV", "\t"), lines, value = TRUE)
    
    #idenfity the line the data came from
    TSTV_info_index <- min(grep(paste("TSTV", "\t", sep=""), lines))
    
    # Clean the decription of the data
    TSTV_info <- gsub("\\[[0-9]+\\]", "", 
                      unlist(strsplit(gsub("# ", "", lines[TSTV_info_index]), "\t")))
    
    #parse into a DF
    df <- read.delim(textConnection(TSTV_data), header = FALSE, col.names = TSTV_info)
    ratio <- round(df$ts.tv[1], digits = 1)
    
    
    #put into the results frame
    results <- rbind(results, data.frame(
      sample = sample_name,
      metric = function_metric,
      value = ratio,
      stringsAsFactors = FALSE
    )
    )
  }
  return(results)
} 

get_het_hom_ratio <- function(){
  
  # Store metric name
  function_metric = "het_hom_ratio"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # If missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    #read file to df
    df <- read.delim(metric_file_path, sep = "\t")
    ratio <- round(df$ratio, digits = 1)
    
    #add key metrics to results format  
    results <- rbind(results, data.frame(
      sample = sample_name,
      metric = function_metric,
      value = ratio)
    ) 
    
  }
  return(results)
}

# Get read multimapping rate
get_multimapping_rate <- function() {
  
  # Store metric name
  function_metric = "multimapping_rate"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # If missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Put all lines of txt file into character vector
    alignment_stats_lines <- readLines(metric_file_path)
    
    # extract the total raw sequences and the multimapped 
    if(any(grepl("_alignment_stats\\.txt$", metric_file_path))){
      
      raw_total_sequences <- grep("^SN\\s+sequences:", alignment_stats_lines, value = TRUE) %>%
        sub(pattern = "^SN\\s+sequences:", replacement = "") %>%
        as.numeric()
      
      
      reads_multimapped <- grep("^SN\tnon-primary alignments:", alignment_stats_lines, value = TRUE) %>%
        sub(pattern = "SN\tnon-primary alignments:\t", replacement = "") %>%
        as.numeric()
    } 
    
    else {
      
      raw_total_sequences <- grep("in total", alignment_stats_lines, value = TRUE) %>%
        sub(pattern = " .*", replacement = "") %>%
        as.numeric()
      
      reads_multimapped <- grep("secondary", alignment_stats_lines, value = TRUE) %>%
        sub(pattern = " .*", replacement = "") %>%
        as.numeric()
    }
    
    multimapping <- round((reads_multimapped / raw_total_sequences) * 100, digits = 1)
    
    
    # Add to results
    results <- rbind(results, data.frame(
      metric = function_metric,
      sample = sample_name,
      value = multimapping)
    )
  }
  return(results)
}

# Extract the duplication rate
get_duplication_rate <- function(){
  
  # Store metric name
  function_metric = "duplication_rate"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # If missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Get duplication values
    if(any(grepl("_alignment_stats\\.txt$", metric_file_path))){
      
      # Put all lines of txt file into character vector
      alignment_stats_lines <- readLines(metric_file_path)
      
      total_reads <- as.numeric(sub("SN	sequences:\t", "", 
                                    grep("^SN	sequences:", alignment_stats_lines, value = TRUE)))
      reads_duplicated <- as.numeric(strsplit(grep("^SN\treads duplicated:", alignment_stats_lines, 
                                                   value = TRUE), "\t")[[1]][3])
      duplication_rate <- round((reads_duplicated / total_reads) * 100, digits = 1) 
        
    } else {
      df <- read.delim(metric_file_path)
      duplication_rate <- round(df$Duplication.rate[df$Sample == sample_name] * 100, digits = 1)
    }
    
    #add key metrics to results format  
    results <- rbind(results, data.frame(
      sample = sample_name,
      metric = function_metric,
      value = duplication_rate)
    ) 
  }
  return(results)
}

get_total_reads_r1 <- function() {
  
  # Store metric name
  function_metric = "total_reads_r1"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # Give if missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip file
    zip_base <- basename(metric_file_path)
    zip_name <- sub("\\.zip$", "", zip_base)
    
    # Create tmp directory for unzipped file
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(metric_file_path, files = paste0(zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
    # Get path for unzipped data file
    fastqc_data_path <- file.path(tmp_dir, zip_name, "fastqc_data.txt")
    
    # Put all lines of txt file into character vector
    fastqc_data_lines <- readLines(fastqc_data_path)
    
    # Get total reads
    total_reads = round(as.numeric(sub("Total Sequences\t", "",
                                 grep("^Total Sequences", 
                                      fastqc_data_lines, 
                                      value = TRUE))) / 1000000, digits = 1)
    
    # Add to results
    results <- rbind(results, data.frame(metric = function_metric,
                                         sample = sample_name,
                                         value = total_reads))
    
    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
    
  }
  
  return(results)
}

get_total_reads_r2 <- function() {
  
  # Store metric name
  function_metric = "total_reads_r2"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # Give if missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip file
    zip_base <- basename(metric_file_path)
    zip_name <- sub("\\.zip$", "", zip_base)
    
    # Create tmp directory for unzipped file
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(metric_file_path, files = paste0(zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
    # Get path for unzipped data file
    fastqc_data_path <- file.path(tmp_dir, zip_name, "fastqc_data.txt")
    
    # Put all lines of txt file into character vector
    fastqc_data_lines <- readLines(fastqc_data_path)
    
    # Get total reads
    total_reads = round(as.numeric(sub("Total Sequences\t", "",
                                       grep("^Total Sequences", 
                                            fastqc_data_lines, 
                                            value = TRUE))) / 1000000, digits = 1)
    
    # Add to results
    results <- rbind(results, data.frame(metric = function_metric,
                                         sample = sample_name,
                                         value = total_reads))
    
    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
    
  }
  
  return(results)
}

get_insert_size <- function(){
  
  # Store metric name
  function_metric = "insert_size"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # If missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Put all lines of txt file into character vector
    insert_metrics_lines <- readLines(metric_file_path)
    
    # Find start of metrics table
    table_start <- grep("^MEDIAN_INSERT_SIZE", insert_metrics_lines)
    
    # Read metrics table
    insert_metrics_table <- read.delim(metric_file_path,
                                       skip = table_start - 1,
                                       nrows = 1,
                                       header = TRUE)
    
    # Get mean insert size
    insert_size <- round(insert_metrics_table$MEAN_INSERT_SIZE, digits = 1)
    
    # Add to results
    results <- rbind(results, data.frame(
      metric = function_metric,
      sample = sample_name,
      value = insert_size
    ))
  }
  
  return(results)
  
}

get_overrepresented_sequences_r1 <- function(){
  
  # Store metric name
  function_metric = "overrepresented_sequences_r1"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # If missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip file
    proc_zip_base <- basename(metric_file_path)
    proc_zip_name <- sub("\\.zip$", "", proc_zip_base)
    
    # Create tmp directory for unzipped files
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(metric_file_path, files = paste0(proc_zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
    # Get path for unzipped metrics file
    proc_fastqc_data_path <- file.path(tmp_dir, proc_zip_name, "fastqc_data.txt")
    
    # Put all lines of txt file into character vector
    proc_fastqc_lines <- readLines(proc_fastqc_data_path)
    
    # Find start and end of the overrepresented sequences section
    start_line <- grep("^>>Overrepresented sequences", proc_fastqc_lines)
    end_lines <- grep("^>>END_MODULE", proc_fastqc_lines)
    end_line <- end_lines[which(end_lines > start_line)[1]]
    
    # Extract per sequence quality scores section lines (skip headers and end module lines)
    section_lines <- proc_fastqc_lines[(start_line):(end_line - 1)]
    
    # If pass, add 0 for percent overrepresented sequences
    if(any(grepl("pass", section_lines))){
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = 0))
    } else {
      # Parse to dataframe
      overrepresented_sequences_df <- read.delim(text = section_lines,
                                                 skip = 1,
                                                 header = TRUE)
      
      # Get percentage represented by most overrepresented sequence
      overrepresented_sequences <- round(max(overrepresented_sequences_df$Percentage), digits = 1)
      
      # Add to results
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = overrepresented_sequences))
    }
    
    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
  }
  
  return(results)
  
}

get_overrepresented_sequences_r2 <- function(){
  
  # Store metric name
  function_metric = "overrepresented_sequences_r2"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # If missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip file
    proc_zip_base <- basename(metric_file_path)
    proc_zip_name <- sub("\\.zip$", "", proc_zip_base)
    
    # Create tmp directory for unzipped files
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(metric_file_path, files = paste0(proc_zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
    # Get path for unzipped metrics file
    proc_fastqc_data_path <- file.path(tmp_dir, proc_zip_name, "fastqc_data.txt")
    
    # Put all lines of txt file into character vector
    proc_fastqc_lines <- readLines(proc_fastqc_data_path)
    
    # Find start and end of the overrepresented sequences section
    start_line <- grep("^>>Overrepresented sequences", proc_fastqc_lines)
    end_lines <- grep("^>>END_MODULE", proc_fastqc_lines)
    end_line <- end_lines[which(end_lines > start_line)[1]]
    
    # Extract per sequence quality scores section lines (skip headers and end module lines)
    section_lines <- proc_fastqc_lines[(start_line):(end_line - 1)]
    
    # If pass, add 0 for percent overrepresented sequences
    if(any(grepl("pass", section_lines))){
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = 0))
    } else {
      # Parse to dataframe
      overrepresented_sequences_df <- read.delim(text = section_lines,
                                                 skip = 1,
                                                 header = TRUE)
      
      # Get percentage represented by most overrepresented sequence
      overrepresented_sequences <- round(max(overrepresented_sequences_df$Percentage), digits = 1)
      
      # Add to results
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = overrepresented_sequences))
    }
    
    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
  }
  
  return(results)
  
}

get_gc_deviation_r1 <- function(){

  # Store metric name
  function_metric = "gc_deviation_r1"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # If missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }

    # Unzip fastqc_data.txt from zip file
    proc_zip_base <- basename(metric_file_path)
    proc_zip_name <- sub("\\.zip$", "", proc_zip_base)

    # Create tmp directory for unzipped files
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)

    # Unzip metrics txt file
    unzip(metric_file_path, files = paste0(proc_zip_name, "/fastqc_data.txt"), exdir = tmp_dir)

    # Get path for unzipped metrics file
    proc_fastqc_data_path <- file.path(tmp_dir, proc_zip_name, "fastqc_data.txt")

    # Put all lines of txt file into character vector
    proc_fastqc_lines <- readLines(proc_fastqc_data_path)

    # Find start and end of per sequence GC content section
    start_line <- grep("^>>Per sequence GC content", proc_fastqc_lines)
    end_lines <- grep("^>>END_MODULE", proc_fastqc_lines)
    end_line <- end_lines[which(end_lines > start_line)[1]]

    # Extract per sequence GC content section lines (skip headers and end module lines)
    section_lines <- proc_fastqc_lines[(start_line):(end_line - 1)]

    # Parse lines to dataframe
    gc_content_df <- read.delim(text = section_lines,
                                               skip = 1,
                                               header = TRUE)
    colnames(gc_content_df) <- c("GC_content", "Count")

    # Estimate parameters for normal distribution
    total_reads <- sum(gc_content_df$Count)
    mean_gc <- sum(gc_content_df$GC_content * gc_content_df$Count) / total_reads
    sd_gc <- sqrt(sum(gc_content_df$Count * (gc_content_df$GC_content - mean_gc)^2) / total_reads)
    
    # Calculate expected counts if normal distribution
    expected_counts <- dnorm(gc_content_df$`GC_content`, mean = mean_gc, sd = sd_gc) * total_reads
    
    # Get sum of deviations from normal distribution counts
    gc_deviation_r1 <- round(sum(abs(gc_content_df$Count - expected_counts)) / total_reads * 100, 
                             digits = 1)

    # Add to results
    results <- rbind(results, data.frame(
      metric = function_metric,
      sample = sample_name,
      value = gc_deviation_r1))

    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
    
    }
  return(results)
}

get_gc_deviation_r2 <- function(){
  
  # Store metric name
  function_metric = "gc_deviation_r2"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # If missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip file
    proc_zip_base <- basename(metric_file_path)
    proc_zip_name <- sub("\\.zip$", "", proc_zip_base)
    
    # Create tmp directory for unzipped files
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(metric_file_path, files = paste0(proc_zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
    # Get path for unzipped metrics file
    proc_fastqc_data_path <- file.path(tmp_dir, proc_zip_name, "fastqc_data.txt")
    
    # Put all lines of txt file into character vector
    proc_fastqc_lines <- readLines(proc_fastqc_data_path)
    
    # Find start and end of per sequence GC content section
    start_line <- grep("^>>Per sequence GC content", proc_fastqc_lines)
    end_lines <- grep("^>>END_MODULE", proc_fastqc_lines)
    end_line <- end_lines[which(end_lines > start_line)[1]]
    
    # Extract per sequence GC content section lines (skip headers and end module lines)
    section_lines <- proc_fastqc_lines[(start_line):(end_line - 1)]
    
    # Parse lines to dataframe
    gc_content_df <- read.delim(text = section_lines,
                                skip = 1,
                                header = TRUE)
    colnames(gc_content_df) <- c("GC_content", "Count")
    
    # Estimate parameters for normal distribution
    total_reads <- sum(gc_content_df$Count)
    mean_gc <- sum(gc_content_df$GC_content * gc_content_df$Count) / total_reads
    sd_gc <- sqrt(sum(gc_content_df$Count * (gc_content_df$GC_content - mean_gc)^2) / total_reads)
    
    # Calculate expected counts if normal distribution
    expected_counts <- dnorm(gc_content_df$`GC_content`, mean = mean_gc, sd = sd_gc) * total_reads
    
    # Get sum of deviations from normal distribution counts
    gc_deviation_r2 <- round(sum(abs(gc_content_df$Count - expected_counts)) / total_reads * 100,
                             digits = 1)
    
    # Add to results
    results <- rbind(results, data.frame(
      metric = function_metric,
      sample = sample_name,
      value = gc_deviation_r2))
    
    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
    
  }
  return(results)
}

get_per_base_content_diff_r1 <- function(){
  
  # Store metric name
  function_metric = "per_base_content_diff_r1"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # If missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip file
    proc_zip_base <- basename(metric_file_path)
    proc_zip_name <- sub("\\.zip$", "", proc_zip_base)
    
    # Create tmp directory for unzipped files
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(metric_file_path, files = paste0(proc_zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
    # Get path for unzipped metrics file
    proc_fastqc_data_path <- file.path(tmp_dir, proc_zip_name, "fastqc_data.txt")
    
    # Put all lines of txt file into character vector
    proc_fastqc_lines <- readLines(proc_fastqc_data_path)
    
    # Find start and end of per base sequence content section
    start_line <- grep("^>>Per base sequence content", proc_fastqc_lines)
    end_lines <- grep("^>>END_MODULE", proc_fastqc_lines)
    end_line <- end_lines[which(end_lines > start_line)[1]]
    
    # Extract per sequence GC content section lines (skip headers and end module lines)
    section_lines <- proc_fastqc_lines[(start_line):(end_line - 1)]
    
    # Parse lines to dataframe
    sequence_content_df <- read.delim(text = section_lines,
                                skip = 1,
                                header = TRUE)
    colnames(sequence_content_df) <- c("Base", "G", "A", "T", "C")
    
    # Calculate maximum difference between GATC at each base
    sequence_content_diff <- sequence_content_df %>%
      rowwise() %>% 
      mutate(max_diff = max(c_across(c(G, A, T, C))) - min(c_across(c(G, A, T, C)))) %>%
      ungroup()
    
    per_base_content_diff_r1 <- round(max(sequence_content_diff$max_diff), digits = 1)
    
    # Add to results
    results <- rbind(results, data.frame(
      metric = function_metric,
      sample = sample_name,
      value = per_base_content_diff_r1))
    
    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
    
  }
  return(results)
}

get_per_base_content_diff_r2 <- function(){
  
  # Store metric name
  function_metric = "per_base_content_diff_r2"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # If missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip file
    proc_zip_base <- basename(metric_file_path)
    proc_zip_name <- sub("\\.zip$", "", proc_zip_base)
    
    # Create tmp directory for unzipped files
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(metric_file_path, files = paste0(proc_zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
    # Get path for unzipped metrics file
    proc_fastqc_data_path <- file.path(tmp_dir, proc_zip_name, "fastqc_data.txt")
    
    # Put all lines of txt file into character vector
    proc_fastqc_lines <- readLines(proc_fastqc_data_path)
    
    # Find start and end of per base sequence content section
    start_line <- grep("^>>Per base sequence content", proc_fastqc_lines)
    end_lines <- grep("^>>END_MODULE", proc_fastqc_lines)
    end_line <- end_lines[which(end_lines > start_line)[1]]
    
    # Extract per sequence GC content section lines (skip headers and end module lines)
    section_lines <- proc_fastqc_lines[(start_line):(end_line - 1)]
    
    # Parse lines to dataframe
    sequence_content_df <- read.delim(text = section_lines,
                                      skip = 1,
                                      header = TRUE)
    colnames(sequence_content_df) <- c("Base", "G", "A", "T", "C")
    
    # Calculate maximum difference between GATC at each base
    sequence_content_diff <- sequence_content_df %>%
      rowwise() %>% 
      mutate(max_diff = max(c_across(c(G, A, T, C))) - min(c_across(c(G, A, T, C)))) %>%
      ungroup()
    
    per_base_content_diff_r2 <- round(max(sequence_content_diff$max_diff), digits = 1)
    
    # Add to results
    results <- rbind(results, data.frame(
      metric = function_metric,
      sample = sample_name,
      value = per_base_content_diff_r2))
    
    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
    
  }
  return(results)
}

get_per_base_sequencing_quality_r1 <- function(){
  
  # Store metric name
  function_metric = "per_base_sequencing_quality_r1"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # If missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip file
    proc_zip_base <- basename(metric_file_path)
    proc_zip_name <- sub("\\.zip$", "", proc_zip_base)
    
    # Create tmp directory for unzipped files
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(metric_file_path, files = paste0(proc_zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
    # Get path for unzipped metrics file
    proc_fastqc_data_path <- file.path(tmp_dir, proc_zip_name, "fastqc_data.txt")
    
    # Put all lines of txt file into character vector
    proc_fastqc_lines <- readLines(proc_fastqc_data_path)
    
    # Find start and end of Per base sequence quality section
    start_line <- grep("^>>Per base sequence quality", proc_fastqc_lines)
    end_lines <- grep("^>>END_MODULE", proc_fastqc_lines)
    end_line <- end_lines[which(end_lines > start_line)[1]]
    
    # Extract per sequence GC content section lines (skip headers and end module lines)
    section_lines <- proc_fastqc_lines[(start_line):(end_line - 1)]
    
    # Parse lines to dataframe
    sequence_quality_df <- read.delim(text = section_lines,
                                      skip = 1,
                                      header = TRUE)
    
    # Get lowest lower quartile score
    per_base_sequencing_quality_r1 <- round(min(sequence_quality_df$Lower.Quartile), digits = 1)
    
    # Add to results
    results <- rbind(results, data.frame(
      metric = function_metric,
      sample = sample_name,
      value = per_base_sequencing_quality_r1))
    
    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
    
  }
  return(results)
}

get_per_base_sequencing_quality_r2 <- function(){
  
  # Store metric name
  function_metric = "per_base_sequencing_quality_r2"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # If missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip file
    proc_zip_base <- basename(metric_file_path)
    proc_zip_name <- sub("\\.zip$", "", proc_zip_base)
    
    # Create tmp directory for unzipped files
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(metric_file_path, files = paste0(proc_zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
    # Get path for unzipped metrics file
    proc_fastqc_data_path <- file.path(tmp_dir, proc_zip_name, "fastqc_data.txt")
    
    # Put all lines of txt file into character vector
    proc_fastqc_lines <- readLines(proc_fastqc_data_path)
    
    # Find start and end of Per base sequence quality section
    start_line <- grep("^>>Per base sequence quality", proc_fastqc_lines)
    end_lines <- grep("^>>END_MODULE", proc_fastqc_lines)
    end_line <- end_lines[which(end_lines > start_line)[1]]
    
    # Extract per sequence GC content section lines (skip headers and end module lines)
    section_lines <- proc_fastqc_lines[(start_line):(end_line - 1)]
    
    # Parse lines to dataframe
    sequence_quality_df <- read.delim(text = section_lines,
                                      skip = 1,
                                      header = TRUE)
    
    # Get lowest lower quartile score
    per_base_sequencing_quality_r2 <- round(min(sequence_quality_df$Lower.Quartile), digits = 1)
    
    # Add to results
    results <- rbind(results, data.frame(
      metric = function_metric,
      sample = sample_name,
      value = per_base_sequencing_quality_r2))
    
    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
    
  }
  return(results)
}

get_per_tile_sequencing_quality_r1 <- function(){
  
  # Store metric name
  function_metric = "per_tile_sequencing_quality_r1"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # If missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip file (could standardise file names to simplify)
    zip_base <- basename(metric_file_path)
    zip_name <- sub("\\.zip$", "", zip_base)
    
    # Create tmp directory for unzipped file
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(metric_file_path, files = paste0(zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
    # Get path for unzipped data file
    fastqc_data_path <- file.path(tmp_dir, zip_name, "fastqc_data.txt")
    
    # Put all lines of txt file into character vector
    fastqc_data_lines <- readLines(fastqc_data_path)
    
    # Find start and end of Per base sequence quality section
    start_line <- grep("^>>Per base sequence quality", fastqc_data_lines)
    end_lines <- grep("^>>END_MODULE", fastqc_data_lines)
    end_line <- end_lines[which(end_lines > start_line)[1]]
    
    # Extract per sequence GC content section lines (skip headers and end module lines)
    section_lines <- fastqc_data_lines[(start_line):(end_line - 1)]
    
    # Parse lines to dataframe
    sequence_quality_df <- read.delim(text = section_lines,
                                      skip = 1,
                                      header = TRUE)
    
    # Get mean quality score
    mean_seq_quality <- mean(sequence_quality_df$Mean)
    
    # Find start and end of Per base sequence quality section
    start_line <- grep("^>>Per tile sequence quality", fastqc_data_lines)
    end_lines <- grep("^>>END_MODULE", fastqc_data_lines)
    end_line <- end_lines[which(end_lines > start_line)[1]]
    
    # Extract per sequence GC content section lines (skip headers and end module lines)
    section_lines <- fastqc_data_lines[(start_line):(end_line - 1)]
    
    # Parse lines to dataframe
    tile_quality_df <- read.delim(text = section_lines,
                                      skip = 1,
                                      header = TRUE)
    
    colnames(tile_quality_df) <- c("tile", "base", "mean_quality")
    
    # Calculate deviation from mean quality score
    per_tile_deviation <- tile_quality_df %>%
      mutate(mean_quality_overall = mean_seq_quality,
             deviation = (abs(mean_quality) / mean_quality_overall) * 100)
    
    per_tile_sequencing_quality_r1 <- round(max(per_tile_deviation$deviation), digits = 1)
    
    # Add to results
    results <- rbind(results, data.frame(
      metric = function_metric,
      sample = sample_name,
      value = per_tile_sequencing_quality_r1))
    
    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
    
  }
  return(results)
}

get_per_tile_sequencing_quality_r2 <- function(){
  
  # Store metric name
  function_metric = "per_tile_sequencing_quality_r2"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # If missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip file (could standardise file names to simplify)
    zip_base <- basename(metric_file_path)
    zip_name <- sub("\\.zip$", "", zip_base)
    
    # Create tmp directory for unzipped file
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(metric_file_path, files = paste0(zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
    # Get path for unzipped data file
    fastqc_data_path <- file.path(tmp_dir, zip_name, "fastqc_data.txt")
    
    # Put all lines of txt file into character vector
    fastqc_data_lines <- readLines(fastqc_data_path)
    
    # Find start and end of Per base sequence quality section
    start_line <- grep("^>>Per base sequence quality", fastqc_data_lines)
    end_lines <- grep("^>>END_MODULE", fastqc_data_lines)
    end_line <- end_lines[which(end_lines > start_line)[1]]
    
    # Extract per sequence GC content section lines (skip headers and end module lines)
    section_lines <- fastqc_data_lines[(start_line):(end_line - 1)]
    
    # Parse lines to dataframe
    sequence_quality_df <- read.delim(text = section_lines,
                                      skip = 1,
                                      header = TRUE)
    
    # Get mean quality score
    mean_seq_quality <- mean(sequence_quality_df$Mean)
    
    # Find start and end of Per base sequence quality section
    start_line <- grep("^>>Per tile sequence quality", fastqc_data_lines)
    end_lines <- grep("^>>END_MODULE", fastqc_data_lines)
    end_line <- end_lines[which(end_lines > start_line)[1]]
    
    # Extract per sequence GC content section lines (skip headers and end module lines)
    section_lines <- fastqc_data_lines[(start_line):(end_line - 1)]
    
    # Parse lines to dataframe
    tile_quality_df <- read.delim(text = section_lines,
                                  skip = 1,
                                  header = TRUE)
    
    colnames(tile_quality_df) <- c("tile", "base", "mean_quality")
    
    # Calculate deviation from mean quality score
    per_tile_deviation <- tile_quality_df %>%
      mutate(mean_quality_overall = mean_seq_quality,
             deviation = (abs(mean_quality) / mean_quality_overall) * 100)
    
    per_tile_sequencing_quality_r2 <- round(max(per_tile_deviation$deviation), digits = 1)
    
    # Add to results
    results <- rbind(results, data.frame(
      metric = function_metric,
      sample = sample_name,
      value = per_tile_sequencing_quality_r2))
    
    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
    
  }
  return(results)
}

get_sequence_length_r1 <- function(){
  
  # Store metric name
  function_metric = "sequence_length_r1"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # If missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip file (could standardise file names to simplify)
    zip_base <- basename(metric_file_path)
    zip_name <- sub("\\.zip$", "", zip_base)
    
    # Create tmp directory for unzipped file
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(metric_file_path, files = paste0(zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
    # Get path for unzipped data file
    fastqc_data_path <- file.path(tmp_dir, zip_name, "fastqc_data.txt")
    
    # Put all lines of txt file into character vector
    fastqc_data_lines <- readLines(fastqc_data_path)
    
    # Find start and end of sequence length distribution section
    start_line <- grep("^>>Sequence Length Distribution", fastqc_data_lines)
    end_lines <- grep("^>>END_MODULE", fastqc_data_lines)
    end_line <- end_lines[which(end_lines > start_line)[1]]
    
    # Extract per sequence GC content section lines (skip headers and end module lines)
    section_lines <- fastqc_data_lines[(start_line):(end_line - 1)]
    
    # Parse lines to dataframe
    sequence_length_df <- read.delim(text = section_lines,
                                      skip = 1,
                                      header = TRUE)
    colnames(sequence_length_df) <- c("Length", "Count")
    
    # Get sequence length peak
    sequence_length_r1 <- sequence_length_df$Length[which.max(sequence_length_df$Count)]
    
    # Add to results
    results <- rbind(results, data.frame(
      metric = function_metric,
      sample = sample_name,
      value = sequence_length_r1))
    
    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
    
  }
  return(results)
}

get_sequence_length_r2 <- function(){
  
  # Store metric name
  function_metric = "sequence_length_r2"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # If missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip file (could standardise file names to simplify)
    zip_base <- basename(metric_file_path)
    zip_name <- sub("\\.zip$", "", zip_base)
    
    # Create tmp directory for unzipped file
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(metric_file_path, files = paste0(zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
    # Get path for unzipped data file
    fastqc_data_path <- file.path(tmp_dir, zip_name, "fastqc_data.txt")
    
    # Put all lines of txt file into character vector
    fastqc_data_lines <- readLines(fastqc_data_path)
    
    # Find start and end of sequence length distribution section
    start_line <- grep("^>>Sequence Length Distribution", fastqc_data_lines)
    end_lines <- grep("^>>END_MODULE", fastqc_data_lines)
    end_line <- end_lines[which(end_lines > start_line)[1]]
    
    # Extract per sequence GC content section lines (skip headers and end module lines)
    section_lines <- fastqc_data_lines[(start_line):(end_line - 1)]
    
    # Parse lines to dataframe
    sequence_length_df <- read.delim(text = section_lines,
                                     skip = 1,
                                     header = TRUE)
    colnames(sequence_length_df) <- c("Length", "Count")
    
    # Get sequence length peak
    sequence_length_r2 <- sequence_length_df$Length[which.max(sequence_length_df$Count)]
    
    # Add to results
    results <- rbind(results, data.frame(
      metric = function_metric,
      sample = sample_name,
      value = sequence_length_r2))
    
    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
    
  }
  return(results)
}

get_per_base_N_content_r1 <- function(){
  
  # Store metric name
  function_metric = "per_base_N_content_r1"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # If missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip file (could standardise file names to simplify)
    zip_base <- basename(metric_file_path)
    zip_name <- sub("\\.zip$", "", zip_base)
    
    # Create tmp directory for unzipped file
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(metric_file_path, files = paste0(zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
    # Get path for unzipped data file
    fastqc_data_path <- file.path(tmp_dir, zip_name, "fastqc_data.txt")
    
    # Put all lines of txt file into character vector
    fastqc_data_lines <- readLines(fastqc_data_path)
    
    # Find start and end of sequence length distribution section
    start_line <- grep("^>>Per base N content", fastqc_data_lines)
    end_lines <- grep("^>>END_MODULE", fastqc_data_lines)
    end_line <- end_lines[which(end_lines > start_line)[1]]
    
    # Extract per sequence GC content section lines (skip headers and end module lines)
    section_lines <- fastqc_data_lines[(start_line):(end_line - 1)]
    
    # Parse lines to dataframe
    N_content_df <- read.delim(text = section_lines,
                                     skip = 1,
                                     header = TRUE)
    colnames(N_content_df) <- c("base", "count")
    
    # Calculate percent N at each base
    N_content_percent <- N_content_df %>% 
      mutate(percent_N = count * 100)
    
    # Get max N content
    per_base_N_content_r1 <- round(max(N_content_percent$percent_N), digits = 1)
    
    # Add to results
    results <- rbind(results, data.frame(
      metric = function_metric,
      sample = sample_name,
      value = per_base_N_content_r1))
    
    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
    
  }
  return(results)
}

get_per_base_N_content_r2 <- function(){
  
  # Store metric name
  function_metric = "per_base_N_content_r2"
  
  # Print progress indicator
  print(paste("Getting", function_metric))
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Print sample name for progress
    print(sample_name)
    
    # Get path to metrics file
    metric_file_path <- metric_file_path(sample_dir, function_metric, component_metrics)
    
    # If missing metrics file enter NA value, then skip sample
    if(length(metric_file_path) == 0) {
      results <- rbind(results, data.frame(
        metric = function_metric,
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip file (could standardise file names to simplify)
    zip_base <- basename(metric_file_path)
    zip_name <- sub("\\.zip$", "", zip_base)
    
    # Create tmp directory for unzipped file
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(metric_file_path, files = paste0(zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
    # Get path for unzipped data file
    fastqc_data_path <- file.path(tmp_dir, zip_name, "fastqc_data.txt")
    
    # Put all lines of txt file into character vector
    fastqc_data_lines <- readLines(fastqc_data_path)
    
    # Find start and end of sequence length distribution section
    start_line <- grep("^>>Per base N content", fastqc_data_lines)
    end_lines <- grep("^>>END_MODULE", fastqc_data_lines)
    end_line <- end_lines[which(end_lines > start_line)[1]]
    
    # Extract per sequence GC content section lines (skip headers and end module lines)
    section_lines <- fastqc_data_lines[(start_line):(end_line - 1)]
    
    # Parse lines to dataframe
    N_content_df <- read.delim(text = section_lines,
                               skip = 1,
                               header = TRUE)
    colnames(N_content_df) <- c("base", "count")
    
    # Calculate percent N at each base
    N_content_percent <- N_content_df %>% 
      mutate(percent_N = count * 100)
    
    # Get max N content
    per_base_N_content_r2 <- round(max(N_content_percent$percent_N), digits = 1)
    
    # Add to results
    results <- rbind(results, data.frame(
      metric = function_metric,
      sample = sample_name,
      value = per_base_N_content_r2))
    
    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
    
  }
  return(results)
}




