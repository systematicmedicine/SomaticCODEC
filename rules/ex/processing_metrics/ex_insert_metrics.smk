"""
Shows distribution of insert sizes (distance between 5' end of R1 and 3' end of R2) for correctly paired (same chr, within 500bp) reads 
"""

from definitions.paths.io import ex as EX
from definitions.paths import log as L

rule ex_insert_metrics:
    input:
        bam = EX.FILTERED_BAM,
        dictf = os.path.splitext(config["sci_params"]["shared"]["reference_genome"])[0] + ".dict"
    output:
        txt = EX.MET_INSERT_SIZE_TXT,
        hist = EX.MET_INSERT_SIZE_PDF
    log:
        L.EX_INSERT_METRICS
    benchmark:
        "logs/{ex_sample}/ex_insert_metrics.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]
    shell:
        """
        # Set memory limit and generate insert size metrics
        picard -Xmx{resources.memory}g -Djava.io.tmpdir=tmp \
            CollectInsertSizeMetrics \
            I={input.bam} \
            O={output.txt} \
            H={output.hist} \
            M=0.5 \
            W=600 \
            DEVIATIONS=100 2>> {log}
        """