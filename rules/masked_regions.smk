"""
--- masked_regions.smk ---

Rules for masking genomic regions where somatic variant cannot be confidently called.

Inputs:
    - gnomAD common variants (1% VAF)
    - GIAB all difficult regions
    - Low depth regions from ms raw alignment (<30x)
    - ms germline variant positions
    
Output: BED file containing all regions to mask

Author: Joshua Johnstone

"""

# Creates a mask for low depth (<30x) positions of ms raw alignment
rule ms_low_depth_mask:
    input:
        markdup_bam = "tmp/results/{ms_sample}_markdup.bam",
        markdup_bai = "tmp/results/{ms_sample}_markdup.bai"
    output:
        depth_stats = "tmp/metrics/alignment/{ms_sample}_depth.txt",
        bed = "tmp/ref/{ms_sample}_lowdepth.bed"
    params:
        threshold = 30
    shell:
        r"""

        # Get depth per base
        # -aa option includes all positions even if 0 depth
        samtools depth -aa {input.markdup_bam} > {output.depth_stats} 

        # Convert low-depth positions into BED regions
        # Steps as follows:
        # Sets depth threshold as variable inside awk
        # Runs following code block only on bases where 3rd column (depth) is less than the threshold
        # If chromosome has changed since previous base, closes region and starts new region
        # For first base, chrom will be undefined so != $1
        # If current base is not yet in a bed region:
        # Saves chromosome name with $1
        # Starts a new region at position $2
        # Sets start and end to this position
        # If current base is next to previous:
        # Extends the region (moves end forward)
        # If current base is not next to previous:
        # Prints the finished bed region start to end
        # Starts a new bed region at the current position
        # END statement prints the last open region after all lines read

        awk -v threshold={params.threshold} '
        $3 < threshold {{
            if (chrom != $1) {{
                if (start != "") print chrom "\t" start-1 "\t" end;
                chrom = $1;
                start = $2;
                end = $2;
            }} else if (start == "") {{
                start = $2;
                end = $2;
            }} else if ($2 == end + 1) {{
                end = $2;
            }} else {{
                print chrom "\t" start-1 "\t" end;
                start = $2;
                end = $2;
            }}
        }}
        END {{
            if (start != "") print chrom "\t" start-1 "\t" end;
        }}
        ' {output.depth_stats} > {output.bed}

        """

# Creates a mask for ms germline variant positions
#When using --deletions, the stop value of the BED output is determined by the length difference between ALT and REF alleles. 
    #Use of --insertions or --snvs yields a one-base BED element.
rule ms_germline_variants_bed:
    input:
        vcf= rules.ms_filter_pass_variants.output.vcf
    output:
        del_bed= "tmp/ref/{ms_sample}_GL_variants_del.bed",
        in_bed= "tmp/ref/{ms_sample}_GL_variants_in.bed",
        snv_bed = "tmp/ref/{ms_sample}_GL_variants_snv.bed",
        bed = "tmp/ref/{ms_sample}_GL_variants.bed"
    shell:
        """
        # Convert filtered VCF to BED format
        zcat {input.vcf} | vcf2bed --deletions > {output.del_bed}
        zcat {input.vcf} | vcf2bed --insertions > {output.in_bed}
        zcat {input.vcf} | vcf2bed --snvs > {output.snv_bed}

        # Concatenate all into a single BED file, preserving exact regions
        cat {output.del_bed} {output.in_bed} {output.snv_bed} | \
            sort -k1,1 -k2,2n > {output.bed}
            
        """

# Combines all masks into one bed file
rule ms_combine_masks:
    input:
        gnomAD_bed = "tmp/ref/gnomad_common_af01_merged.bed",
        illumina_bed =
        GIAB_bed = "tmp/ref/GRCh38_alldifficultregions.bed.gz",
        lowdepth_bed = "tmp/ref/{ms_sample}_lowdepth.bed",
        ms_germline_bed = "tmp/ref/{ms_sample}_GL_variants.bed"
    output:
        combined_bed = "tmp/ref/{ms_sample}_combined.bed"
    shell:
        """
        cat {input.gnomAD_bed} \
        {input.GIAB_bed} \
        {input.lowdepth_bed} \
        {input.ms_germline_bed}
        sort -k1,1 -k2,2n | \
        bedtools merge -i - > {output.combined_bed}

        """