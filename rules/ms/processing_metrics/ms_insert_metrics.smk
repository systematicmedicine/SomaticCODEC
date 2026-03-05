"""
Generates ms insert size metrics
"""

from definitions.paths.io import ms as MS

rule ms_insert_metrics:
    input:
        bam = MS.DEDUPED_BAM,
        dictf = os.path.splitext(config["sci_params"]["shared"]["reference_genome"])[0] + ".dict"
    output:
        insert_metrics = MS.MET_INSERT_SIZE_TXT,
        insert_hist = MS.MET_INSERT_SIZE_PDF
    log:
        "logs/{ms_sample}/ms_insert_metrics.log"
    benchmark:
        "logs/{ms_sample}/ms_insert_metrics.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit and generate insert size metrics
        picard -Xmx{resources.memory}g -Djava.io.tmpdir=tmp CollectInsertSizeMetrics \
            I={input.bam} \
            O={output.insert_metrics} \
            H={output.insert_hist} 2>> {log}
        """ 