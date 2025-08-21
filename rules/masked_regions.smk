"""
--- masked_regions.smk ---

Rules for masking genomic regions where somatic variant cannot be confidently called.

Inputs:
    - gnomAD common variants (1% VAF)
    - GIAB all difficult regions
    - Low depth regions from ms raw alignment (<30x)
    - ms germline variant positions
    
Output: BED file containing all regions to mask

Authors:
    - Joshua Johnstone
    - Benjamin Barry
    - James Phie
    - Cameron Fraser
"""

import scripts.get_metadata as md

# Creates a mask for genomic positions with low ms read depth
rule ms_low_depth_mask:
    input:
        bam = "tmp/{ms_sample}/{ms_sample}_read_group_map.bam",
        bai = "tmp/{ms_sample}/{ms_sample}_read_group_map.bam.bai"
    output:
        bed = temp("tmp/{ms_sample}/{ms_sample}_lowdepth.bed"),
        depth_histogram = "metrics/{ms_sample}/{ms_sample}_depth_histogram.txt",
        intermediate_depth_per_base = temp("tmp/{ms_sample}/{ms_sample}_depth_per_base.txt"),
        intermediate_lowdepth = temp("tmp/{ms_sample}/{ms_sample}_lowdepth.txt"),
        intermediate_lowdepth_sorted = temp("tmp/{ms_sample}/{ms_sample}_lowdepth_sorted.txt"),
        intermediate_depth_values = temp("tmp/{ms_sample}/{ms_sample}_depth_values.txt"),
        intermediate_depth_values_sorted = temp("tmp/{ms_sample}/{ms_sample}_depth_values_sorted.txt")
    log:
        "logs/{ms_sample}/ms_low_depth_mask.log"
    benchmark:
        "logs/{ms_sample}/ms_low_depth_mask.benchmark.txt"
    params:
        threshold = config["ms_low_depth_mask"]["threshold"]
    shell:
        """
        samtools depth -aa {input.bam} > {output.intermediate_depth_per_base} 2>> {log}

        awk -v threshold={params.threshold} '$3 < threshold {{print $1"\t"($2-1)"\t"$2}}' \
        {output.intermediate_depth_per_base} > {output.intermediate_lowdepth} 2>> {log}

        sort {output.intermediate_lowdepth} -k1,1V -k2,2n > {output.intermediate_lowdepth_sorted} 2>> {log}

        bedtools merge -i {output.intermediate_lowdepth_sorted} > {output.bed} 2>> {log}

        awk '{{print $3}}' {output.intermediate_depth_per_base} > {output.intermediate_depth_values} 2>> {log}

        sort -n {output.intermediate_depth_values} > {output.intermediate_depth_values_sorted} 2>> {log}

        uniq -c {output.intermediate_depth_values_sorted} > {output.depth_histogram} 2>> {log}
        """

# Creates a mask genomic positions where germline variants have been called in ms sample
    # For deletions, the stop value of the BED region is determined by the length difference between ALT and REF alleles. 
    # For insertions and SNV's, the BED region is length 1
rule ms_germline_variants_mask:
    input:
        vcf = "tmp/{ms_sample}/{ms_sample}_ms_candidate_variants.vcf.gz"
    output:
        intermediate_uncompressed = temp("tmp/{ms_sample}/{ms_sample}_ms_candidate_variants_uncompressed.vcf"),
        intermediate_del_unformatted = temp("tmp/{ms_sample}/{ms_sample}_germ_deletions_unformatted.bed"),
        intermediate_ins_unformatted = temp("tmp/{ms_sample}/{ms_sample}_germ_insertions_unformatted.bed"),
        intermediate_snv_unformatted = temp("tmp/{ms_sample}/{ms_sample}_germ_snvs_unformatted.bed"),
        ms_germ_del_bed = temp("tmp/{ms_sample}/{ms_sample}_germ_deletions.bed"),
        ms_germ_ins_bed = temp("tmp/{ms_sample}/{ms_sample}_germ_insertions.bed"),
        ms_germ_snv_bed = temp("tmp/{ms_sample}/{ms_sample}_germ_snvs.bed")
    log:
        "logs/{ms_sample}/ms_germline_variants_mask.log"
    benchmark:
        "logs/{ms_sample}/ms_germline_variants_mask.benchmark.txt"
    shell:
        """
        zcat {input.vcf} > {output.intermediate_uncompressed} 2>> {log}
        
        vcf2bed --deletions < {output.intermediate_uncompressed} > {output.intermediate_del_unformatted} 2>> {log}

        vcf2bed --insertions < {output.intermediate_uncompressed} > {output.intermediate_ins_unformatted} 2>> {log}

        vcf2bed --snvs < {output.intermediate_uncompressed} > {output.intermediate_snv_unformatted} 2>> {log}

        cut -f1-3 {output.intermediate_del_unformatted} > {output.ms_germ_del_bed} 2>> {log}

        cut -f1-3 {output.intermediate_ins_unformatted} > {output.ms_germ_ins_bed} 2>> {log}

        cut -f1-3 {output.intermediate_snv_unformatted} > {output.ms_germ_snv_bed} 2>> {log}  
        """

