# Running the pipeline

## Preparation

The following instructions assume you have:
- Set up the compute platform
- Prepared sample metadata sheets
- Prepared `config.yaml`
- Reference files are ready for staging
- `ex_lane` and `ms_sample` FASTQ files are ready for staging

See the relevant documentation for more information on how to do the above steps.

## Running pipeline

1. **Upload config file and sample metadata sheets**
    
    Upload the following files to the `config/` directory:
    - `config.yaml`
    - `ex_lanes.csv`
    - `ex_samples.csv`
    - `ex_adapters.csv`
    - `ms_samples.csv`
    - `download_list.csv` (optional)

    On `Amazon EC2` this can be acomplised with the following command:
    ```
    scp -i ~/.ssh/<private_key>.pem <dir_with_config_files>/* ubuntu@<public_IPv4_address>:SomaticCODEC/config/
    ```

2. **Start a tmux session**

    ```
    tmux new -s codec-session
    ```

3. **Run the docker container**

    On `Amazon EC2`:
    ```
    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600") && \
    INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id) && \
    REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | cut -d'"' -f4) && \
    sudo docker run -it \
    --name codec-container \
    -v "$PWD":/work \
    -w /work \
    -e INSTANCE_ID="$INSTANCE_ID" \
    -e AWS_REGION="$REGION" \
    codec-image
    ```

    On other platforms:
    ```
    sudo docker run -it \
    --name codec-container \
    -v "$PWD":/work \
    -w /work \
    codec-image
    ```

4. **Check sample metadata**

    ```
    python3 -u bin/check_sample_metadata.py
    ```

5. **Check download list configuration (optional)**

    Run the following command if you plan to stage files using `bin/download_S3.py`

    ```
    python3 -u bin/check_download_list_S3.py
    ```

6. **Stage files** 

    All files required for the pipeline run must be transfered to the instance.
    - `ex_lane` FASTQ files (defined in `ex_lanes.csv`)
    - `ms_sample` FASTQ files (defined in `ms_samples.csv`)
    - Reference files defined in `config.yaml` -> `sci_params.shared`

    If the following files are located on Amazon S3, and are defined in `download_list.csv`, they can be staged using the following command:

    ```
    python3 -u bin/download_S3.py
    ```

7. **Dryrun**

    ```
    bash bin/dryrun.sh
    ```

8. **Run pipeline**

    ```
    bash bin/run_pipeline.sh
    ```
    12 samples on a `m7i.48xlarge` instance takes aproximately 48 hours.

9. **Package outputs**

    ```
    python3 bin/package_outputs.py
    ```

10. **Upload packaged outputs to S3 (optional)**

    ```
    bash bin/upload_S3.sh
    ```

    If using this script, upload destination must be defined in `config.yaml` -> `infrastructure.aws.s3_out_dir`

## End-end pipeline automation (Amazon EC2)

Perform steps 1-3 as per instructions above, then run the following command:

    ```
    bash bin/run_all.sh
    ```
If using this script, SNS ARN must be defined in `config.yaml` -> `infrastructure.aws.sns_arn`

