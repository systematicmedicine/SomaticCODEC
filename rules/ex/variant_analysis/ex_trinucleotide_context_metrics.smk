"""
Calculate trinucleotide contexts for called somatic mutations
    - Compare to reference contexts using cosine similarity
"""
rule ex_trinucleotide_context_metrics:
    input:
        vcf_path = "results/{ex_sample}/{ex_sample}_variants.vcf",
        ref_fasta_path = config["sci_params"]["global"]["reference_genome"],
        ref_contexts_path = config["sci_params"]["global"]["reference_tri_contexts"]
    output:
        sample_csv_raw = "results/{ex_sample}/{ex_sample}_trinuc_context_raw.csv",
        sample_csv_normalised = "results/{ex_sample}/{ex_sample}_trinuc_context_normalised.csv",
        similarities_csv_raw = "results/{ex_sample}/{ex_sample}_trinuc_similarities_raw.csv",
        plot_pdf_raw = "results/{ex_sample}/{ex_sample}_trinuc_plots_raw.pdf"
    params:
        sample = "{ex_sample}"
    log:
        "logs/{ex_sample}/ex_trinuc_context.log"
    benchmark:
        "logs/{ex_sample}/ex_trinuc_context.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate trinucleotide contexts
        ex_trinucleotide_context_metrics.py \
            --vcf_path {input.vcf_path} \
            --ref_fasta_path {input.ref_fasta_path} \
            --ref_contexts_path {input.ref_contexts_path} \
            --sample_csv_raw {output.sample_csv_raw} \
            --similarities_csv_raw {output.similarities_csv_raw} \
            --plot_pdf_raw {output.plot_pdf_raw} \
            --sample {params.sample} \
            --log {log} 2>> {log}
        """
