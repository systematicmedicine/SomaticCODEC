"""
--- masked_regions.smk ---

Rules for masking genomic regions where somatic variant cannot be confidently called.

Inputs:
    - gnomAD common variants
    - Illumina all difficult regions
    - Low depth regions from raw alignment (ms)
    - Heterozygous regions from filtered germline variants (ms)
    
Output: BED file containing all regions to mask

Author: Joshua Johnstone

"""
# Filters and creates a mask for low depth regions of ms raw alignment
rule low_depth_mask:
    input:
        markdup_bam = "tmp/results/{ms_sample}_markdup.bam",
        markdup_bai = "tmp/results/{ms_sample}_markdup.bai"
    output:
        depth_stats = "tmp/metrics/alignment/{ms_sample}_depth.txt",
        bed = "tmp/masks/{ms_sample}_lowdepth.bed"
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

# Filters and creates a mask for heterozygous regions from ms filtered germline variants 
#rule heterozygous_mask:
# BB working on this rule

# Combines all masks into one bed file
# rule combine_masks:
#     input:
#         gnomAD_bed =
#         illumina_bed = "tmp/masks/GRCh38_alldifficultregions.bed.gz",
#         lowdepth_bed = "tmp/masks/{ms_sample}_lowdepth.bed",
#         heterozygous_bed = 
#     output:
#         combined_bed = "tmp/masks/{ms_sample}_combined.bed"
#     shell:
#         """
#         cat {input.gnomAD_bed} \
#         {input.illumina_bed} \
#         {input.lowdepth_bed} \
#         {input.lowmap_bed} \
#         {input.heterozygous_bed} | \
#         sort -k1,1 -k2,2n | \
#         bedtools merge -i - > {output.combined_bed}

#         """