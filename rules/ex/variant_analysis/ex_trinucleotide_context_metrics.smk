"""
Calculate trinucleotide contexts for called somatic mutations
    - Compare to reference contexts using cosine similarity
"""
rule ex_trinucleotide_context_metrics:
    input:
        vcf_path = "results/{ex_sample}/{ex_sample}_variants.vcf",
        ref_fasta_path = config["sci_params"]["global"]["reference_genome"],
        context_csv_path = config["sci_params"]["global"]["reference_tri_contexts"]
    output:
        sample_csv = "results/{ex_sample}/{ex_sample}_trinuc_context.csv",
        similarities_csv = "results/{ex_sample}/{ex_sample}_trinuc_similarities.csv",
        plot_pdf = "results/{ex_sample}/{ex_sample}_trinuc_plots.pdf"
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
            --context_csv_path {input.context_csv_path} \
            --sample_csv {output.sample_csv} \
            --similarities_csv {output.similarities_csv} \
            --plot_pdf {output.plot_pdf} \
            --sample {params.sample} \
            --log {log} 2>> {log}
        """
