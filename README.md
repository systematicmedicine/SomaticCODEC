# codec-opensource
A bioinformatics pipeline for calling somatic mutations in sequenced CODEC libraries.

## Key differences from [`broadinstitute/CODECsuite`](https://github.com/broadinstitute/CODECsuite)

* Fully open-source toolchain (e.g. `cutadapt`, `fgbio`, `samtools`, etc)
* Tailored for calling somatic mutations in normal tissue
* Uses independent matched samples (from same individual) to differentiate true somatic variants from germline variants
* Extensive range of QC metrics generated (e.g. `fastqc`)
* Fully containerized docker workflow

## Contribution guidleines
* [Versions, branches & pull requests](docs/versions_and_branches.md)
* [Logging](docs/logging.md)

## Library prep and sequencing
* Prepare and sequence CODEC libraries as per `SOP0017 CODECseq library preparation`
* Prepare and sequence matched samples as `\CODECseq\20250526 Sequencing for pipeline and metric tests\Methods`

## Setup instructions
* [Setup Instructions](docs/setup.md)

## Running the pipeline

All of the steps below must be run from the repositories root directory.

1. Upload [config files](docs/configs.md):
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

4. Download FASTQ and reference files 
```
python3 bin/download_S3.py
```

5. Start background system resource monitoring (to be moved into pipeline)
```
bash bin/monitor_system_resources.sh &
``` 

6. Check pipeline
```
bash bin/check_pipeline.sh
```

7. Run pipeline
```
bash bin/run_pipeline.sh
``` 

8. Package outputs
```
python3 bin/package_outputs.py
```

9. Upload outputs to S3
```
bash upload_S3.sh
```

10. Email that run is complete
```
bash bin/send_email.sh "Pipeline completed sucessfully"
```

11. Shutdown EC2 instance
```
sudo shutdown -h +1
```

