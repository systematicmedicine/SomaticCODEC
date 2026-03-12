# config_yaml_setup.md

Download and prepare the [config.yaml file](https://github.com/systematicmedicine/SomaticCODEC/blob/master/config/config.yaml).

## Recommended

If following the [recommended compute setup](docs/setup/compute_setup.md), modify only the below parameters within config.yaml:

- run_name: Used by bin scripts and to label various metrics plots.
- infrastructure.aws.s3_out_dir: The S3 directory where the packaged outputs will be uploaded if using the bin/upload_S3.sh script.

The below parameter is only required if using the bin/run_all.sh script:

- infrastructure.aws.sns_arn: The Amazon Resource Name for an SNS topic that sends an email when the pipeline finishes ([SNS setup instructions](https://docs.aws.amazon.com/sns/latest/dg/sns-getting-started.html)).

## Custom

### Compute environment

If using a compute environment that is different to the [recommended compute setup](docs/setup/compute_setup.md), ensure the following parameters are set correctly:

- infrastructure.memory: Limits the memory used by each rule, must be less than the total available memory.
- infrastructure.threads: Limits the threads used by each rule, must be less than the total available threads.
- infrastructure.create_run_timeline_plot.disk_iops and infrastructure.create_run_timeline_plot.disk_throughput: Used to calculate disk usage during run (no effect on disk behaviour).

### Mask files

Mask files can be added/removed by modifying the list under sci_params.shared.precomputed_masks.