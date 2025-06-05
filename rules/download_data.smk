"""
--- ex_alignment.smk ---

Downloads data from AWS S3:
    * Sample FASTQ files 
    * Reference files (e.g. GCRh38)

Author: ...

"""

rule download_reference_files:
    output:
        "tmp/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna",
        "tmp/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.dict",
        "tmp/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.pac",
        "tmp/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.sa",
        "tmp/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.0123",
        "tmp/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.amb",
        "tmp/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.ann",
        "tmp/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.bwt",
        "tmp/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.bwt.2bit.64",
        "tmp/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.fai",
        "tmp/reference/GRCh38_notinalldifficultregions.bed",
        "tmp/reference/GRCh38_notinalldifficultregions.interval_list",
        "tmp/reference/common_all_20180418_with_chr.vcf",
        "tmp/reference/common_all_20180418_with_chr.vcf.gz.tbi"
    shell:
        """
        mkdir -p tmp/reference
        aws s3 cp s3://sysmed-ref-s3/reference-files tmp/reference --recursive
        """


rule download_ex_raw_fastq:
    params:
        fastqfolder = config["s3seq_fastq_folder"]
    output:
        ex_raw_fastq1,
        ex_raw_fastq2
    shell:
        """
        mkdir -p tmp/raw
        aws s3 cp s3://sysmed-seq-s3/{params.fastqfolder} tmp/raw --recursive
        """