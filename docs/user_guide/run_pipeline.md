# Running the pipeline

## Preparation

The following instructions assume you have:
- `ex_lane` and `ms_sample` FASTQ files have been generated
- Prepared sample metadata sheets
- Reference files are ready for staging
- Set up the compute platform

See the relevant documentation for more information on how to perform the above steps.

## Running pipeline

1. **Upload experiment metadata sheets**
    
    Upload the following files to the `experiment/` directory:
    - `ex_lanes.csv`
    - `ex_samples.csv`
    - `ex_adapters.csv`
    - `ms_samples.csv`
    - `download_list.csv` (optional)

    On `Amazon EC2` this can be accomplished with the following command:

    ```bash
    scp -i ~/.ssh/<private_key>.pem <dir_with_experiment_sheets>/* ubuntu@<public_IPv4_address>:SomaticCODEC/experiment/
    ```

2. **Start a tmux session**

    ```bash
    tmux new -s codec-session
    ```

3. **Run the docker container**

    ```bash
    sudo docker run -it \
    --name codec-container \
    -v "$PWD":/work \
    -w /work \
    codec-image
    ```

4. **Create runtime config**

    ```bash
    python3 -u bin/create_runtime_config.py \
        --environment <environment_name> \
        --profile <profile_name>
    ```

5. **Check sample metadata**

    ```bash
    python3 -u bin/check_sample_metadata.py
    ```

6. **Check download list configuration (optional)**

    Run the following command if you plan to stage files using `bin/download_S3.py`

    ```bash
    python3 -u bin/check_download_list_S3.py
    ```

7. **Stage files** 

    All files required for the pipeline run must be transferred to the instance.
    - `ex_lane` FASTQ files (defined in `ex_lanes.csv`)
    - `ms_sample` FASTQ files (defined in `ms_samples.csv`)
    - Reference files defined in `config.yaml` -> `sci_params.shared`

    If the following files are located on Amazon S3, and are defined in `download_list.csv`, they can be staged using the following command:

    ```bash
    python3 -u bin/download_S3.py
    ```

8. **Dryrun**

    ```bash
    bash bin/dryrun.sh
    ```

9. **Run pipeline**

    ```bash
    python3 -u bin/run_pipeline.py
    ```
    Running 12 samples on an `m7i.48xlarge` instance takes approximately 48 hours.

10. **Package outputs**

    ```bash
    python3 bin/package_outputs.py
    ```

11. **Upload packaged outputs to S3 (optional)**

    ```bash
    S3_TARGET_DIR="s3://<bucket>/<dir>" \
    bash bin/upload_S3.sh
    ```

## Alternative process (end-end pipeline automation)

The following process assumes:
- You are using the default compute platform (Amazon EC2)
- You have configured AWS SNS to send an email when the pipeline finishes

1. **Upload sample metadata sheets**
    
    Upload the following files to the `experiment/` directory:
    - `ex_lanes.csv`
    - `ex_samples.csv`
    - `ex_adapters.csv`
    - `ms_samples.csv`
    - `download_list.csv`

    ```bash
    scp -i ~/.ssh/<private_key>.pem <dir_with_config_files>/* ubuntu@<public_IPv4_address>:SomaticCODEC/config/
    ```

2. **Start a tmux session**

    ```bash
    tmux new -s codec-session
    ```

3. **Run the docker container (pass EC2 parameters)**
    
    ```bash
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

4. **Run all pipeline steps**

    ```bash
    ENVIRONMENT="<environment_name>" \
    PROFILE="<profile_name>" \
    S3_TARGET_DIR="s3://<bucket>/<dir>/" \
    SNS_ARN="arn:aws:sns:<region>:<account_ID>:<topic_name>" \
    bash bin/run_all.sh
    ```

5. **Upon completion (success or failure), an email will be sent and the instance will shut down.**