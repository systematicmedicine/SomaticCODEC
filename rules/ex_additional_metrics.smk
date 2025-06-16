"""
--- ex_additional_metrics.smk ---

Rules for creating metrics files, that are not related to the other rule groups.

Outputs: Multiple metrics files

Author: James Phie

"""

#Lists ex_sample names that belong to each lane
samples_by_lane = pd.read_csv(config["ex_samples_path"]).groupby("ex_lane")["ex_sample"].apply(list).to_dict()

# Replace default index names with experiment specific sample names as defined in the input.tsv
rule ex_correctproduct_metrics:
    input:
        demux_json = "metrics/{lane}_demux_metrics.json",
        trim_reports = lambda wildcards: expand("metrics/{ex_sample}/{ex_sample}_trimfilter_metrics.json", ex_sample=samples_by_lane[wildcards.lane]),
        flagstats = lambda wildcards: expand("metrics/{ex_sample}/{ex_sample}_map_metrics.txt", ex_sample=samples_by_lane[wildcards.lane])
    output:
        "metrics/{lane}_correctproduct_metrics.txt"
    params:
        samples = lambda wildcards: samples_by_lane[wildcards.lane]
    script:
        "../scripts/correctproduct.py"

# Custom python script to assess how many unused indices were detected from other experiments (similar metrics to rawreadcounts). This should always be 0. 
rule ex_batchcontamination_metrics:
    input:
        json = "metrics/{lane}_demux_metrics.json"
    output:
        contamination = "metrics/{lane}_batchcontamination_metrics.txt"
    params:
        fasta = config['r1start'],
        used = config['ex_samples']
    script:
        "../scripts/batchcontamination.py"

# Calculates insert size (distance between start of watson and end of crick, includes ss overhangs)
rule ex_insert_metrics:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno.bam",
    output:
        txt = "metrics/{ex_sample}/{ex_sample}_deduplicated_insert_metrics.txt",
        hist = "metrics/{ex_sample}/{ex_sample}_deduplicated_insert_metrics.pdf",
    resources:
        mem = 32
    shell:
        """
        picard -Xmx{resources.mem}g -Djava.io.tmpdir=tmp \
            CollectInsertSizeMetrics \
            I={input.bam} \
            O={output.txt} \
            H={output.hist} \
            M=0.5 \
            W=600 \
            DEVIATIONS=100
        """

# Duplication rate calculated based on unique UMI families output from ex_groupbyumi.
rule ex_duplication_metrics:
    input:
        expand("metrics/{ex_sample}/{ex_sample}_map_umi3_metrics.txt", ex_sample=ex_sample_names)
    output:
        "metrics/duplication_metrics.txt"
    script:
        "../scripts/duplication.py"