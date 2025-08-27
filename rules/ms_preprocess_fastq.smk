"""
--- ms_preprocess_fastq.smk ---

Rules for performing fastqc, adaptor trimming, and quality filtering on demuxed ms FASTQs.

Input: 
    - Demuxed FASTQ files generated from Illumina sequencing of Illumina PCR-free libraries 
Outputs: 
    - Processed ms FASTQ files

Authors:
    - Joshua Johnstone
    - Cameron Fraser
"""

import scripts.get_metadata as md


"""
Moves UMI from i7 index to end of read header
""" 
rule ms_extract_fastq_umis:
    input:
        mapping_check = "logs/pipeline/check_ex_ms_mapping.done",
        variant_chroms_check = "logs/pipeline/check_variant_calling_chroms_present.done",
        ms_samples = config["files"]["ms_samples"],
        r1 = lambda wc: md.get_ms_sample_fastqs(config)[wc.ms_sample][0],
        r2 = lambda wc: md.get_ms_sample_fastqs(config)[wc.ms_sample][1]
    output:
        r1 = temp("tmp/{ms_sample}/{ms_sample}_umi_extracted_r1.fastq.gz"),
        r2 = temp("tmp/{ms_sample}/{ms_sample}_umi_extracted_r2.fastq.gz")
    log:
        "logs/{ms_sample}/ms_extract_fastq_umis.log"
    benchmark:
        "logs/{ms_sample}/ms_extract_fastq_umis.benchmark.txt"
    threads:
        config["resources"]["threads"]["light"]
    shell:
        r"""
        seqkit replace -j {threads} \
            -p "^(\\S+)\\s+(\\d+:\\S+:\\S+):([ACGT]+)([ACGT]{{12}})\\+([ACGT]+)" \
            -r '$1:$4 $2:$3+$5' \
            {input.r1} -o {output.r1} 2>> {log} &

        seqkit replace -j {threads} \
            -p "^(\\S+)\\s+(\\d+:\\S+:\\S+):([ACGT]+)([ACGT]{{12}})\\+([ACGT]+)" \
            -r '$1:$4 $2:$3+$5' \
            {input.r2} -o {output.r2} 2>> {log} &

        wait
        """


"""
Trims FASTQ files
    - 3bp spacer from 5' end of reads
    - Adaptors
    - Poly-G artifacts (>10 Gs at 3' end)
    - Trims bases of quality <20 from read ends
"""
rule ms_trim_fastq:
    input:
        r1 = "tmp/{ms_sample}/{ms_sample}_umi_extracted_r1.fastq.gz",
        r2 = "tmp/{ms_sample}/{ms_sample}_umi_extracted_r2.fastq.gz"
    output:
        intermediate_spacer_removed_r1 = temp("tmp/{ms_sample}/{ms_sample}_spacer_removed_r1.fastq.gz"),
        intermediate_spacer_removed_r2 = temp("tmp/{ms_sample}/{ms_sample}_spacer_removed_r2.fastq.gz"),
        r1 = temp("tmp/{ms_sample}/{ms_sample}_trim_r1.fastq.gz"),
        r2 = temp("tmp/{ms_sample}/{ms_sample}_trim_r2.fastq.gz"),
        report = "metrics/{ms_sample}/{ms_sample}_trim_metrics.txt"
    params:
        adaptor_1 = config["rules"]["ms_trim_fastq"]["adaptor_1"],
        adaptor_2 = config["rules"]["ms_trim_fastq"]["adaptor_2"],
        spacer_length = config["rules"]["ms_trim_fastq"]["spacer_length"],
        qual_trim_threshold = config["rules"]["ms_trim_fastq"]["qual_trim_threshold"]
    log:
        "logs/{ms_sample}/ms_trim_fastq.log"
    benchmark:
        "logs/{ms_sample}/ms_trim_fastq.benchmark.txt"
    threads: 
        config["resources"]["threads"]["moderate"]
    shell:
        """
        cutadapt \
          -j {threads} \
          -u {params.spacer_length} \
          -U {params.spacer_length} \
          -o {output.intermediate_spacer_removed_r1} \
          -p {output.intermediate_spacer_removed_r2} \
          {input.r1} {input.r2} 2>> {log}
        
        cutadapt \
            -j {threads} \
            -a {params.adaptor_1} \
            -A {params.adaptor_1} \
            -a {params.adaptor_2} \
            -A {params.adaptor_2} \
            -a "G{{10}}" \
            -A "G{{10}}" \
            --quality-cutoff {params.qual_trim_threshold} \
            -o {output.r1} \
            -p {output.r2} \
            {output.intermediate_spacer_removed_r1} {output.intermediate_spacer_removed_r2} \
            --report=full > {output.report} 2>> {log}
        """

"""
Filters FASTQ files
    - Reads < 100 base pairs
"""
rule ms_filter_fastq:
    input:
        r1 = "tmp/{ms_sample}/{ms_sample}_trim_r1.fastq.gz",
        r2 = "tmp/{ms_sample}/{ms_sample}_trim_r2.fastq.gz",    
    output:
        r1 = temp("tmp/{ms_sample}/{ms_sample}_filter_r1.fastq.gz"),
        r2 = temp("tmp/{ms_sample}/{ms_sample}_filter_r2.fastq.gz"),
        report = "metrics/{ms_sample}/{ms_sample}_filtered_fq_metrics.txt"
    params:
        min_read_length = config["rules"]["ms_filter_fastq"]["min_read_length"]
    log:
        "logs/{ms_sample}/ms_filter_fastq.log"
    benchmark:
        "logs/{ms_sample}/ms_filter_fastq.benchmark.txt"
    threads:
        config["resources"]["threads"]["moderate"]
    shell:
        """
        cutadapt \
            -j {threads} \
            --minimum-length {params.min_read_length} \
            -o {output.r1} \
            -p {output.r2} \
            {input.r1} {input.r2} \
            --report=full > {output.report} 2>> {log}
        """