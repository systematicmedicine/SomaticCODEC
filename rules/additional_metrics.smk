"""
--- additional_metrics.smk ---

Rules for creating metrics files that are not related to the other rule groups and a component metrics report.

Outputs: 
    - Multiple metrics files
    - Component metrics report csv

Authors: 
    - James Phie
    - Joshua Johnstone

"""

#Lists ex_sample names that belong to each lane
samples_by_lane = pd.read_csv(config["ex_samples_path"]).groupby("ex_lane")["ex_sample"].apply(list).to_dict()

# Replace default index names with experiment specific sample names as defined in the input.tsv
rule ex_correctproduct_metrics:
    input:
        demux_json = "metrics/{lane}/{lane}_demux_metrics.json",
        trim_reports = lambda wildcards: expand("metrics/{ex_sample}/{ex_sample}_filter_metrics.json", ex_sample=samples_by_lane[wildcards.lane]),
        flagstats = lambda wildcards: expand("metrics/{ex_sample}/{ex_sample}_map_metrics.txt", ex_sample=samples_by_lane[wildcards.lane])
    output:
        "metrics/{lane}/{lane}_correctproduct_metrics.txt"
    params:
        samples = lambda wildcards: samples_by_lane[wildcards.lane]
    script:
        "../scripts/correctproduct.py"

# Custom python script to assess how many unused indices were detected from other experiments (similar metrics to rawreadcounts). This should always be 0. 
rule ex_batchcontamination_metrics:
    input:
        json = "metrics/{lane}/{lane}_demux_metrics.json"
    output:
        contamination = "metrics/{lane}/{lane}_batchcontamination_metrics.txt"
    params:
        fasta = lambda wildcards: f"tmp/adapter_fastas/{wildcards.lane}_r1start.fasta",
        used = config['ex_samples_path']
    script:
        "../scripts/batchcontamination.py"

# Shows distribution of insert sizes (distance between 5' end of R1 and 3' end of R2) for correctly paired (same chr, within 500bp) reads 
rule ex_insert_metrics:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_correct.bam",
    output:
        txt = "metrics/{ex_sample}/{ex_sample}_insert_metrics.txt",
        hist = "metrics/{ex_sample}/{ex_sample}_insert_metrics.pdf",
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
        "metrics/ex_duplication_metrics.txt"
    script:
        "../scripts/duplication.py"

# Generates a pass/fail report for all component level metrics
rule component_metrics_report:
    input:
        expand("metrics/{ms_sample}/{ms_sample}_mask_metrics.txt", ms_sample = ms_sample_names),
        expand("metrics/{ex_sample}/{ex_sample}_map_metrics.txt", ex_sample=ex_sample_names)
    output:
        report = "metrics/component_metrics_report.csv"
    script:
        "scripts/component_metrics_report.R"