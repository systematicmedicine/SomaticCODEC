# intermediate_file_generation.md

*This document provides instructions for generating intermediate files. This is aimed at an internal audience.*

By default, the pipeline deletes intermediate files that are marked with temp(). If these files are required, they can be generated using the steps below.

1. Create experiment metadata files as per the [experiment metadata setup guide](../user_guide/experiment_metadata_setup.md).

2. Set up EC2 instance as per the [compute setup guide](../user_guide/compute_setup.md), with the following change:
    * Allocate 2500GiB per EX or MS sample (instead of 500 GiB)

3. Run pipeline as per the [Run pipeline guide](../user_guide/run_pipeline.md), with the following changes:

    * If using the stepwise approach:

        At step 9 (Run pipeline), include the --notemp flag

        ```bash
        python3 -u bin/run_pipeline.py --notemp
        ```

    * If using the automated approach:

        At step 4 (Run all pipeline steps), include the -n flag

        ```bash
        bash bin/run_all.sh \
        -e <environment> \
        -p <profile> \
        -s <S3_target_dir> \
        -n
        ```

        Following successful completion of the pipeline, start the shut-down instance and Docker container:

        ```
        cd SomaticCODEC

        tmux new -s file-transfer

        docker start -ai codec-container
        ```

4. Upload select intermediate files to S3:

```
aws s3 cp tmp/ \
s3://<destination_bucket>/<directory>/ \
--recursive \
--exclude "*" \
--include "*_filtered_r1.fastq.gz" \
--include "*_filtered_r2.fastq.gz" \
--include "*_deduped_alignment.bam" \
--include "*_deduped_alignment.bam.bai" \
--include "*_germ_risk.bed" \
--include "*_lowdepth.bed" \
--include "*_combined_mask.bed" \
--include "*_include.bed" \
--include "*_umi_grouped_alignment.bam" \
--include "*_filtered_dsc.bam" \
--include "*_filtered_dsc.bam.bai" \
--include "*_all_positions.vcf"
```
