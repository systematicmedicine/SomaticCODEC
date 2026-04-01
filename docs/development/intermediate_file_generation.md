# intermediate_file_generation.md

By default, the pipeline deletes intermediate files that are marked with temp(). If these files are required, they can be generated using the steps below.

1. Create experiment metadata files as per the [experiment metadata setup guide](../setup/experiment_metadata_setup.md).

2. Set up EC2 instance as per the [compute setup guide](../setup/compute_setup.md), with the following change:
    * Allocate 2500GiB per EX or MS sample (instead of 500 GiB)

3. Create tmux session and run docker as per the [Run pipeline](../run_pipeline.md) document

4. Open *bin/run_pipeline.sh* with nano and add the `--notemp` flag to the Snakemake command

```bash
snakemake \
    --snakefile Snakefile \
    --configfile tmp/runtime_config/merged_config.yaml \
    --cores $USABLE_CORES \
    --resources memory=$USABLE_MEM_GB \
    --keep-going \
    --notemp \
    --stats logs/bin_scripts/run_pipeline_stats.json
```

5. Run pipeline as per the [Run pipeline document](docs/run_pipeline.md)

6. Following successful completion of the pipeline, the instance will shut down

7. Start the instance

8. Create a new tmux session and start the existing docker container

```
tmux new -s file-transfer

docker start -ai codec-container
```

9. Upload select intermediate files to s3:

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
