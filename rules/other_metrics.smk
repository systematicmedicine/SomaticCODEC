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
        file_path = "logs/git_metadata.json"
    log:
        "logs/write_git_metadata.log"
    benchmark:
        "logs/write_git_metadata.benchmark.txt"
    script:
        "../scripts/write_git_metadata.py"


# Count number of reads and bases in FASTQ and BAM files
rule count_reads_and_bases:
        input:
            final_ex_bams = expand("tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam", ex_sample = md.get_ex_sample_ids(config)),
            final_ms_bams = expand("tmp/{ms_sample}/{ms_sample}_sorted_map.bam", ms_sample = md.get_ms_sample_ids(config))
        output:
            json_paths = expand(
                "metrics/{sample}/{sample}_read_base_counts.json", 
                sample = md.get_ex_sample_ids(config) + 
                md.get_ms_sample_ids(config) + 
                md.get_ex_lane_ids(config)
                )
        threads:
            max(1, os.cpu_count() // 4)
        log:
            "logs/count_reads_and_bases.log"
        benchmark:
            "logs/count_reads_and_bases.benchmark.txt"
        shell:
             "python scripts/count_reads_and_bases.py > {log} 2>&1"


# Generates a pass/fail report for component & system level metrics
rule create_metrics_report:
    input:
        component_metrics_metadata = config["component_metrics_path"],
        system_metrics_metadata = config["system_metrics_path"],
        ms_metrics = ms_metrics,
        ex_metrics = ex_metrics
    output:
        csv_path = "metrics/metrics_report.csv",
        heatmap_path = "metrics/metrics_heatmap.png"
    log:
        "logs/create_metrics_report.log"
    benchmark:
        "logs/create_metrics_report.benchmark.txt"
    script:
        "../scripts/metrics_report.R"


# Collates all benchmarks into a single CSV
rule collate_benchmarks:
    input:
        rules.write_git_metadata.output.file_path,
        rules.count_reads_and_bases.output.json_paths,
        rules.create_metrics_report.output
    output:
        file_path = "logs/combined_benchmarks.csv"
    log:
        "logs/collate_benchmarks.log"
    script:
        "../scripts/collate_benchmarks.py"


# Calculate disk usage at end of run
rule log_disk_usage:
    input:
        rules.collate_benchmarks.output
    output:
        "logs/disk_usage.txt"
    shell:
        """
        echo "End of run disk usage at $(date):" > {output}
        du -h --max-depth=1 . >> {output}
        """