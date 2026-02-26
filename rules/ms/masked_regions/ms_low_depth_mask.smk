"""
Creates a mask for genomic positions with low read depth in matched sample
    - Deletions are counted towards depth (-J flag)   
    - Overlapping r1 and r2 reads are counted once only (-s flag)
"""

from definitions.paths.io import ms as MS

rule ms_low_depth_mask:
    input:
        bam = MS.DEDUPED_BAM,
        bai = MS.DEDUPED_BAM_INDEX
    output:
        intermediate_depth_per_base = temp(MS.LOW_DEPTH_MASK_INT1),
        intermediate_lowdepth = temp(MS.LOW_DEPTH_MASK_INT2),
        intermediate_lowdepth_sorted = temp(MS.LOW_DEPTH_MASK_INT3),
        bed = temp(MS.LOW_DEPTH_MASK)
    params:
        min_base_qual = config["sci_params"]["ms_germline_risk"]["min_base_qual"],
        min_map_qual = config["sci_params"]["ms_germline_risk"]["min_map_qual"],
        threshold = config["sci_params"]["ms_low_depth_mask"]["min_depth"]
    log:
        "logs/{ms_sample}/ms_low_depth_mask.log"
    benchmark:
        "logs/{ms_sample}/ms_low_depth_mask.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}

        # Calculate depth per base
        samtools depth \
        -aa \
        --min-BQ {params.min_base_qual} \
        --min-MQ {params.min_map_qual} \
        -s \
        -J \
        {input.bam} > {output.intermediate_depth_per_base} 2>> {log}

        # Filter for depth < depth threshold
        awk -v threshold={params.threshold} '$3 < threshold {{print $1"\t"($2-1)"\t"$2}}' \
        {output.intermediate_depth_per_base} > {output.intermediate_lowdepth} 2>> {log}

        # Sort by chromosome then position
        sort {output.intermediate_lowdepth} -k1,1V -k2,2n > {output.intermediate_lowdepth_sorted} 2>> {log}

        # Merge adjacent regions
        bedtools merge -i {output.intermediate_lowdepth_sorted} > {output.bed} 2>> {log}
        """