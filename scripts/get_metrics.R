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
                                       pattern = "_samtools_stats.txt$|_map_metrics.txt$", 
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
    
    # Calculate alignment rate (only works on samtools stats files)
    if(any(grepl("_samtools_stats\\.txt$", alignment_stats_path))){
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

# collate germline variant call metrics
get_germline_variant_metrics <- function(){
  
  # Get list of sample directories within metrics directory
  sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
  
  #create empty object to store metrics
  results <- data.frame(
    sample = character(),
    metric = character(),
    value = numeric(),
    stringsAsFactors = FALSE
  )
  
  #loop through sample directory and create path files for variantCall files
  for (sample_dir in sample_dirs) {
    sample_name <- basename(sample_dir)
    txt_path <- list.files(sample_dir, pattern = "variantCall_summary.*\\.txt$",
                           ignore.case = TRUE, full.names = TRUE)
    
    # If summary file not found add NA then skip sample
    if (length(txt_path) == 0 || is.na(txt_path)) {
      results <- rbind(results, data.frame(
        metric = "germline_variants",
        sample = sample_name,
        value = NA))
        
        results <- rbind(results, data.frame(
          metric = "SNV_indel_ratio",
          sample = sample_name,
          value = NA))
          
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
                                       pattern = "_samtools_stats.txt$|_map_metrics.txt$", 
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
    
    # Calculate alignment rate (only works on samtools stats files)
    if(any(grepl("_samtools_stats\\.txt$", alignment_stats_path))){
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

# get_gc_deviation_r1 <- function(){
#   
#   sample_dirs <- list.dirs("metrics", full.names = TRUE, recursive = FALSE)
#   results <- data.frame(metric = character(), sample = character(), value = numeric())
#   
#   for (sample_dir in sample_dirs) {
#     sample_name <- basename(sample_dir)
#     # Get path to processed fastqc file
#     proc_zip_path <- list.files(sample_dir, 
#                                 pattern = "_processed_r2_fastqc\\.zip$|_r2_filter_metrics\\.zip$", 
#                                 full.names = TRUE)
#     
#     # If missing processed fastqc zip file enter NA value, then skip sample
#     if (length(proc_zip_path) == 0) {
#       results <- rbind(results, data.frame(
#         metric = "overrepresented_sequences_r2",
#         sample = sample_name,
#         value = NA
#       ))
#       next
#     }
#     
#     # Unzip fastqc_data.txt from zip file
#     proc_zip_base <- basename(proc_zip_path)
#     proc_zip_name <- sub("\\.zip$", "", proc_zip_base)
#     
#     # Create tmp directory for unzipped files
#     tmp_dir <- file.path(sample_dir, "tmp")
#     if (!dir.exists(tmp_dir)) dir.create(tmp_dir)
#     
#     # Unzip metrics txt file
#     unzip(proc_zip_path, files = paste0(proc_zip_name, "/fastqc_data.txt"), exdir = tmp_dir)
#     
#     # Get path for unzipped metrics file
#     proc_fastqc_data_path <- file.path(tmp_dir, proc_zip_name, "fastqc_data.txt")
#     
#     # Put all lines of txt file into character vector
#     proc_fastqc_lines <- readLines(proc_fastqc_data_path)
#     
#     # Find start and end of per sequence GC content section
#     start_line <- grep("^>>Per sequence GC content", proc_fastqc_lines)
#     end_lines <- grep("^>>END_MODULE", proc_fastqc_lines)
#     end_line <- end_lines[which(end_lines > start_line)[1]]
#     
#     # Extract per sequence GC content section lines (skip headers and end module lines)
#     section_lines <- proc_fastqc_lines[(start_line):(end_line - 1)]
#     
#     # Parse lines to dataframe
#     gc_content_df <- read.delim(text = section_lines,
#                                                skip = 1,
#                                                header = TRUE)
#     colnames(gc_content_df) <- c("GC_content", "Count")
#     
#     
#     
#     # Add to results
#     results <- rbind(results, data.frame(
#       metric = "overrepresented_sequences_r2",
#       sample = sample_name,
#       value = overrepresented_sequences))
#     
#       
#     }
#     
#     # Remove tmp directory
#     Sys.sleep(1) # Pause needed to allow files to be deleted
#     unlink(tmp_dir, recursive = TRUE)
#   }
#   
#   return(results)
#   
# }
