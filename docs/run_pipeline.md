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
sudo docker run -it --name codec-container -v "$PWD":/work -w /work codec-image
```

4. Start background system resource monitoring (optional)
```
bash bin/monitor_system_resources.sh &
```

5. Run pipeline
```
# Download script
python3 bin/download_S3.py > logs/bin_scripts/download_S3.log 2>&1

# Check pipeline
bash bin/check_pipeline.sh > logs/bin_scripts/check_pipeline.log 2>&1

# Run pipeline
bash bin/run_pipeline.sh > logs/bin_scripts/run_pipeline.log 2>&1

# Package outputs
python3 bin/package_outputs.py > logs/bin_scripts/package_outputs.log 2>&1

# Upload outputs to S3
bash bin/upload_S3.sh > logs/bin_scripts/upload_S3.log 2>&1
