# ----------------------------------------------------------------------------------------------
#   RULE ms_germline_mask
#
#   Creates a BED file from germline risk VCF 
# 
#   Notes:
#       - For deletions, the stop value of the BED region is determined by the length difference 
#           between ALT and REF alleles. 
#       - For insertions and SNV's, the BED region is length 1
# ----------------------------------------------------------------------------------------------

rule ms_germline_mask:
    input:
        vcf = "tmp/{ms_sample}/{ms_sample}_ms_germ_risk.vcf",
        ref_fai = config["sci_params"]["global"]["reference_genome"] + ".fai"
    output:
        intermediate_del_unformatted = temp("tmp/{ms_sample}/{ms_sample}_germ_deletions_unformatted.bed"),
        intermediate_ins_unformatted = temp("tmp/{ms_sample}/{ms_sample}_germ_insertions_unformatted.bed"),
        intermediate_snv_unformatted = temp("tmp/{ms_sample}/{ms_sample}_germ_snvs_unformatted.bed"),
        intermediate_del_unpadded = temp("tmp/{ms_sample}/{ms_sample}_germ_deletions_unpadded.bed"),
        intermediate_ins_unpadded = temp("tmp/{ms_sample}/{ms_sample}_germ_insertions_unpadded.bed"),
        ms_germ_del_bed = temp("tmp/{ms_sample}/{ms_sample}_germ_deletions.bed"),
        ms_germ_ins_bed = temp("tmp/{ms_sample}/{ms_sample}_germ_insertions.bed"),
        ms_germ_snv_bed = temp("tmp/{ms_sample}/{ms_sample}_germ_snvs.bed")
    params:
        indel_padding_bases = config["sci_params"]["ms_germline_mask"]["indel_padding_bases"]
    log:
        "logs/{ms_sample}/ms_germline_variants_mask.log"
    benchmark:
        "logs/{ms_sample}/ms_germline_variants_mask.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]
    shell:
        """        
        vcf2bed --deletions < {input.vcf} > {output.intermediate_del_unformatted} 2>> {log}
        vcf2bed --insertions < {input.vcf} > {output.intermediate_ins_unformatted} 2>> {log}
        vcf2bed --snvs < {input.vcf} > {output.intermediate_snv_unformatted} 2>> {log}

        cut -f1-3 {output.intermediate_del_unformatted} > {output.intermediate_del_unpadded} 2>> {log}
        cut -f1-3 {output.intermediate_ins_unformatted} > {output.intermediate_ins_unpadded} 2>> {log}
        cut -f1-3 {output.intermediate_snv_unformatted} > {output.ms_germ_snv_bed} 2>> {log}

        bedtools slop \
        -b {params.indel_padding_bases} \
        -g {input.ref_fai} \
        -i {output.intermediate_del_unpadded} > {output.ms_germ_del_bed} 2>> {log}
        
        bedtools slop \
        -b {params.indel_padding_bases} \
        -g {input.ref_fai} \
        -i {output.intermediate_ins_unpadded} > {output.ms_germ_ins_bed} 2>> {log}
        """