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
* Transfer sequenced FASTQ files to `/s3/buckets/sysmed-seq-s3`
## Running pipeline on AWS EC2

### Prepare config files
Refer to [link](#) for more information on configuring config files.
* config.yaml
* ms_samples
* ex_samples.csv
* ex_adapters.csv
* download_list.csv

### Initialise EC2 instance
* Select `m8g.24xlarge`
* Configure IAM roles to allow S3 read only access
* Select an EBS volume size aproximately 4x the size of the input FASTQ files
* Connect to EC2 instance via SSH

### Clone GitHub repo
* The repo deploy key can be found at `\RwoD Research\Personal\Cameron\Misc\codec-opensource deploy key`
* Copy the deploy key to `~/.ssh/deploy_key`
* Run the following commands
```chmod 600 ~/.ssh/deploy_key
ssh-keyscan github.com >> ~/.ssh/known_hosts
GIT_SSH_COMMAND='ssh -i ~/.ssh/deploy_key' git clone --branch dev git@github.com:systematicmedicine/codec-opensource.git
```

### Download FASTQ and reference files
All required FASTQ and reference files should be defined in config/download_list.csv
```
python3 utils/download_S3toEC2.py
```

### Upload config files
* Replace defult config files in the cloned repository

### Build docker image
```
docker build -t codec .
```
### Run pipeline
* Create tmux session
```
tmux new -s pipeline
```
* Run the pipeline
```
snakemake --configfile config/config.yaml --notemp
``` 
### Download outputs to local
* Create tar file of key pipeline outputs
```
python3 utils/tar_output.py
```
* Download outputs using method of choice (e.g. scp to WSL)

### Shut down EC2 instance
Note: EC2 instances are expensive, do not leave them running when not in use

