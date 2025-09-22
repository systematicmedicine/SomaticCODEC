# ===========================================================================
# Metrics report.R
#
# Collate component level and system level metrics into a report
#   - Component level metrics are defined in config/component_metrics.xlsx
#
# Authors: 
#   - Cameron Fraser
#   - Joshua Johnstone
# ===========================================================================

library(jsonlite)
library(ggplot2)
library(dplyr)

# ---------------------------------------------------------------------------
# Format targets
# ---------------------------------------------------------------------------
format_targets <- function(nn_lower, nn_upper, ideal_lower, ideal_upper){
  targets <- sprintf(
    "Non-neg (%s; %s); ideal (%s; %s)",
    as.character(nn_lower),
    as.character(nn_upper),
    as.character(ideal_lower),
    as.character(ideal_upper)
  )
  return(targets)
}

# ---------------------------------------------------------------------------
# Coerce dataframe columns to expected types
# ---------------------------------------------------------------------------

coerce_types <- function(df, schema) {
  
  for (col in names(schema)) {
    expected_type <- schema[[col]] 
    
    # If the column is missing from the data, create it with NA values
    if (!col %in% names(df)) {
      warning(sprintf("Column '%s' missing from data. Filling with NA.", col))
      df[[col]] <- NA
    }

    # Type coercion based on schema
    if (expected_type == "numeric") {
      df[[col]] <- suppressWarnings(as.numeric(df[[col]]))
    } else if (expected_type == "character") {
      df[[col]] <- as.character(df[[col]])
    } else if (expected_type == "logical") {
      df[[col]] <- suppressWarnings(as.logical(df[[col]]))
    } else {
      stop(sprintf("Unsupported type: %s for column %s", expected_type, col))
    }
  }

  # Return dataframe
  return(df)
}

# ---------------------------------------------------------------------------
# Find all files that match a pattern
# ---------------------------------------------------------------------------

find_metric_files <- function(pattern) {
  
  # Ensure the pattern only matches files ending in the given suffix
  full_pattern <- paste0(pattern, "$")
  
  files <- list.files(
    path = "metrics",
    pattern = full_pattern,
    recursive = TRUE,
    full.names = TRUE
  )
  
  return(files)
}

# ---------------------------------------------------------------------------
# Get a metric from a txt file, using a regex pattern (single line)
# ---------------------------------------------------------------------------

get_metric_txt <- function(file_path, pattern) {
  # Check file exists
  if (!file.exists(file_path)) {
    warning(sprintf("File not found: %s", file_path))
    return(NA_real_)
  }

  lines <- readLines(file_path, warn = FALSE)

  for (line in lines) {
    match <- regexpr(pattern, line, perl = TRUE)
    if (match[[1]] == -1) next  # No match on this line

    # Get metadata for capture groups
    capture_names  <- attr(match, "capture.names")
    capture_start  <- attr(match, "capture.start")
    capture_length <- attr(match, "capture.length")

    if (length(capture_names) == 0 || all(capture_start == -1)) {
      warning(sprintf("Pattern matched line but no named capture groups were extracted.\nLine: %s", line))
      return(NA_real_)
    }

    # Extract non-empty named groups
    values <- mapply(function(start, len) {
      if (start == -1) return(NA_character_)
      substr(line, start, start + len - 1)
    }, capture_start, capture_length, USE.NAMES = FALSE)

    # Try to coerce non-empty groups to numeric
    for (val in values) {
      val_num <- suppressWarnings(as.numeric(gsub(",", "", val)))
      if (!is.na(val_num)) return(val_num)
    }

    warning(sprintf("Pattern matched line, but no numeric values found in named groups.\nLine: %s", line))
    return(NA_real_)
  }

  # If no lines matched the pattern
  warning(sprintf("No line in %s matched the pattern:\n%s", file_path, pattern))
  return(NA_real_)
}

# ---------------------------------------------------------------------------
# Get a metric from a JSON file, using a dot notation key pattern
# ---------------------------------------------------------------------------

get_metric_json <- function(file_path, key_path) {
  # Return NA if file doesn't exist
  if (!file.exists(file_path)) return(NA)
  
  # Try parsing JSON
  json_data <- tryCatch(jsonlite::fromJSON(file_path), error = function(e) return(NULL))
  if (is.null(json_data)) return(NA)

  # Traverse nested structure using dot-separated key path
  keys <- strsplit(key_path, "\\.")[[1]]
  value <- json_data
  for (key in keys) {
    if (!is.list(value) || is.null(value[[key]])) return(NA)
    value <- value[[key]]
  }

  # Ensure output is numeric or NA
  numeric_value <- suppressWarnings(as.numeric(value))
  if (length(numeric_value) != 1 || is.na(numeric_value)) return(NA)
  
  return(numeric_value)
}


# ---------------------------------------------------------------------------
# Grades a metric agains nn & ideal criteria
# ---------------------------------------------------------------------------

grade_metric_value <- function(value, ideal_lower, ideal_upper, nn_lower, nn_upper) {
  # Ensure all bounds are numeric
  value <- suppressWarnings(as.numeric(value))
  ideal_lower <- as.numeric(ideal_lower)
  ideal_upper <- as.numeric(ideal_upper)
  nn_lower <- as.numeric(nn_lower)
  nn_upper <- as.numeric(nn_upper)

  if (is.na(value)) {
    return(NA)
  } else if (!is.na(ideal_lower) && !is.na(ideal_upper) &&
             value >= ideal_lower && value <= ideal_upper) {
    return("pass_ideal")
  } else if (!is.na(nn_lower) && !is.na(nn_upper) &&
             value >= nn_lower && value <= nn_upper) {
    return("pass_nn")
  } else {
    return("fail")
  }
}

