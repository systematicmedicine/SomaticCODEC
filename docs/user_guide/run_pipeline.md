# Running the pipeline

The instructions below for running the pipeline assume the following:

- The compute platform has been set up
- Sample sheets have been prepared
- `ex_lane` FASTQ files, `ms_sample` FASTQ files, and reference files are ready for staging
- A profile has been chosen

There are two options for running the pipeline: stepwise and automated. Both run the same bin scripts. The automated option orchestrates these via a wrapper script and assumes execution on AWS. New users should use the stepwise approach.

## Running pipeline (stepwise)

1. **Upload sample sheets**
    
    Upload the following files to the `experiment/` directory:
    - `ex_lanes.csv`
    - `ex_samples.csv`
    - `ex_adapters.csv`
    - `ms_samples.csv`
    - `ms_adapters.csv`
    - `download_list.csv` (optional)

    Uploading these files to an `Amazon EC2` instance can be accomplished with the following command:

    ```bash
    scp -i ~/.ssh/<private_key>.pem <dir_with_sample_sheets>/* ubuntu@<public_IPv4_address>:SomaticCODEC/experiment/
    ```

2. **Start a tmux session**

    ```bash
    tmux new -s codec-session
    ```

3. **Run the docker container**

    ```bash
    # Run inside the SomaticCODEC directory
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

5. **Check sample sheets**

    ```bash
    python3 -u bin/check_sample_metadata.py
    ```

6. **Check download list (optional)**

    Run the following command if you plan to stage files using `bin/download_S3.py`

    ```bash
    python3 -u bin/check_download_list_S3.py
    ```

7. **Stage files** 

    All files required for the pipeline run must be transferred to the instance.
    - `ex_lane` FASTQ files (defined in `ex_lanes.csv`)
    - `ms_sample` FASTQ files (defined in `ms_samples.csv`)
    - Reference files defined in `config.yaml` -> `sci_params.shared`

    If these files are located on Amazon S3, and are defined in `download_list.csv`, they can be staged using the following command:

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
    bash bin/upload_S3.sh <S3_target_dir>
    ```

## Running pipeline (automated)

1. **Upload sample metadata sheets**
    
    Upload the following files to the `experiment/` directory:
    - `ex_lanes.csv`
    - `ex_samples.csv`
    - `ex_adapters.csv`
    - `ms_samples.csv`
    - `ms_adapters.csv`
    - `download_list.csv`

    ```bash
    scp -i ~/.ssh/<private_key>.pem <dir_with_sample_sheets>/* ubuntu@<public_IPv4_address>:SomaticCODEC/experiment/
    ```

2. **Start a tmux session**

    ```bash
    tmux new -s codec-session
    ```

3. **Run the docker container (pass EC2 metadata)**
    
    ```bash
    # Run inside the SomaticCODEC directory
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
    bash bin/run_all.sh \
    -e <environment> \
    -p <profile> \
    -s <S3_target_dir>
    ```
    Packaged outputs will be sent to the S3 target directory (write access is required).

5. **Upon completion (success or failure), the instance will shut down.**