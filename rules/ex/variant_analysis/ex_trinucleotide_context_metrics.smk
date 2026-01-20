"""
Calculate trinucleotide contexts for called somatic mutations
    - Compare to reference contexts using cosine similarity
"""
rule ex_trinucleotide_context_metrics:
    input:
        vcf_path = "results/{ex_sample}/{ex_sample}_variants.vcf",
        vcf_all_path = "tmp/{ex_sample}/{ex_sample}_all_positions.vcf",
        ref_fasta_path = config["sci_params"]["global"]["reference_genome"],
        ref_contexts_path = config["sci_params"]["global"]["reference_tri_contexts"],
        ref_trinuc_counts_path = config["sci_params"]["global"]["reference_genome_trinuc_counts"]
    output:
        proportions_csv = "results/{ex_sample}/{ex_sample}_trinuc_proportions.csv",
        similarities_csv = "results/{ex_sample}/{ex_sample}_trinuc_similarities.csv",
        plot_pdf_normalised = "results/{ex_sample}/{ex_sample}_trinuc_plots_normalised.pdf"
    params:
        sample = "{ex_sample}"
    log:
        "logs/{ex_sample}/ex_trinucleotide_context_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_trinucleotide_context_metrics.benchmark.txt"
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
