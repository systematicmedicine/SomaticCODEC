"""
--- other_metrics.smk ---

Rules for creating metrics files that are not part of ex or ms pipelines

Authors:
    - Joshua Johnstone
    - Cameron Fraser

"""

import scripts.get_metadata as md


# Write git metadata to file for version tracking
rule write_git_metadata:
    output:
        file_path = "logs/pipeline/git_metadata.json"
    log:
        "logs/pipeline/write_git_metadata.log"
    benchmark:
        "logs/pipeline/write_git_metadata.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
    script:
        "../scripts/write_git_metadata.py"


# Count number of reads in FASTQ and BAM files
rule count_reads:
        input:
            final_ex_bams = expand("tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam", ex_sample = md.get_ex_sample_ids(config)),
            final_ms_bams = expand("tmp/{ms_sample}/{ms_sample}_read_group_map.bam", ms_sample = md.get_ms_sample_ids(config))
        output:
            json_paths = expand(
                "metrics/{sample}/{sample}_read_counts.json", 
                sample = md.get_ex_sample_ids(config) + 
                md.get_ms_sample_ids(config) + 
                md.get_ex_lane_ids(config)
                )
        log:
            "logs/batch/count_reads.log"
        benchmark:
            "logs/batch/count_reads.benchmark.txt"
        threads:
            config["resources"]["threads"]["moderate"]
        resources:
            memory = config["resources"]["memory"]["moderate"]
        shell:
             "python scripts/count_reads.py > {log} 2>&1"


# Generates a pass/fail report for component & system level metrics
rule create_metrics_report:
    input:
        component_metrics_metadata = config["files"]["component_metrics_metadata"],
        system_metrics_metadata = config["files"]["system_metrics_metadata"],
        ms_metrics = ms_metrics,
        ex_metrics = ex_metrics
    output:
        csv_path = "metrics/metrics_report.csv",
        heatmap_path = "metrics/metrics_heatmap.png"
    log:
        "logs/pipeline/create_metrics_report.log"
    benchmark:
        "logs/pipeline/create_metrics_report.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
    script:
        "../scripts/metrics_report.R"


# Collates all benchmarks into a single CSV
rule collate_benchmarks:
    input:
        rules.write_git_metadata.output.file_path,
        rules.count_reads.output.json_paths,
        rules.create_metrics_report.output
    output:
        file_path = "logs/pipeline/combined_benchmarks.csv"
    log:
        "logs/pipeline/collate_benchmarks.log"
    resources:
        memory = config["resources"]["memory"]["light"]
    script:
        "../scripts/collate_benchmarks.py"
