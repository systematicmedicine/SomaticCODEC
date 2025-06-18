# codec-opensource
A bioinformatics pipeline for calling somatic mutations in sequenced CODEC libraries.

## Key differences from [`broadinstitute/CODECsuite`](https://github.com/broadinstitute/CODECsuite)

* Fully open-source toolchain (e.g. `cutadapt`, `fgbio`, `samtools`, etc)
* Tailored for calling somatic mutations in normal tissue
* Uses independent matched samples (from same individual) to differentiate true somatic variants from germline variants
* Extensive range of QC metrics generated (e.g. `fastqc`)
* Fully containerized docker workflow

## Library prep and sequencing
* Prepare and sequence CODEC libraries as per `SOP0017 CODECseq library preparation`
* Prepare and sequence matched samples as `\CODECseq\20250526 Sequencing for pipeline and metric tests\Methods`

## Setup instructions
* [Setup Instructions](docs/setup.md)

## Running the pipeline
* Change to <I>codec-opensource</I> directory
* Upload [config files](docs/configs.md) for this run
* Run docker container
```
sudo docker run -it --name pipeline -v "$PWD":/work -w /work codec
```
* Download FASTQ and reference files
```
python3 utils/download_S3toEC2.py
```
* Create tmux session
```
tmux new -s pipeline
```
* Run pipeline
```
snakemake --configfile config/config.yaml --dryrun
snakemake --configfile config/config.yaml --cores all --stats metrics/stats.json | tee metrics/snakemake.log
``` 
* After pipeline has run sucessfullt, create single file of outputs (optional)
```
python3 utils/tar_output.py
```
* If using EC2, don't forget to shut down your instance

