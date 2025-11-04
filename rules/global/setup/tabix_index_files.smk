# Creates index files for input VCFs

rule tabix_index_files:
    input:
        germline_vcf = config["sci_params"]["global"]["known_germline_variants"]
    output:
        germline_tbi = config["sci_params"]["global"]["known_germline_variants"] + ".tbi"
    log:
        "logs/global_rules/tabix_index_files.log"
    benchmark:
        "logs/global_rules/tabix_index_files.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        tabix -p vcf {input.germline_vcf} 2>> {log}
        """