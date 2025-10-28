"""
Calculate DSC coverage metrics
    - ex_mean_analyzable_duplex_depth: Total duplex bases in include_beg region divided by total positions in include_bed region
    - ex_duplex_coverage_bedregions: Percentage of positions in include_bed region that have >0x duplex depth
    - ex_duplex_coverage_wholegenome: Positions with >0x duplex depth in the include_bed region as a percentage of the whole genome
"""

import helpers.get_metadata as md

rule ex_dsc_coverage_metrics:
    input:
        bam_ex_dsc = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam",
        bai_ex_dsc = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam.bai",
        include_bed = "tmp/{ex_sample}/{ex_sample}_include.bed",
        ms_depth = lambda wc: (
            f"tmp/{md.get_ex_to_ms_sample_map(config)[wc.ex_sample]}/"
            f"{md.get_ex_to_ms_sample_map(config)[wc.ex_sample]}_depth_per_base.txt"
        ),
        fai = config["sci_params"]["global"]["reference_genome"] + ".fai"
    output:
        metrics = "metrics/{ex_sample}/{ex_sample}_dsc_coverage_metrics.json"
    params: 
        quality_threshold = config["sci_params"]["ex_call_somatic_snv"]["min_base_quality"],
        sample = "{ex_sample}",
        ms_depth_threshold = config["sci_params"]["ms_low_depth_mask"]["min_depth"]
    log:
        "logs/{ex_sample}/ex_dsc_coverage_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_dsc_coverage_metrics.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        os.path.join(workflow.basedir, "scripts", "ex_dsc_coverage_metrics.py")