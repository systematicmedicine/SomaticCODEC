# ---
# --- get_metrics.R ---
# 
# Collection of R functions to collect key metrics from codec-opensource/metrics
# 
# Authors: 
#     - Joshua Johnstone
#     - Ben Barry
# ---


# Get peak of per sequence quality score distribution for raw r1
get_per_sequence_quality_score_r1 <- function() {
  
  # Store metric name
  function_metric = "per_sequence_quality_score_r1"
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    # Get path to zip file (could standardise file names to simplify)
    zip_path <- list.files(sample_dir, 
                           pattern = "_r1_raw_fastqc\\.zip$|_r1_fastqc_raw_metrics\\.zip$", 
                           full.names = TRUE)
    
    # Give if missing zip enter NA value, then skip sample
    if(length(zip_path) == 0) {
      results <- rbind(results, data.frame(
        metric = "per_sequence_quality_score_r1",
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip file (could standardise file names to simplify)
    zip_base <- basename(zip_path)
    zip_name <- sub("\\.zip$", "", zip_base)
    
    # Create tmp directory for unzipped file
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(zip_path, files = paste0(zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
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
    peak_quality <- quality_df$Quality[which.max(quality_df$Count)]
    
    # Add to results
    results <- rbind(results, data.frame(metric = "per_sequence_quality_score_r1",
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
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    # Get path to zip file (could standardise file names to simplify)
    zip_path <- list.files(sample_dir, 
                           pattern = "_r2_raw_fastqc\\.zip$|_r2_fastqc_raw_metrics\\.zip$", 
                           full.names = TRUE)
    
    # If missing zip enter NA value, then skip sample
    if (length(zip_path) == 0) {
      results <- rbind(results, data.frame(
        metric = "per_sequence_quality_score_r2",
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip file (could standardise file names to simplify)
    zip_base <- basename(zip_path)
    zip_name <- sub("\\.zip$", "", zip_base)
    
    # Create tmp directory for unzipped file
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(zip_path, files = paste0(zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
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
    peak_quality <- quality_df$Quality[which.max(quality_df$Count)]
    
    # Add to results
    results <- rbind(results, data.frame(metric = "per_sequence_quality_score_r2",
                                         sample = sample_name,
                                         value = peak_quality))
    
    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
    
  }
  
  return(results)
}

# Get percent reads remaining after processing for r1
get_percent_reads_remaining_r1 <- function() {
  
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    # Get path to zip file (could standardise file names to simplify)
    raw_zip_path <- list.files(sample_dir, 
                           pattern = "_r1_raw_fastqc\\.zip$|_r1_fastqc_raw_metrics\\.zip$", 
                           full.names = TRUE)
    proc_zip_path <- list.files(sample_dir, 
                                   pattern = "_processed_r1_fastqc\\.zip$|_r1_filter_metrics\\.zip$", 
                                   full.names = TRUE)
    
    # If missing zips enter NA value, then skip sample
    if (length(raw_zip_path) == 0 || length(proc_zip_path) == 0) {
      results <- rbind(results, data.frame(
        metric = "percent_reads_remaining_r1",
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip files (could standardise file names to simplify)
    raw_zip_base <- basename(raw_zip_path)
    raw_zip_name <- sub("\\.zip$", "", raw_zip_base)
    
    proc_zip_base <- basename(proc_zip_path)
    proc_zip_name <- sub("\\.zip$", "", proc_zip_base)
    
    # Create tmp directory for unzipped files
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt files
    unzip(raw_zip_path, files = paste0(raw_zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    unzip(proc_zip_path, files = paste0(proc_zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
    # Get paths for unzipped metrics files
    raw_fastqc_data_path <- file.path(tmp_dir, raw_zip_name, "fastqc_data.txt")
    proc_fastqc_data_path <- file.path(tmp_dir, proc_zip_name, "fastqc_data.txt")
    
    # Put all lines of txt files into character vector
    raw_fastqc_lines <- readLines(raw_fastqc_data_path)
    proc_fastqc_lines <- readLines(proc_fastqc_data_path)
    
    # Extract total sequences from each txt file
    raw_total <- as.numeric(sub("Total Sequences\t", "", grep("^Total Sequences", raw_fastqc_lines, value = TRUE)))
    proc_total <- as.numeric(sub("Total Sequences\t", "", grep("^Total Sequences", proc_fastqc_lines, value = TRUE)))

    # Calculate percent remaining
    percent_remaining <- round((proc_total / raw_total) * 100, digits = 1)
    
    # Add to results
    results <- rbind(results, data.frame(
      metric = "percent_reads_remaining_r1",
      sample = sample_name,
      value = percent_remaining
    ))
    
    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
  }
  
  return(results)
}

# Get percent reads remaining after processing for r2
get_percent_reads_remaining_r2 <- function() {
  
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    # Get path to zip file (could standardise file names to simplify)
    raw_zip_path <- list.files(sample_dir, 
                               pattern = "_r2_raw_fastqc\\.zip$|_r2_fastqc_raw_metrics\\.zip$", 
                               full.names = TRUE)
    proc_zip_path <- list.files(sample_dir, 
                                pattern = "_processed_r2_fastqc\\.zip$|_r2_filter_metrics\\.zip$", 
                                full.names = TRUE)
    
    # If missing zips enter NA value, then skip sample
    if (length(raw_zip_path) == 0 || length(proc_zip_path) == 0) {
      results <- rbind(results, data.frame(
        metric = "percent_reads_remaining_r2",
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip files (could standardise file names to simplify)
    raw_zip_base <- basename(raw_zip_path)
    raw_zip_name <- sub("\\.zip$", "", raw_zip_base)
    
    proc_zip_base <- basename(proc_zip_path)
    proc_zip_name <- sub("\\.zip$", "", proc_zip_base)
    
    # Create tmp directory for unzipped files
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt files
    unzip(raw_zip_path, files = paste0(raw_zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    unzip(proc_zip_path, files = paste0(proc_zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
    # Get paths for unzipped metrics files
    raw_fastqc_data_path <- file.path(tmp_dir, raw_zip_name, "fastqc_data.txt")
    proc_fastqc_data_path <- file.path(tmp_dir, proc_zip_name, "fastqc_data.txt")
    
    # Put all lines of txt files into character vector
    raw_fastqc_lines <- readLines(raw_fastqc_data_path)
    proc_fastqc_lines <- readLines(proc_fastqc_data_path)
    
    # Extract total sequences from each txt file
    raw_total <- as.numeric(sub("Total Sequences\t", "", grep("^Total Sequences", raw_fastqc_lines, value = TRUE)))
    proc_total <- as.numeric(sub("Total Sequences\t", "", grep("^Total Sequences", proc_fastqc_lines, value = TRUE)))
    
    # Calculate percent remaining
    percent_remaining <- round((proc_total / raw_total) * 100, digits = 1)
    
    # Add to results
    results <- rbind(results, data.frame(
      metric = "percent_reads_remaining_r2",
      sample = sample_name,
      value = percent_remaining
    ))
    
    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
  }
  
  return(results)
}

# Get read alignment rate
get_read_alignment_rate <- function() {
  
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    # Get path to alignment stats file (could standardise file names to simplify)
    alignment_stats_path <- list.files(sample_dir, 
                                       pattern = "_alignment_stats.txt$|_map_metrics.txt$", 
                                       full.names = TRUE)
    
    # If missing alignment stats file enter NA value, then skip sample
    if (length(alignment_stats_path) == 0) {
      results <- rbind(results, data.frame(
        metric = "read_alignment_rate",
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Put all lines of txt file into character vector
    alignment_stats_lines <- readLines(alignment_stats_path)
    
    # Calculate alignment rate
    if(any(grepl("_alignment_stats\\.txt$", alignment_stats_path))){
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
      metric = "read_alignment_rate",
      sample = sample_name,
      value = alignment_rate
    ))
  }
  
  return(results)
}

# Get percentage of reference genome masked by combined mask
get_mask_coverage <- function(){
  
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    # Get path to mask metrics file
    mask_metrics_path <- list.files(sample_dir, 
                                       pattern = "_mask_metrics.txt$", 
                                       full.names = TRUE)
    
    # If missing mask metrics file enter NA value, then skip sample
    if (length(mask_metrics_path) == 0) {
      results <- rbind(results, data.frame(
        metric = "mask_coverage",
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Put all lines of txt file into character vector
    mask_metrics_lines <- readLines(mask_metrics_path)
    
    # Get percent coverage of combined mask
    combined_mask_line <- grep("^combined_mask\\.bed", mask_metrics_lines, value = TRUE)
    percent_coverage <- round(as.numeric(sub("%", "", 
                                             strsplit(combined_mask_line, "\t")[[1]][3])), digits = 1)
    
    # Add to results
    results <- rbind(results, data.frame(
      metric = "mask_coverage",
      sample = sample_name,
      value = percent_coverage
    ))
  }
  
  return(results)
}

# Get percentage of reads contributed by each sample
get_percent_read_contribution <- function(){
  
  library(jsonlite)
  
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    # Get path to demux metrics file
    demux_metrics_path <- list.files(sample_dir, 
                                    pattern = "_demux_metrics.json$", 
                                    full.names = TRUE)
    
    # If missing demux metrics file enter NA value, then skip sample
    if (length(demux_metrics_path) == 0) {
      results <- rbind(results, data.frame(
        metric = "percent_read_contribution",
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Pull json file contents into list
    demux_metrics <- fromJSON(demux_metrics_path)
    
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
      metric = "percent_read_contribution",
      sample = sample_name,
      value = percent_contribution
      ))
  }
  
  return(results)
}

# Get percentage of contaminating adaptors in each sample
get_percent_adaptor_contamination <- function(){
  
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    # Get path to batch contamination metrics file
    contamination_metrics_path <- list.files(sample_dir, 
                                     pattern = "batchcontamination_metrics.txt$", 
                                     full.names = TRUE)
    
    # If missing batch contamination metrics file enter NA value, then skip sample
    if (length(contamination_metrics_path) == 0) {
      results <- rbind(results, data.frame(
        metric = "percent_adaptor_contamination",
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Pull metrics into data frame
    contamination_metrics <- read.delim(contamination_metrics_path)
    
    # Get percent adaptor contamination
    percent_contamination <- format(round(as.numeric(sub("%", "", contamination_metrics$Percentage.of.demuxed[
      contamination_metrics$Sample == sample_name])), digits = 4), scientific = FALSE)
    
    # Add to results
    results <- rbind(results, data.frame(
      metric = "percent_adaptor_contamination",
      sample = sample_name,
      value = percent_contamination
    ))
  }
  
  return(results)
}

# Get correct product ratio
get_correct_product_ratio <- function(){
  
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    # Get path to correct product metrics file
    correct_product_metrics_path <- list.files(sample_dir, 
                                    pattern = "_correctproduct_metrics.txt$", 
                                    full.names = TRUE)
    
    # If missing correct product metrics file enter NA value, then skip sample
    if (length(correct_product_metrics_path) == 0) {
      results <- rbind(results, data.frame(
        metric = "correct_product_ratio",
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Pull metrics into data frame
    correct_product_metrics <- read.delim(correct_product_metrics_path)
    
    # Get correct product ratio
    correct_product_ratio <- round(as.numeric(correct_product_metrics$correct_aligned_. / 100), 
                                   digits = 2)
    
    # Add to results
    results <- rbind(results, data.frame(
      metric = "correct_product_ratio",
      sample = sample_name,
      value = correct_product_ratio
    ))
  }
  
  return(results)
}

# Get duplex coverage
get_duplex_coverage <- function(){
  
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    # Get path to dsc depth metrics file
   dsc_depth_metrics_path <- list.files(sample_dir, 
                                               pattern = "_dsc_depth_metrics.txt$", 
                                               full.names = TRUE)
    
   # If missing dsc depth metrics file enter NA value, then skip sample
   if (length(dsc_depth_metrics_path) == 0) {
     results <- rbind(results, data.frame(
       metric = "duplex_coverage",
       sample = sample_name,
       value = NA
     ))
     next
   }
   
   # Read lines and find line after header
   dsc_depth_metrics_lines <- readLines(dsc_depth_metrics_path)
   header_line <- grep("^GENOME_TERRITORY", dsc_depth_metrics_lines)
   data_line <- dsc_depth_metrics_lines[header_line + 1]
   
  # Get mean duplex coverage
   duplex_coverage <- round(as.numeric(strsplit(data_line, "\t")[[1]][2]), digits = 1)
   
   # Add to results
   results <- rbind(results, data.frame(
     metric = "duplex_coverage",
     sample = sample_name,
     value = duplex_coverage
   ))
  }
}

# Collate germline variant call metrics
get_germline_variants <- function(){
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  
  #create empty object to store metrics
  results <- data.frame(
    sample = character(),
    metric = character(),
    value = numeric(),
    stringsAsFactors = FALSE
  )
  
  #loop  through sample directory and create path files for variantCall files
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    txt_path <- list.files(sample_dir, pattern = "variantCall_summary.*\\.txt$",
                           ignore.case = TRUE, full.names = TRUE)
    
    # Skip sample and insert NA if summary file not found 
    if (length(txt_path) == 0 || is.na(txt_path)) {
      results <- rbind(results, data.frame(
        metric = "germline_variants",
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # read file
    lines <- readLines(txt_path)
    #select key metrics 
    obj <- list()
    
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
      metric = "germline_variants",
      value = total_variants,
      stringsAsFactors = FALSE
    )
    )
    
  }
  return(results)
}

get_SNV_indel_ratio <- function(){
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  
  #create empty object to store metrics
  results <- data.frame(
    sample = character(),
    metric = character(),
    value = numeric(),
    stringsAsFactors = FALSE
  )
  
  #loop  through sample directory and create path files for variantCall files
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    txt_path <- list.files(sample_dir, pattern = "variantCall_summary.*\\.txt$",
                           ignore.case = TRUE, full.names = TRUE)
    
    # Insert NA and skip sample if summary file not found 
    if (length(txt_path) == 0 || is.na(txt_path)) {
      results <- rbind(results, data.frame(
        metric = "SNV_indel_ratio",
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # read file
    lines <- readLines(txt_path)
    #select key metrics 
    obj <- list()
    
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
    ratio <- snp / indel
    
    #parse into results frame
    results <- rbind(results, data.frame(
      sample = sample_name,
      metric = "SNV_indel_ratio",
      value = ratio,
      stringsAsFactors = FALSE
    )
    )
    
  }
  return(results)
}

get_insertion_deletion_ratio <- function(){
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  
  #create empty object to store metrics
  results <- data.frame(
    sample = character(),
    metric = character(),
    value = numeric(),
    stringsAsFactors = FALSE
  )
  
  #loop  through sample directory and create path files for variantCall files
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    txt_path <- list.files(sample_dir, pattern = "variantCall_summary.*\\.txt$",
                           ignore.case = TRUE, full.names = TRUE)
    
    # Insert NA and skip sample if summary file not found 
    if (length(txt_path) == 0 || is.na(txt_path)) {
      results <- rbind(results, data.frame(
        metric = "insertion_deletion_ratio",
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # read file
    lines <- readLines(txt_path)
    #select key metrics 
    obj <- list()
    
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
    
    #put into the results frame
    results <- rbind(results, data.frame(
      sample = "sample_name",
      metric = "insertion_deletion_ratio",
      value = ins_count/del_count,
      stringsAsFactors = FALSE
    )
    )
    
  }
  return(results)
}

get_MNP_other_variants <- function(){
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  
  #create empty object to store metrics
  results <- data.frame(
    sample = character(),
    metric = character(),
    value = numeric(),
    stringsAsFactors = FALSE
  )
  
  #loop  through sample directory and create path files for variantCall files
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    txt_path <- list.files(sample_dir, pattern = "variantCall_summary.*\\.txt$",
                           ignore.case = TRUE, full.names = TRUE)
    
    # Insert NA and skip sample if summary file not found 
    if (length(txt_path) == 0 || is.na(txt_path)) {
      results <- rbind(results, data.frame(
        metric = "MNP_other_variants",
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # read file
    lines <- readLines(txt_path)
    #select key metrics 
    obj <- list()
    
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
      metric = "MNP_other_variants",
      value = MNP + other,
      stringsAsFactors = FALSE
    )
    )
    
  }
  return(results)
} 

get_transition_transversion_ratio <- function(){
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  
  #create empty object to store metrics
  results <- data.frame(
    sample = character(),
    metric = character(),
    value = numeric(),
    stringsAsFactors = FALSE
  )
  
  #loop  through sample directory and create path files for variantCall files
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    txt_path <- list.files(sample_dir, pattern = "variantCall_summary.*\\.txt$",
                           ignore.case = TRUE, full.names = TRUE)
    
    # Insert NA and skip sample if summary file not found 
    if (length(txt_path) == 0 || is.na(txt_path)) {
      results <- rbind(results, data.frame(
        metric = "transition_transversion_ratio",
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # read file
    lines <- readLines(txt_path)
    #select key metrics 
    obj <- list()
    
    # Get the data from "SN"
    TSTV_data <- grep(paste0("^", "TSTV", "\t"), lines, value = TRUE)
    
    #idenfity the line the data came from
    TSTV_info_index <- min(grep(paste("TSTV", "\t", sep=""), lines))
    
    # Clean the decription of the data
    TSTV_info <- gsub("\\[[0-9]+\\]", "", 
                      unlist(strsplit(gsub("# ", "", lines[TSTV_info_index]), "\t")))
    
    #parse into a DF
    df <- read.delim(textConnection(TSTV_data), header = FALSE, col.names = TSTV_info)
    
    
    #put into the results frame
    results <- rbind(results, data.frame(
      sample = sample_name,
      metric = "transition_transversion_ratio",
      value = df$ts.tv[1],
      stringsAsFactors = FALSE
    )
    )
  }
  return(results)
} 

get_het_hom_ratio <- function(){
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  
  #create empty object to store metrics
  results <- data.frame(
    sample = character(),
    metric = character(),
    value = numeric(),
    stringsAsFactors = FALSE
  )
  
  #loop  through sample directory and create path files for duplication metrics
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    txt_path <- list.files(sample_dir, pattern = "_genotype_summary.*\\.txt$",
                           ignore.case = TRUE, full.names = TRUE)
    
    # Insert NA and skip sample if metric file isnt found
    if (length(txt_path) == 0 || is.na(txt_path)) {
      results <- rbind(results, data.frame(
        metric = "get_het_hom_ratio",
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    #read file to df
    df <- read_delim(txt_path, show_col_types = TRUE, delim = "\t")
    
    #add key metrics to results format  
    results <- rbind(results, data.frame(
      sample = sample_name,
      metric = "het_hom_ratio",
      value = df$ratio)
    ) 
    
  }
  return(results)
}

# Get read multimapping rate
get_multimapping_rate <- function() {
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  
  # create empty object to store metrics
  results <- data.frame(
    metric = character(),
    sample = character(),
    value = numeric()
  )
  
  #loop  through sample directory and create path files for duplication metrics
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    
    # Get path to samtools stat/ flagstat output file (could standardise file names to simplify)
    alignment_stats_path <- list.files(
      sample_dir, 
      pattern = "_alignment_stats.txt$|_map_metrics.txt$", 
      full.names = TRUE
    )
    
    # If missing alignment stats file enter NA value, then skip sample
    if (length(alignment_stats_path) == 0) {
      results <- rbind(results, data.frame(
        metric = "multimapping_rate",
        sample = sample_name,
        value = NA)
      )
      next
    }
    
    # Put all lines of txt file into character vector
    alignment_stats_lines <- readLines(alignment_stats_path)
    
    # extract the total raw sequences and the multimapped 
    if(any(grepl("_alignment_stats\\.txt$", alignment_stats_path))){
      
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
    
    multimapping <- round((reads_multimapped / raw_total_sequences) * 100, 1)
    
    
    # Add to results
    results <- rbind(results, data.frame(
      metric = "multimapping_rate",
      sample = sample_name,
      value = multimapping)
    )
  }
  return(results)
}

# Extract the duplication rate
get_duplication_rate <- function(){
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  
  #create empty object to store metrics
  results <- data.frame(
    sample = character(),
    metric = character(),
    value = numeric(),
    stringsAsFactors = FALSE
  )
  
  #loop  through sample directory and create path files for duplication metrics
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    txt_path <- list.files(sample_dir, pattern = "_duplication_metrics.*\\.txt$",
                           ignore.case = TRUE, full.names = TRUE)
    
    if (length(txt_path) == 0 || is.na(txt_path)) {
      results <- rbind(results, data.frame(
        metric = "duplication_rate",
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    #read file to df
    df <- read.delim(txt_path)
    
    #add key metrics to results format  
    results <- rbind(results, data.frame(
      sample = sample_name,
      metric = "duplication_rate",
      value = df$`Duplication.rate`[1])
    ) 
  }
  return(results)
}

get_total_reads <- function() {
  
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    # Get path to alignment stats file
    alignment_stats_path <- list.files(sample_dir, 
                                       pattern = "_alignment_stats.txt$|_map_metrics.txt$", 
                                       full.names = TRUE)
    
    # If missing alignment stats file enter NA value, then skip sample
    if (length(alignment_stats_path) == 0) {
      results <- rbind(results, data.frame(
        metric = "total_reads",
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Put all lines of txt file into character vector
    alignment_stats_lines <- readLines(alignment_stats_path)
    
    # Calculate alignment rate
    if(any(grepl("_alignment_stats\\.txt$", alignment_stats_path))){
      total_reads <- as.numeric(sub("SN	sequences:\t", "", 
                                    grep("^SN	sequences:", alignment_stats_lines, value = TRUE)))
    } else {
      total_reads <- as.numeric(sub(" .*", "", grep("in total", alignment_stats_lines, value = TRUE)))
    }
    
    total_reads_million <- round(total_reads / 1000000, digits = 0)
    
    # Add to results
    results <- rbind(results, data.frame(
      metric = "total_reads",
      sample = sample_name,
      value = total_reads_million
    ))
  }
  
  return(results)
}

get_ex_insert_size <- function(){
  
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    # Get path to dedup insert metrics file
    dedup_insert_metrics_path <- list.files(sample_dir, 
                                       pattern = "_deduplicated_insert_metrics.txt$", 
                                       full.names = TRUE)
    
    # If missing dedup insert metrics file enter NA value, then skip sample
    if (length(dedup_insert_metrics_path) == 0) {
      results <- rbind(results, data.frame(
        metric = "ex_insert_size",
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Put all lines of txt file into character vector
    dedup_insert_metrics_lines <- readLines(dedup_insert_metrics_path)
    
    # Find start of metrics table
    table_start <- grep("^MEDIAN_INSERT_SIZE", dedup_insert_metrics_lines)
    
    # Read metrics table
    dedup_insert_metrics_table <- read.delim(dedup_insert_metrics_path, 
                                             skip = table_start - 1, 
                                             header = TRUE)
    
    # Get mean insert size
    ex_insert_size <- dedup_insert_metrics_table$MEAN_INSERT_SIZE
    
    # Add to results
    results <- rbind(results, data.frame(
      metric = "ex_insert_size",
      sample = sample_name,
      value = ex_insert_size
    ))
  }
  
  return(results)
  
}

get_overrepresented_sequences_r1 <- function(){
  
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    # Get path to processed fastqc file
    proc_zip_path <- list.files(sample_dir, 
                                pattern = "_processed_r1_fastqc\\.zip$|_r1_filter_metrics\\.zip$", 
                                full.names = TRUE)
    
    # If missing processed fastqc zip file enter NA value, then skip sample
    if (length(proc_zip_path) == 0) {
      results <- rbind(results, data.frame(
        metric = "overrepresented_sequences_r1",
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip file
    proc_zip_base <- basename(proc_zip_path)
    proc_zip_name <- sub("\\.zip$", "", proc_zip_base)
    
    # Create tmp directory for unzipped files
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(proc_zip_path, files = paste0(proc_zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
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
        metric = "overrepresented_sequences_r1",
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
        metric = "overrepresented_sequences_r1",
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
  
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    # Get path to processed fastqc file
    proc_zip_path <- list.files(sample_dir, 
                                pattern = "_processed_r2_fastqc\\.zip$|_r2_filter_metrics\\.zip$", 
                                full.names = TRUE)
    
    # If missing processed fastqc zip file enter NA value, then skip sample
    if (length(proc_zip_path) == 0) {
      results <- rbind(results, data.frame(
        metric = "overrepresented_sequences_r2",
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip file
    proc_zip_base <- basename(proc_zip_path)
    proc_zip_name <- sub("\\.zip$", "", proc_zip_base)
    
    # Create tmp directory for unzipped files
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(proc_zip_path, files = paste0(proc_zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
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
        metric = "overrepresented_sequences_r2",
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
        metric = "overrepresented_sequences_r2",
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

  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())

  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    # Get path to processed fastqc file
    proc_zip_path <- list.files(sample_dir,
                                pattern = "_processed_r1_fastqc\\.zip$|_r1_filter_metrics\\.zip$",
                                full.names = TRUE)

    # If missing processed fastqc zip file enter NA value, then skip sample
    if (length(proc_zip_path) == 0) {
      results <- rbind(results, data.frame(
        metric = "gc_deviation_r1",
        sample = sample_name,
        value = NA
      ))
      next
    }

    # Unzip fastqc_data.txt from zip file
    proc_zip_base <- basename(proc_zip_path)
    proc_zip_name <- sub("\\.zip$", "", proc_zip_base)

    # Create tmp directory for unzipped files
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)

    # Unzip metrics txt file
    unzip(proc_zip_path, files = paste0(proc_zip_name, "/fastqc_data.txt"), exdir = tmp_dir)

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
    gc_deviation_r1 <- sum(abs(gc_content_df$Count - expected_counts)) / total_reads * 100

    # Add to results
    results <- rbind(results, data.frame(
      metric = "gc_deviation_r1",
      sample = sample_name,
      value = gc_deviation_r1))

    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
    
    }
  return(results)
}

get_gc_deviation_r2 <- function(){
  
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    # Get path to processed fastqc file
    proc_zip_path <- list.files(sample_dir,
                                pattern = "_processed_r2_fastqc\\.zip$|_r2_filter_metrics\\.zip$",
                                full.names = TRUE)
    
    # If missing processed fastqc zip file enter NA value, then skip sample
    if (length(proc_zip_path) == 0) {
      results <- rbind(results, data.frame(
        metric = "gc_deviation_r2",
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip file
    proc_zip_base <- basename(proc_zip_path)
    proc_zip_name <- sub("\\.zip$", "", proc_zip_base)
    
    # Create tmp directory for unzipped files
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(proc_zip_path, files = paste0(proc_zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
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
    gc_deviation_r2 <- sum(abs(gc_content_df$Count - expected_counts)) / total_reads * 100
    
    # Add to results
    results <- rbind(results, data.frame(
      metric = "gc_deviation_r2",
      sample = sample_name,
      value = gc_deviation_r2))
    
    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
    
  }
  return(results)
}

get_per_base_content_diff_r1 <- function(){
  
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    # Get path to processed fastqc file
    proc_zip_path <- list.files(sample_dir,
                                pattern = "_processed_r1_fastqc\\.zip$|_r1_filter_metrics\\.zip$",
                                full.names = TRUE)
    
    # If missing processed fastqc zip file enter NA value, then skip sample
    if (length(proc_zip_path) == 0) {
      results <- rbind(results, data.frame(
        metric = "per_base_content_diff_r1",
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip file
    proc_zip_base <- basename(proc_zip_path)
    proc_zip_name <- sub("\\.zip$", "", proc_zip_base)
    
    # Create tmp directory for unzipped files
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(proc_zip_path, files = paste0(proc_zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
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
      metric = "per_base_content_diff_r1",
      sample = sample_name,
      value = per_base_content_diff_r1))
    
    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
    
  }
  return(results)
}

get_per_base_content_diff_r2 <- function(){
  
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    # Get path to processed fastqc file
    proc_zip_path <- list.files(sample_dir,
                                pattern = "_processed_r2_fastqc\\.zip$|_r2_filter_metrics\\.zip$",
                                full.names = TRUE)
    
    # If missing processed fastqc zip file enter NA value, then skip sample
    if (length(proc_zip_path) == 0) {
      results <- rbind(results, data.frame(
        metric = "per_base_content_diff_r2",
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip file
    proc_zip_base <- basename(proc_zip_path)
    proc_zip_name <- sub("\\.zip$", "", proc_zip_base)
    
    # Create tmp directory for unzipped files
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(proc_zip_path, files = paste0(proc_zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
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
      metric = "per_base_content_diff_r2",
      sample = sample_name,
      value = per_base_content_diff_r2))
    
    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
    
  }
  return(results)
}

get_per_base_sequencing_quality_r1 <- function(){
  
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    # Get path to processed fastqc file
    proc_zip_path <- list.files(sample_dir,
                                pattern = "_processed_r1_fastqc\\.zip$|_r1_filter_metrics\\.zip$",
                                full.names = TRUE)
    
    # If missing processed fastqc zip file enter NA value, then skip sample
    if (length(proc_zip_path) == 0) {
      results <- rbind(results, data.frame(
        metric = "per_base_sequencing_quality_r1",
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip file
    proc_zip_base <- basename(proc_zip_path)
    proc_zip_name <- sub("\\.zip$", "", proc_zip_base)
    
    # Create tmp directory for unzipped files
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(proc_zip_path, files = paste0(proc_zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
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
    per_base_sequencing_quality_r1 <- min(sequence_quality_df$Lower.Quartile)
    
    # Add to results
    results <- rbind(results, data.frame(
      metric = "per_base_sequencing_quality_r1",
      sample = sample_name,
      value = per_base_sequencing_quality_r1))
    
    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
    
  }
  return(results)
}

get_per_base_sequencing_quality_r2 <- function(){
  
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    # Get path to processed fastqc file
    proc_zip_path <- list.files(sample_dir,
                                pattern = "_processed_r2_fastqc\\.zip$|_r2_filter_metrics\\.zip$",
                                full.names = TRUE)
    
    # If missing processed fastqc zip file enter NA value, then skip sample
    if (length(proc_zip_path) == 0) {
      results <- rbind(results, data.frame(
        metric = "per_base_sequencing_quality_r2",
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip file
    proc_zip_base <- basename(proc_zip_path)
    proc_zip_name <- sub("\\.zip$", "", proc_zip_base)
    
    # Create tmp directory for unzipped files
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(proc_zip_path, files = paste0(proc_zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
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
    per_base_sequencing_quality_r2 <- min(sequence_quality_df$Lower.Quartile)
    
    # Add to results
    results <- rbind(results, data.frame(
      metric = "per_base_sequencing_quality_r2",
      sample = sample_name,
      value = per_base_sequencing_quality_r2))
    
    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
    
  }
  return(results)
}

get_per_tile_sequencing_quality_r1 <- function(){
  
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    # Get path to zip file (could standardise file names to simplify)
    zip_path <- list.files(sample_dir, 
                           pattern = "_r1_raw_fastqc\\.zip$|_r1_fastqc_raw_metrics\\.zip$", 
                           full.names = TRUE)
    
    # Give if missing zip enter NA value, then skip sample
    if(length(zip_path) == 0) {
      results <- rbind(results, data.frame(
        metric = "per_sequence_quality_score_r1",
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip file (could standardise file names to simplify)
    zip_base <- basename(zip_path)
    zip_name <- sub("\\.zip$", "", zip_base)
    
    # Create tmp directory for unzipped file
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(zip_path, files = paste0(zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
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
      metric = "per_tile_sequencing_quality_r1",
      sample = sample_name,
      value = per_tile_sequencing_quality_r1))
    
    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
    
  }
  return(results)
}

get_per_tile_sequencing_quality_r2 <- function(){
  
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    # Get path to zip file (could standardise file names to simplify)
    zip_path <- list.files(sample_dir, 
                           pattern = "_r1_raw_fastqc\\.zip$|_r2_fastqc_raw_metrics\\.zip$", 
                           full.names = TRUE)
    
    # Give if missing zip enter NA value, then skip sample
    if(length(zip_path) == 0) {
      results <- rbind(results, data.frame(
        metric = "per_sequence_quality_score_r2",
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip file (could standardise file names to simplify)
    zip_base <- basename(zip_path)
    zip_name <- sub("\\.zip$", "", zip_base)
    
    # Create tmp directory for unzipped file
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(zip_path, files = paste0(zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
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
      metric = "per_tile_sequencing_quality_r2",
      sample = sample_name,
      value = per_tile_sequencing_quality_r2))
    
    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
    
  }
  return(results)
}

get_sequence_length_r1 <- function(){
  
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    # Get path to zip file (could standardise file names to simplify)
    zip_path <- list.files(sample_dir, 
                           pattern = "_r1_raw_fastqc\\.zip$|_r1_fastqc_raw_metrics\\.zip$", 
                           full.names = TRUE)
    
    # Give if missing zip enter NA value, then skip sample
    if(length(zip_path) == 0) {
      results <- rbind(results, data.frame(
        metric = "per_sequence_quality_score_r1",
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip file (could standardise file names to simplify)
    zip_base <- basename(zip_path)
    zip_name <- sub("\\.zip$", "", zip_base)
    
    # Create tmp directory for unzipped file
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(zip_path, files = paste0(zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
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
      metric = "sequence_length_r1",
      sample = sample_name,
      value = sequence_length_r1))
    
    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
    
  }
  return(results)
}

get_sequence_length_r2 <- function(){
  
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    # Get path to zip file (could standardise file names to simplify)
    zip_path <- list.files(sample_dir, 
                           pattern = "_r2_raw_fastqc\\.zip$|_r2_fastqc_raw_metrics\\.zip$", 
                           full.names = TRUE)
    
    # Give if missing zip enter NA value, then skip sample
    if(length(zip_path) == 0) {
      results <- rbind(results, data.frame(
        metric = "per_sequence_quality_score_r2",
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip file (could standardise file names to simplify)
    zip_base <- basename(zip_path)
    zip_name <- sub("\\.zip$", "", zip_base)
    
    # Create tmp directory for unzipped file
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(zip_path, files = paste0(zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
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
      metric = "sequence_length_r2",
      sample = sample_name,
      value = sequence_length_r2))
    
    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
    
  }
  return(results)
}

get_per_base_N_content_r1 <- function(){
  
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    # Get path to zip file (could standardise file names to simplify)
    zip_path <- list.files(sample_dir, 
                           pattern = "_r1_raw_fastqc\\.zip$|_r1_fastqc_raw_metrics\\.zip$", 
                           full.names = TRUE)
    
    # Give if missing zip enter NA value, then skip sample
    if(length(zip_path) == 0) {
      results <- rbind(results, data.frame(
        metric = "get_per_base_N_content_r1",
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip file (could standardise file names to simplify)
    zip_base <- basename(zip_path)
    zip_name <- sub("\\.zip$", "", zip_base)
    
    # Create tmp directory for unzipped file
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(zip_path, files = paste0(zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
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
      metric = "per_base_N_content_r1",
      sample = sample_name,
      value = per_base_N_content_r1))
    
    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
    
  }
  return(results)
}

get_per_base_N_content_r2 <- function(){
  
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  results <- data.frame(metric = character(), sample = character(), value = numeric())
  
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    # Get path to zip file (could standardise file names to simplify)
    zip_path <- list.files(sample_dir, 
                           pattern = "_r2_raw_fastqc\\.zip$|_r2_fastqc_raw_metrics\\.zip$", 
                           full.names = TRUE)
    
    # Give if missing zip enter NA value, then skip sample
    if(length(zip_path) == 0) {
      results <- rbind(results, data.frame(
        metric = "get_per_base_N_content_r2",
        sample = sample_name,
        value = NA
      ))
      next
    }
    
    # Unzip fastqc_data.txt from zip file (could standardise file names to simplify)
    zip_base <- basename(zip_path)
    zip_name <- sub("\\.zip$", "", zip_base)
    
    # Create tmp directory for unzipped file
    tmp_dir <- file.path(sample_dir, "tmp")
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
    
    # Unzip metrics txt file
    unzip(zip_path, files = paste0(zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
    
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
      metric = "per_base_N_content_r2",
      sample = sample_name,
      value = per_base_N_content_r2))
    
    # Remove tmp directory
    Sys.sleep(1) # Pause needed to allow files to be deleted
    unlink(tmp_dir, recursive = TRUE)
    
  }
  return(results)
}




