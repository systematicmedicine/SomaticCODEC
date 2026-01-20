# intermediate_files.md

By default, the pipeline deletes intermediate files that are marked with temp(). As analyses often require these files, a representive set of intermediate files is maintained on s3 using the steps below.

Following each **MAJOR** version release, generate a set of representative intermediate files:

1. Create config files for a set of 4 EX/MS sample pairs

2. Set up EC2 instance as per the [EC2 setup guide](docs/ec2_setup.md), with the following change:
    * Allocate 5000GiB gp3 storage per EX/MS sample pair (20000GiB total for 4 EX/MS sample pairs)

3. Create tmux session and run docker as per the [Run pipeline](docs/run_pipeline.md) document

4. Open bin/run_pipeline.sh with nano or vim and add the --notemp flag to the Snakemake command

```
snakemake \
    --snakefile Snakefile \
    --configfile config/config.yaml \
    --cores $USABLE_CORES \
    --resources memory=$USABLE_MEM_GB \
    --keep-going \
    --notemp \
    --stats logs/bin_scripts/run_pipeline_stats.json
```

5. Run pipeline as per the [Run pipeline](docs/run_pipeline.md) document

6. Following successful completion of the pipeline, upload select intermediate files to s3:

```
aws s3 cp ./ \
s3://sm-restricted-stvincents-hrec-130-22/tmp/SomaticCODEC-intermediate-files/{version}/ \
--recursive \
--exclude "*" \
include "*_filter.fastq.gz" \
include "*_map_umi_grouped.bam" \
include "*_map_dsc_anno_filtered.bam" \
include "*_map_dsc_anno_filtered.bam.bai" \
include "*_all_positions.vcf" \
include "*_filter_r1.fastq.gz" \
include "*_filter_r2.fastq.gz" \
include "*_deduped_map.bam" \
include "*_deduped_map.bam.bai" \
include "*_ms_germ_risk.vcf" \
include "*_ms_germ_risk.bed" \
include "*_lowdepth.bed" \
include "*_combined_mask.bed" \
include "*_include.bed"
```

7. Once the files are uploaded, delete intermediate files generated with the previous **MAJOR** version (these are now obselete)
