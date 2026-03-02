"""
Collates all benchmarks into a single CSV
"""

rule collate_benchmarks:
    input:
        git_metadata = "logs/shared_rules/git_metadata.json",
        timeline_plot = "logs/shared_rules/run_timeline.pdf"
    output:
        combined_benchmarks = "logs/shared_rules/combined_benchmarks.csv"
    log:
        "logs/shared_rules/collate_benchmarks.log"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Collate benchmarks
        collate_benchmarks.py \
            --combined_benchmarks {output.combined_benchmarks} \
            --log {log} 2>> {log}
        """
