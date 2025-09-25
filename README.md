# codec-opensource
A bioinformatics pipeline for calling somatic mutations in sequenced CODEC libraries.

## Key differences from [`broadinstitute/CODECsuite`](https://github.com/broadinstitute/CODECsuite)

* Fully open-source toolchain (e.g. `cutadapt`, `fgbio`, `samtools`, etc)
* Tailored for calling somatic mutations in normal tissue
* Uses independent matched samples (from same individual) to differentiate true somatic variants from germline variants
* Extensive range of QC metrics generated (e.g. `fastqc`)
* Fully containerized docker workflow

## Library prep and sequencing
Prepare and sequence libraries as per: 

* `SOP0017 CODECseq library preparation`
* `SOP0029 CODECseq matched sample library preparation`

## Setup instructions
* [Amazon EC2](docs/setup_EC2.md)

## Running the pipeline

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
```

