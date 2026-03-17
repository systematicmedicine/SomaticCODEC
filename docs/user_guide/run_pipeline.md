# Running the pipeline

The following instructions assume you have:
- Set up the compute environment
- Prepared sample metadata sheets
- Prepared the config file

See the relevant documentation for more information on how to do the above steps.

## Default platform (Amazon EC2)



1. Upload prepared config file and sample metadata sheets to the *SomaticCODEC/config* directory on the EC2 instance:
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

6. Stage required files. This must include all the files defined in:
    - *config/ex_lanes.csv*: `fastq1` and `fastq1`
    - *config/ms_samples.csv*: `fastq1` and `fastq2`
    - *config/config.yaml*: `sci_params.shared`

    If all of the above files have been defined in `config/download_list.csv`, they can be staged by running:

    ```
    python3 -u bin/download_S3.py
    ```

7. Pipeline dryrun

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

*Note: Steps 4-10 can be run autonomously with the bin/run_all.sh script. Once the pipeline finishes, the EC2 instance will be shut down and an email will be sent describing the outcome of the run (this requires an SNS topic to be set up and the ARN provided in config.yaml)*

## Custom compute platform

If using the custom compute platform, follow the instructions above, with the following modifications.

1. Unchanged
2. Unchanged
3. Run the Docker container without the AWS variables

    ```
    sudo docker run -it \
    --name codec-container \
    -v "$PWD":/work \
    -w /work \
    codec-image
    ```
4. Unchanged
5. Skip
6. Stage required files using method of choice
7. Unchanged
8. Unchanged
9. Unchanged (optional)
10. Skip

