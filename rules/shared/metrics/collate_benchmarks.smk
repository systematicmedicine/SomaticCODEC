"""
Collates all benchmarks into a single CSV
"""

from definitions.paths import log as L

rule collate_benchmarks:
    input:
        git_metadata = L.GIT_METADATA,
        job_log_csv = L.JOB_LOG
    output:
        combined_benchmarks = L.COMBINED_BENCHMARKS
    log:
        L.COLLATE_BENCHMARKS
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
