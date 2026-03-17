# Preparing the configuration file

Download `config.yaml` from the `config/` directory. Make the following changes:

#### All runs:

- `run_name`: Used by bin scripts and to label various metrics plots.

#### If using custom reference genome

- `sci_params.shared.reference_genome`

#### If using automated S3 upload script:

- `infrastructure.aws.s3_out_dir`: The S3 directory where the packaged outputs will be uploaded if using the *bin/upload_S3.sh* script.

#### If using run_all.sh to automate runs end-end

- `infrastructure.aws.sns_arn`: The Amazon Resource Name for an SNS topic that sends an email when the pipeline finishes ([SNS setup instructions](https://docs.aws.amazon.com/sns/latest/dg/sns-getting-started.html)).

