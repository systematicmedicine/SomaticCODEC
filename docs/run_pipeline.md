# run_pipeline.md

## Recommended

*Note: Steps 4-10 can be run autonomously with the bin/run_all.sh script. Once the pipeline finishes, the EC2 instance will be shut down and an email will be sent describing the outcome of the run (this requires an SNS topic to be set up and the ARN provided in config.yaml)*

1. Upload prepared config files to the SomaticCODEC/config directory on the EC2 instance:
    - `config.yaml`
    - `ex_lanes.csv`
    - `ex_samples.csv`
    - `ex_adapters.csv`
    - `ms_samples.csv`
    - `download_list.csv`

    ```
    scp -i ~/.ssh/<private_key>.pem <dir_with_config_files>/* ubuntu@<public_IPv4_address>:SomaticCODEC/config/
    ```

2. Start a tmux session

    ```
    tmux new -s codec-session
    ```

3. Run the docker container

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

4. Check sample metadata configuration

    ```
    python3 -u bin/check_sample_metadata.py
    ```

5. Check download list configuration

    ```
    python3 -u bin/check_download_list_S3.py
    ```

6. Download files from S3

    ```
    python3 -u bin/download_S3.py
    ```

7. Check pipeline configuration

    ```
    bash bin/dryrun.sh
    ```

8. Run pipeline

    ```
    bash bin/run_pipeline.sh
    ```

9. Package outputs

    ```
    python3 bin/package_outputs.py
    ```

10. Upload packaged outputs to S3

    ```
    bash bin/upload_S3.sh
    ```

## Custom

If Amazon S3 and/or Amazon EC2 are not being used:

- Skip the download and upload steps, but ensure all required files are otherwise staged at the paths defined in:

    - config/config.yaml: sci_params.shared
    - config/ex_lanes.csv: fastq1 and fastq1
    - ms_samples: fastq1 and fastq2

- Run the Docker container without the AWS variables, or otherwise ensure all dependencies are available:

    ```
    sudo docker run -it \
    --name codec-container \
    -v "$PWD":/work \
    -w /work \
    codec-image
    ```
