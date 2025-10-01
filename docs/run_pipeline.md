# run_pipeline.md

All of the steps below must be run from the repositories root directory.

1. Upload config files to config directory:
    * `config.yaml`
    * `ex_samples.csv`
    * `ex_lanes.csv`
    * `ex_adapters.csv`
    * `ex_technical_controls.csv`
    * `ms_samples.csv`
    * `download_list.csv`

2. Create tmux session
```
tmux new -s codec-session
```
3. Run docker container
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
4. Run pipeline
```
bash bin/run_all.sh
```

5. Cleanup
    
    * Once the pipeline finishes running (sucess or failure), an email message will be sent to `info@systematicmedicine.com`, and the AWS instance will automatically shut down.
    * The instance will need to be terminated manually via EC2 web interface (to remove EBS volume) 
    * The packaged outputs can be found at `s3://sysmed-tmp-s3/codec-opensource-runs/`
