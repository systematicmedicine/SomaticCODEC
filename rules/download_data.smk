"""
--- ex_alignment.smk ---

Downloads data from AWS S3:
    * Sample FASTQ files 
    * Reference files (e.g. GCRh38)

Author: ...

"""
rule download_reference_files:
    output:
        directory("tmp/reference/")
    shell:
        """
        mkdir -p {output}
        aws s3 cp s3://sysmed-ref-s3/reference-files {output} --recursive
        """

rule download_raw_fastq:
    output:
        directory("tmp/raw/")
    params:
        fastqfolder = config["seq_folder"]
    shell:
        """
        mkdir -p {output}
        aws s3 cp s3://sysmed-seq-s3/{params.fastqfolder} {output} --recursive
        """