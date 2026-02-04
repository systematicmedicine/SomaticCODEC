"""
Creates a mask for genomic positions with low read depth in matched sample
    - Deletions are counted towards depth (-J flag)   
    - Overlapping r1 and r2 reads are counted once only (-s flag)
"""

rule ms_low_depth_mask:
    input:
        bam = "tmp/{ms_sample}/{ms_sample}_deduped_map.bam",
        bai = "tmp/{ms_sample}/{ms_sample}_deduped_map.bam.bai"
    output:
        bed = temp("tmp/{ms_sample}/{ms_sample}_lowdepth.bed"),
        intermediate_depth_per_base = temp("tmp/{ms_sample}/{ms_sample}_depth_per_base.txt"),
        intermediate_lowdepth = temp("tmp/{ms_sample}/{ms_sample}_lowdepth.txt"),
        intermediate_lowdepth_sorted = temp("tmp/{ms_sample}/{ms_sample}_lowdepth_sorted.txt")
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