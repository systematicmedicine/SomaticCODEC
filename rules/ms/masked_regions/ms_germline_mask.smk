"""
Creates a BED file from germline risk VCF 
    - For deletions, the stop value of the BED region is determined by the length difference between ALT and REF alleles
    - For insertions and SNV's, the BED region is length 1
"""

from definitions.paths.io import ms as MS

rule ms_germline_mask:
    input:
        vcf = MS.GERMLINE_RISK_VCF,
        ref_fai = config["sci_params"]["global"]["reference_genome"] + ".fai"
    output:
        # Intermediate files
        intermediate_del_unformatted = temp(MS.GERMLINE_MASK_INT1),
        intermediate_ins_unformatted = temp(MS.GERMLINE_MASK_INT2),
        intermediate_all_unformatted = temp(MS.GERMLINE_MASK_INT3),
        intermediate_del_unpadded = temp(MS.GERMLINE_MASK_INT4),
        intermediate_ins_unpadded = temp(MS.GERMLINE_MASK_INT5),
        ms_germ_del_bed = temp(MS.GERMLINE_MASK_INT6),
        ms_germ_ins_bed = temp(MS.GERMLINE_MASK_INT7),
        ms_germ_all_bed = temp(MS.GERMLINE_MASK_INT8),
        intermediate_cat_unsorted = temp(MS.GERMLINE_MASK_INT9),
        intermediate_cat_unmerged = temp(MS.GERMLINE_MASK_INT10),
        
        # Rule output
        ms_germ_risk_bed = temp(MS.GERMLINE_RISK_MASK)

    params:
        indel_padding_bases = config["sci_params"]["ms_germline_mask"]["indel_padding_bases"]
    log:
        "logs/{ms_sample}/ms_germline_variants_mask.log"
    benchmark:
        "logs/{ms_sample}/ms_germline_variants_mask.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["extra_heavy"]
    shell:
        """   
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}

        # Create unformatted BED file for all records in VCF
        vcf2bed --do-not-sort < {input.vcf} > {output.intermediate_all_unformatted} 2>> {log}

        # Create separate BED files for insertions and deletions (to allow padding)
        vcf2bed --deletions < {input.vcf} > {output.intermediate_del_unformatted} 2>> {log}
        vcf2bed --insertions < {input.vcf} > {output.intermediate_ins_unformatted} 2>> {log}

        # Format BED files
        cut -f1-3 {output.intermediate_del_unformatted} > {output.intermediate_del_unpadded} 2>> {log}
        cut -f1-3 {output.intermediate_ins_unformatted} > {output.intermediate_ins_unpadded} 2>> {log}
        cut -f1-3 {output.intermediate_all_unformatted} > {output.ms_germ_all_bed} 2>> {log}

        # Add padding bases on either side of deletion regions
        bedtools slop \
        -b {params.indel_padding_bases} \
        -g {input.ref_fai} \
        -i {output.intermediate_del_unpadded} > {output.ms_germ_del_bed} 2>> {log}
        
        # Add padding bases on either side of insertion regions
        bedtools slop \
        -b {params.indel_padding_bases} \
        -g {input.ref_fai} \
        -i {output.intermediate_ins_unpadded} > {output.ms_germ_ins_bed} 2>> {log}

        # Combine all germline risk masks
        cat {output.ms_germ_all_bed} \
        {output.ms_germ_del_bed} \
        {output.ms_germ_ins_bed} > {output.intermediate_cat_unsorted} 2>> {log}

        # Sort by chromosome then position
        sort {output.intermediate_cat_unsorted} -k1,1V -k2,2n > {output.intermediate_cat_unmerged} 2>> {log}

        # Merge adjacent regions
        bedtools merge -i {output.intermediate_cat_unmerged} > {output.ms_germ_risk_bed} 2>> {log}
        """