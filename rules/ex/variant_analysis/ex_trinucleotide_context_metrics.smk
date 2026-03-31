"""
Calculate trinucleotide contexts for called somatic mutations
    - Compare to reference contexts using cosine similarity
"""

from definitions.paths.io import ex as EX
from definitions.paths import log as L
from definitions.paths import benchmark as B

rule ex_trinucleotide_context_metrics:
    input:
        vcf_path = EX.CALLED_SNVS,
        vcf_all_path = EX.CALL_SOMATIC_SNV_INT3,
        ref_fasta_path = config["sci_params"]["reference_files"]["genome"],
        ref_contexts_path = config["sci_params"]["reference_files"]["tri_contexts"],
        ref_trinuc_counts_path = config["sci_params"]["reference_files"]["genome_trinuc_counts"]
    output:
        proportions_csv = EX.MET_TRINUC_PROPORTIONS,
        similarities_csv = EX.MET_TRINUC_SIMILARITIES,
        plot_pdf_normalised = EX.MET_TRINUC_PLOTS
    params:
        sample = "{ex_sample}"
    log:
        L.EX_TRINUCLEOTIDE_CONTEXT_METRICS
    benchmark:
        B.EX_TRINUCLEOTIDE_CONTEXT_METRICS
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate trinucleotide contexts
        ex_trinucleotide_context_metrics.py \
            --vcf_path {input.vcf_path} \
            --vcf_all_path {input.vcf_all_path} \
            --ref_fasta_path {input.ref_fasta_path} \
            --ref_contexts_path {input.ref_contexts_path} \
            --ref_trinuc_counts_path {input.ref_trinuc_counts_path} \
            --proportions_csv {output.proportions_csv} \
            --similarities_csv {output.similarities_csv} \
            --plot_pdf_normalised {output.plot_pdf_normalised} \
            --sample {params.sample} \
            --log {log} 2>> {log}
        """
