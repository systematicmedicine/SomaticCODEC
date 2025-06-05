"""
--- ex_alignment.smk ---

Downloads data from AWS S3:
    * Sample FASTQ files 
    * Reference files (e.g. GCRh38)

Author: ...

"""
rule download_reference_files:
    output:
        touch("tmp/reference/.complete")
    shell:
        """
        mkdir -p tmp/reference
        aws s3 cp s3://sysmed-ref-s3/reference-files tmp/reference --recursive
        touch {output}
        """

rule download_raw_fastq:
    params:
        fastqfolder = config["s3seq_fastq_folder"]
    output:
        touch("tmp/raw/.complete")
    shell:
        """
        mkdir -p tmp/raw
        aws s3 cp s3://sysmed-seq-s3/{params.fastqfolder} tmp/raw --recursive
        touch {output}
        """