# Creates a mask for-non canonical genomic locations 
    # e.g. chrUn, chr*_random, chrM, chrEBV

rule mask_noncanonical_chroms:
    input:
        fai = config['reference_path'] + ".fai"
    output:
        bed = temp("tmp/downloads/noncanonical_mask.bed")
    run:
        # Define canonical chromosomes
        canonical = {f"chr{i}" for i in range(1, 23)} | {"chrX", "chrY"}

        # Load the .fai and filter
        with open(input.fai) as fai_in, open(output.bed, "w") as bed_out:
            for line in fai_in:
                chrom, length, *_ = line.strip().split("\t")
                if chrom not in canonical:
                    bed_out.write(f"{chrom}\t0\t{length}\n")


# Combines all masks into a single BED file
rule combine_masks:
    input:
        gnomAD_bed = config['common_variants_path'],
        GIAB_bed = config['difficult_regions_path'],
        noncanonical_bed = rules.mask_noncanonical_chroms.output.bed,
        ms_lowdepth_bed = "tmp/{ms_sample}/{ms_sample}_lowdepth.bed",
        ms_germ_del_bed = "tmp/{ms_sample}/{ms_sample}_germ_deletions.bed",
        ms_germ_ins_bed = "tmp/{ms_sample}/{ms_sample}_germ_insertions.bed",
        ms_germ_snv_bed = "tmp/{ms_sample}/{ms_sample}_germ_snvs.bed",
        fai = config['reference_path'] + ".fai" 
    output:
        combined_bed = temp("tmp/{ms_sample}/{ms_sample}_combined_mask.bed"),
        intermediate_cat = temp("tmp/{ms_sample}/{ms_sample}_masks_cat.bed"),
        intermediate_sorted = temp("tmp/{ms_sample}/{ms_sample}_masks_sorted.bed")
    log:
        "logs/{ms_sample}/combine_masks.log"
    benchmark:
        "logs/{ms_sample}/combine_masks.benchmark.txt"
    shell:
        """
        cat {input.gnomAD_bed} \
        {input.GIAB_bed} \
        {input.noncanonical_bed} \
        {input.ms_lowdepth_bed} \
        {input.ms_germ_del_bed} \
        {input.ms_germ_ins_bed} \
        {input.ms_germ_snv_bed} > {output.intermediate_cat} 2>> {log}
        
        bedtools sort -faidx {input.fai} -i {output.intermediate_cat} > {output.intermediate_sorted} 2>> {log}

        bedtools merge -i {output.intermediate_sorted} > {output.combined_bed} 2>> {log}
        """

# Generate an include regions bed file for variant calling (opposite of combined bed)
rule generate_include_bed:
    input:
        ms_samples = config["ms_samples_path"],
        mask_bed = lambda wc: (
            f"tmp/{md.get_ex_to_ms_sample_map(config)[wc.ex_sample]}/"
            f"{md.get_ex_to_ms_sample_map(config)[wc.ex_sample]}_combined_mask.bed"
        ),
        fai = config["reference_path"] + ".fai"
    output:
        include_bed = "tmp/{ex_sample}/{ex_sample}_include.bed"
    log:
        "logs/{ex_sample}/generate_include_bed.log"
    benchmark:
        "logs/{ex_sample}/generate_include_bed.benchmark.txt"
    shell:
        """
        bedtools complement -i {input.mask_bed} -g {input.fai} > {output.include_bed} 2>> {log}
        """