# ---------------------------------------------------------------------------
# Assess a single metric
# ---------------------------------------------------------------------------

assess_metric <- function(metric) {
  # Create empty results list
  results_list <- list()
  
  # Extract values from the input
  metric_name <- metric[["Name"]]
  stage <- metric[["Stage"]]
  nn_lower <- metric["nn_lower"]
  nn_upper <- metric["nn_upper"]
  ideal_lower <- metric["ideal_lower"]
  ideal_upper <- metric["ideal_upper"]
  file_pattern <- metric[["file_pattern"]]
  value_pattern <- metric[["value_pattern"]]
 
  # Find all relevant metrics files
  matching_files <- find_metric_files(file_pattern)
  message(sprintf("[INFO] Found %d files for pattern: %s", length(matching_files), file_pattern))
  
  for (file_path in matching_files) {
    # Decide which getter to use based on file extension
    if (grepl("\\.json$", file_path, ignore.case = TRUE)) {
      value <- get_metric_json(file_path, value_pattern)
    } else if (grepl("\\.(txt|csv)$", file_path, ignore.case = TRUE)) {
      value <- get_metric_txt(file_path, value_pattern)
    } else {
      message(sprintf("Unsupported file type: %s", file_path))
      next
    }
    
    # Determine metric grade
    grade <- grade_metric_value(value, ideal_lower, ideal_upper, nn_lower, nn_upper)

    # Extract sample ID from filename (e.g., S001_metric.txt → S001)
    sample_id <- sub("^metrics/([^/]+)/.*$", "\\1", file_path)

    # Create formatted targets string
    targets <- format_targets(nn_lower, nn_upper, ideal_lower, ideal_upper)

    # Append a row to results list
    results_list[[length(results_list) + 1]] <- data.frame(
      Metric = metric_name,
      Stage = stage,
      Sample = sample_id,
      Value = value,
      Grade = grade,
      Targets = targets
    )
  }
  
  # Combine all rows into one data frame
  return(bind_rows(results_list))
}

# ---------------------------------------------------------------------------
# Create metrics heatmap
# ---------------------------------------------------------------------------

plot_metric_heatmap <- function(df, title) {
  library(ggplot2)
  library(dplyr)

  required_cols <- c("Sample", "Metric", "Grade")
  if (!all(required_cols %in% names(df))) {
    stop("Data frame must contain columns: Sample, Metric, Grade")
  }

  exp_name <- CONFIG$experiment$name
  date <- format(Sys.Date(), "%Y-%m-%d")
  pipeline_version <- fromJSON("logs/pipeline/git_metadata.json")$git_tag
  title <- paste0(exp_name, " metrics")
  subtitle <- paste0(date, ", ", pipeline_version)

  df <- df %>%
    mutate(
      Metric = factor(Metric, levels = rev(unique(Metric))),
      Grade = factor(
        Grade,
        levels = c("pass_ideal", "pass_nn", "fail", NA),
        labels = c("pass_ideal", "pass_nn", "fail", "NA"),
        exclude = NULL
      ),
      Metric_pos = as.numeric(Metric),
      Sample = as.factor(Sample)  
    )

  ggplot(df, aes(x = Sample, y = Metric, fill = Grade)) +
    geom_tile(color = "white", linewidth = 0.2) +
    geom_hline(yintercept = seq(1.5, length(levels(df$Metric)) - 0.5, by = 1), color = "grey95", linewidth = 0.3) +
    geom_vline(xintercept = seq(1.5, length(levels(df$Sample)) - 0.5, by = 1), color = "grey95", linewidth = 0.3) +
    scale_fill_manual(
      values = c(
        "pass_ideal" = "#2ecc71",
        "pass_nn" = "#f1c40f",
        "fail" = "#e74c3c",
        "NA" = "#bdc3c7"
      ),
      na.value = "#bdc3c7",
      drop = FALSE
    ) +
    theme_minimal(base_size = 10) +
    theme(
      panel.grid = element_blank(),
      axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5),
      axis.text.y = element_text(size = 6),
      plot.background = element_rect(fill = "white", color = NA),
      panel.background = element_rect(fill = "white", color = NA),
      legend.background = element_rect(fill = "white", color = NA),
      legend.box.background = element_rect(fill = "white", color = NA)
    ) +
    labs(
      title = title,
      subtitle = subtitle,
      x = "Sample",
      y = "Metric",
      fill = "Grade"
    )
}

# ---------------------------------------------------------------------------
# Scale heatmap and save to disk
# ---------------------------------------------------------------------------
save_scaled_heatmap <- function(plot, path, nrows, ncols,
                                base_width = 0.3, base_height = 0.25,
                                min_width = 6, max_width = 20,
                                min_height = 6, max_height = 30,
                                dpi = 300) {
  # Calculate width and height
  width  <- max(min_width, min(ncols * base_width, max_width))
  height <- max(min_height, min(nrows * base_height, max_height))

  # Save the plot
  ggsave(path, plot = plot, width = width, height = height, dpi = dpi)
}
