"""
--- ex_technical_controls.smk ---

Rules for generating metrics from technical control FASTQ files

Input: Demuxed technical control FASTQ files
Output: Metrics files

Authors: 
    - Joshua Johnstone
"""

rule check_technical_controls_demuxed:
    input:
        expand("tmp/{ex_technical_control}/{ex_technical_control}_r1_demux.fastq.gz", 
            ex_technical_control = md.get_ex_technical_control_ids(config)),
        expand("tmp/{ex_technical_control}/{ex_technical_control}_r2_demux.fastq.gz", 
            ex_technical_control = md.get_ex_technical_control_ids(config))
    output:
        "logs/pipeline/check_technical_controls_demuxed.done"
    shell:
        """
        touch {output}
        """
