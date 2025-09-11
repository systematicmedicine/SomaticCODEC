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
* Navigate to the codec-opensource directory
* Upload [config files](docs/configs.md) for this run:
    * `config.yaml`
    * `ex_samples.csv`
    * `ex_lanes.csv`
    * `ex_adapters.csv`
    * `ms_samples.csv`
    * `download_list.csv` (optional)
* Create tmux session
```
tmux new -s codec-session
```
* Run docker container
```
sudo docker run -it --name codec-container -v "$PWD":/work -w /work codec-image
```
* Download FASTQ and reference files
```
# If your files are stored elswhere, a different method may be used
python3 scripts/download_S3toEC2.py
```
* Start background system resource monitoring (optional)
```
./scripts/monitor_system_resources.sh &
``` 
* Run pipeline
```
# Dry-run
snakemake --configfile config/config.yaml --cores all --dryrun

# Run pipeline
snakemake \
    --snakefile Snakefile \
    --configfile config/config.yaml \
    --cores all \
    --resources memory=490 \
    --keep-going \
    --reason \
    --stats logs/pipeline/pipeline_stats.json \
    2>&1 | tee logs/pipeline/pipeline_run_$(date +%Y%m%d).log

# Generate report
snakemake --configfile config/config.yaml --report report.html
``` 
* Common tmux commands
    * Disconnect: Ctrl + b, d
    * List sessions: tmux ls
    * Reconnect: tmux attach -t <I>session name</I>
    * Enable scrolling: Ctrl + b, Shift + :, set -g mouse on, Enter

* After pipeline has run sucessfully, create single file of outputs (optional)
```
python3 scripts/tar_output.py
```
* If using EC2, don't forget to shut down your instance

