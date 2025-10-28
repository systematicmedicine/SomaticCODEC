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
        sample_csv = "metrics/{ex_sample}/{ex_sample}_trinuc_context.csv",
        similarities_csv = "metrics/{ex_sample}/{ex_sample}_trinuc_similarities.csv",
        plot_pdf = "metrics/{ex_sample}/{ex_sample}_trinuc_plots.pdf"
    log:
        "logs/{ex_sample}/ex_trinuc_context.log"
    benchmark:
        "logs/{ex_sample}/ex_trinuc_context.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        os.path.join(workflow.basedir, "scripts", "ex_trinuc_contexts.py")